@;==============================================================================
@;
@;	"garlic_itcm_proc.s":	código de las funciones de control de procesos (1.0)
@;						(ver "garlic_system.h" para descripción de funciones)
@;
@;==============================================================================

@; CONSTANTS DEL SISTEMA I OFFSETS DEL PCB

IME = 0x4000208				@; Adreça del REG_IME
VBLANK_FREQ = 60			@; Freqüènia de refresc de la pantalla

PCB_PID = 0
PCB_PC = 4
PCB_SP = 8
PCB_STATUS = 12
PCB_KEY = 16
PCB_TICKS = 20				@; Els tics als 24 baixos i ús de CPU als 8 alts
PCB_SIZE = 24				@; Mida total del struct


@; CONSTANTS PER LES BÚSTIES

MAILBOX_QUEUE_SIZE = 16
MB_HEAD = 64
MB_TAIL = 68
MB_COUNT = 72
MB_WAIT = 76
MB_NWAIT = 92
MAILBOX_STRUCT_SIZE = 96	@; 64 + 4 + 4 + 4 + 16 + 4 = 96 bytes


.section .itcm,"ax",%progbits

	.arm
	.align 2
		
	.global _gp_WaitForVBlank
	@; rutina para pausar el procesador mientras no se produzca una interrupción
	@; de retroceso vertical (VBL); es un sustituto de la "swi #5" que evita
	@; la necesidad de cambiar a modo supervisor en los procesos GARLIC;
_gp_WaitForVBlank:
	push {r0-r1, lr}
	ldr r0, =__irq_flags
.Lwait_espera:
	mcr p15, 0, lr, c7, c0, 4	@; HALT (suspender hasta nueva interrupción)
	ldr r1, [r0]			@; R1 = [__irq_flags]
	tst r1, #1				@; comprobar flag IRQ_VBL
	beq .Lwait_espera		@; repetir bucle mientras no exista IRQ_VBL
	bic r1, #1
	str r1, [r0]			@; poner a cero el flag IRQ_VBL
	pop {r0-r1, pc}


	.global _gp_IntrMain
	@; Manejador principal de interrupciones del sistema Garlic;
_gp_IntrMain:
	mov	r12, #0x4000000
	add	r12, r12, #0x208	@; R12 = base registros de control de interrupciones	
	ldr	r2, [r12, #0x08]	@; R2 = REG_IE (máscara de bits con int. permitidas)
	ldr	r1, [r12, #0x0C]	@; R1 = REG_IF (máscara de bits con int. activas)
	and r1, r1, r2			@; filtrar int. activas con int. permitidas
	ldr	r2, =irqTable
.Lintr_find:				@; buscar manejadores de interrupciones específicos
	ldr r0, [r2, #4]		@; R0 = máscara de int. del manejador indexado
	cmp	r0, #0				@; si máscara = cero, fin de vector de manejadores
	beq	.Lintr_setflags		@; (abandonar bucle de búsqueda de manejador)
	ands r0, r0, r1			@; determinar si el manejador indexado atiende a una
	beq	.Lintr_cont1		@; de las interrupciones activas
	ldr	r3, [r2]			@; R3 = dirección de salto del manejador indexado
	cmp	r3, #0
	beq	.Lintr_ret			@; abandonar si dirección = 0
	mov r2, lr				@; guardar dirección de retorno
	blx	r3					@; invocar el manejador indexado
	mov lr, r2				@; recuperar dirección de retorno
	b .Lintr_ret			@; salir del bucle de búsqueda
.Lintr_cont1:	
	add	r2, r2, #8			@; pasar al siguiente índice del vector de
	b	.Lintr_find			@; manejadores de interrupciones específicas
.Lintr_ret:
	mov r1, r0				@; indica qué interrupción se ha servido
.Lintr_setflags:
	str	r1, [r12, #0x0C]	@; REG_IF = R1 (comunica interrupción servida)
	ldr	r0, =__irq_flags	@; R0 = dirección flags IRQ para gestión IntrWait
	ldr	r3, [r0]
	orr	r3, r3, r1			@; activar el flag correspondiente a la interrupción
	str	r3, [r0]			@; servida (todas si no se ha encontrado el maneja-
							@; dor correspondiente)
	mov	pc,lr				@; retornar al gestor de la excepción IRQ de la BIOS


	.global _gp_rsiVBL
	@; Manejador de interrupciones VBL (Vertical BLank) de Garlic:
	@; se encarga de actualizar los tics, intercambiar procesos, etc.
_gp_rsiVBL:
	push {r4-r7, lr}
		
		@; FASE 2: Comptar Tics del Procés Actual
		ldr r4, =_gd_pidz
		ldr r4, [r4]
		and r4, r4, #0xF			@; R4 = Sòcol actual
		
		ldr r5, =_gd_pcbs
		mov r6, #PCB_SIZE					@; Mida PCB
		mla r5, r6, r4, r5			@; R5 = Adreça PCB actual
		
		ldr r6, [r5, #PCB_TICKS]	@; Carreguem workTicks (offset 20)
		add r6, r6, #1				@; Incrementem
		str r6, [r5, #PCB_TICKS]	@; Guardem
	
		@; Incrementar comptador tics.
		ldr r4, =_gd_tickCount		@; Carreguem l'adreça de la variable comptador de tics global.
		ldr r5, [r4] 				@; Carreguem el valor de la variable comptador de tics.
		add r5, #1					@; Incrementem el valor de la variable.
		str r5, [r4]				@; Guardem el valor modificat.
		
		
		bl _gp_actualizarDelay		@; FASE 2: Cridem a la funció que actualitza la cua de Delay i desperta els processos si fa falta.
		
		
		@; Comprovar si hi ha algun procés a la cua nReady.
		
		@; Hi ha algú a la cua READY?
		ldr r6, =_gd_nReady
		ldr r7, [r6]
		cmp r7, #0
		bne .Lchange_context		@; Si nReady > 0, fem canvi

		@; El procés actual s'està bloquejant?
		ldr r4, =_gd_pidz
		ldr r5, [r4]
		tst r5, #0x80000000			@; Comprovem el bit 31 de la variable PIDZ
		bne .Lchange_context		@; Si bit 31==1, hem de marxar (encara que nReady=0)

		@; Si no hi ha ningú a Ready I no estic bloquejat -> Continuem
		b .Lfinal
		
		@; Comprovar si el procés no és del S.O i el seu PID és 0.
		.Lchange_context:
		ldr r4, =_gd_pidz			@; Carreguem adreça de la variable PID i sòcol del procés actual.
		ldr r4, [r4]				@; Carreguem el valor de la variable PIDZ.
		cmp r4, #0					@; Si PIDZ = 0, és el sistema operatiu -> Salvem el seu estat.
		beq .LsalvarProces			
		mov r4, r4, lsr #4			@; Aillem els 28 bits alts del PID.
		cmp r4, #0					@; Si el PID és 0, el procés ha acabat -> Restaurem el següent procés.
		beq .LrestaurarProces
		
		@; Crida a la funció de salvar l'estat del procés.
		.LsalvarProces:
		ldr r4, =_gd_nReady			@; Preparem els paràmetres per la crida a _gp_salvarProc.
		ldr r5, [r4]
		ldr r6, = _gd_pidz
		bl _gp_salvarProc			@; Cridem la funció _gp_salvarProc.
		str r5, [r4]				@; Guardem el valor actualitzat del nombre de processos a la cua Ready.
		
		@; Crida a la funció de restaurar l'estat del procés.
		.LrestaurarProces:
		ldr r4, =_gd_nReady			@; Preparem els paràmetres per la crida a _gp_restaurarProc.
		ldr r5, [r4]
		ldr r6, = _gd_pidz
		bl _gp_restaurarProc		@; Cridem la funció _gp_restaurarProc.
		
		
	.Lfinal:
	pop {r4-r7, pc}


	@; Rutina para salvar el estado del proceso interrumpido en la entrada
	@; correspondiente del vector _gd_pcbs
	@;Parámetros
	@; R4: dirección _gd_nReady
	@; R5: número de procesos en READY
	@; R6: dirección _gd_pidz
	@;Resultado
	@; R5: nuevo número de procesos en READY (+1)
	.global _gp_salvarProc
_gp_salvarProc:
	push {r8-r11, lr}
		@; --- MODIFICACIÓ FASE 2: Comprovar el bit 31  ---
		ldr r8, [r6]				@; Carreguem el valor de _gd_pidz
		tst r8, #0x80000000			@; Mirem si el bit 31 está a 1 o no
		and r8, r8, #0xF			@; Filtrem els 4 bits baixos del PIDZ per quedarn-nos amb el núm de sòcol	
		bne .Lskip_ready			@; Si el bit 31 estava actiu (Resultat != 0), saltem el procés de guardar a la cua de Ready

		@; Guardem a ready (Només si no està bloquejat)
		ldr r9, =_gd_qReady			@; Carreguem l'adreça de la cua de Ready.
		strb r8, [r9, r5]			@; Guardar el número de sòcol a la cua de Ready.
		add r5, #1					@; Incrementem el comptador de processos en estat Ready.
		
		.Lskip_ready:	
			@; Guardar el valor del PC al vector de PCB
			ldr r9, =_gd_pcbs			@; Carreguem l'adreça del vector de PCBs.
			mov r10, #24				@; Desem la dimensió de cadascun de les posicions del struct (6 ints * 4 bytes/int = 24).
			mla r9, r10, r8, r9			@; Calculem l'adreça de la posició del vector PCB del sòcol actual (Dimensió de cada posició * Número de sòcol + Adreça base del vector PCBs).
			mov r10, sp					@; Carreguem a R10 el punter de la pila SP en mode IRQ, per tant SP_irq.
			ldr r8, [r10, #60]			@; Carreguem a R8 el PC del procés a aturar (SP_irq amb un desplaçament de 60).
			str r8, [r9, #4] 			@; Guardem el valor del PC al segon camp del struct del PCB.
			
			@; Guardar el CPSR dins del seu PCB
			mrs r11, SPSR				@; Carreguem a R11 el SPSR (el CPSR del procés aturat).
			str r11, [r9, #12]			@; Guardem el SPSR al camp Status del PCB.
			
			@; Activar el mode sistema
			mrs r8, CPSR				@; Carreguem a R8 el CPSR (l'estat actual del processador).
			orr r8, r8, #0x1F			@; Posem els 5 bits de menys pes del CPSR a 1 (1111b) per activar el mode sistema.
			msr CPSR, r8				@; Tornem a guardar el CPSR amb el mode sistema actiu.
			
			@; Apilar els registres R0-R12 i R14 del procés a aturar.
			push {r14}					@; Apilem R14 (LR_sys, el Link Register del procés).
			ldr r8, [r10, #56]    		@; Carrega a R8 el valor de R12 (guardat a [SP_irq + 56])
			push {r8}             		@; Apila R12 a la pila del procés (SP_sys)
			ldr r8, [r10, #12]    		@; Carrega a R8 el valor de R11 (guardat a [SP_irq + 12])
			push {r8}             		@; Apila R11 a la pila del procés
			ldr r8, [r10, #8]     		@; Carrega a R8 el valor de R10 (guardat a [SP_irq + 8])
			push {r8}             		@; Apila R10 a la pila del procés
			ldr r8, [r10, #4]     		@; Carrega a R8 el valor de R9 (guardat a [SP_irq + 4])
			push {r8}					@; Apila R9 a la pila del procés
			ldr r8, [r10, #0]     		@; Carrega a R8 el valor de R8 (guardat a [SP_irq + 0])
			push {r8}             		@; Apila R8 a la pila del procés
			ldr r8, [r10, #32]    		@; Carrega a R8 el valor de R7 (guardat a [SP_irq + 32])
			push {r8}             		@; Apila R7 a la pila del procés
			ldr r8, [r10, #28]    		@; Carrega a R8 el valor de R6 (guardat a [SP_irq + 28])
			push {r8}             		@; Apila R6 a la pila del procés
			ldr r8, [r10, #24]    		@; Carrega a R8 el valor de R5 (guardat a [SP_irq + 24])
			push {r8}             		@; Apila R5 a la pila del procés
			ldr r8, [r10, #20]    		@; Carrega a R8 el valor de R4 (guardat a [SP_irq + 20])
			push {r8}             		@; Apila R4 a la pila del procés
			ldr r8, [r10, #52]   		@; Carrega a R8 el valor de R3 (guardat a [SP_irq + 52])
			push {r8}             		@; Apila R3 a la pila del procés
			ldr r8, [r10, #48]    		@; Carrega a R8 el valor de R2 (guardat a [SP_irq + 48])
			push {r8}             		@; Apila R2 a la pila del procés
			ldr r8, [r10, #44]    		@; Carrega a R8 el valor de R1 (guardat a [SP_irq + 44])
			push {r8}             		@; Apila R1 a la pila del procés
			ldr r8, [r10, #40]    		@; Carrega a R8 el valor de R0 (guardat a [SP_irq + 40])
			push {r8}             		@; Apila R0 a la pila del procés
			
			@; Guardem el valor de R13 (el Stack Pointer) al tercer camp del struct PCB.
			str r13, [r9, #8]			
			
			@; Tornar al mode d'execudció IRQ.
			mrs r8, CPSR				@; Carreguem el valor del CPSR (estat actual del processador).
			and r8, r8, #0xFFFFFFE0		@; Reiniciem els 5 bits de menys pes a 0.
			orr r8, r8, #0x12			@; Posem els 5 bits de menys pes en mode Normal Interrupt Request (10010b = 12h).
			msr CPSR, r8				@; Guardem el CPSR per confirmar el canvi de mode.
		
	pop {r8-r11, pc}


	@; Rutina para restaurar el estado del siguiente proceso en la cola de READY
	@;Parámetros
	@; R4: dirección _gd_nReady
	@; R5: número de procesos en READY
	@; R6: dirección _gd_pidz
	.global _gp_restaurarProc
_gp_restaurarProc:
	push {r8-r11, lr}
		
		@; Si nReady = 0, hem de restaurar el sistema operatiu (sòcol 0)
		cmp r5, #0
		beq .LrestaurarSO
		
		@; Carregar el número de sòcol del procés a restaurar.
		ldr r8, =_gd_qReady			@; Carreguem la cua de processos en estat Ready.
		ldrb r11, [r8]				@; Carreguem el número de sòcol del primer procés a la cua.
		sub r5, r5, #1				@; Reduim el nombre de processos al comptador de Ready.
		str r5, [r4]				@; Guardem el comptador actualitzat.
		mov r10, #0					@; Inicialitzem un comptador pel bucle de reordenar la cua.
		.LreorderQueue:
			cmp r10, r5				@; Mirem si ha acabat el bucle.
			beq .LreorderEnd		@; Si hem acabat sortim del bucle.
			ldrb r9, [r8, #1]		@; Carreguem la següent posició de la cua.
			strb r9, [r8]			@; La guardem a la posició actual.
			add r8, r8, #1			@; Avançem el índex de la cua.
			add r10, r10, #1		@; Incrementem comptador d'iteracions.
			b .LreorderQueue
		.LreorderEnd:
		b .Lcontinuar				@; Saltem la casolística de nReady = 0.
		
		.LrestaurarSO:
			mov r11, #0				@; Si nReady = 0, triem el sòcol 0
		
		.Lcontinuar:
		@; Desar el PID i el número de sòcol del procés a restaurar dins de la variable global _gd_pidz
		ldr r9, =_gd_pcbs			@; Carreguem l'adreça base del vector de PCBs dels processos.
		mov r10, #24				@; Desem la dimensió de cadascun de les posicions del struct (6 ints * 4 bytes/int = 24).
		mla r9, r10, r11, r9		@; Calculem la adreça del PCB del procés actual (Sòcol * Tamany PCB + Adreça base PCBs).
		ldr r10, [r9, #0]			@; Carreguem la primera posició (PID) del PCB del procés actual.
		mov r10, r10, lsl #4		@; Fem espai pel número de sòcol desplaçant 4 bits a l'esquerra el PID
		orr r10, r10, r11			@; Combinem número de sòcol amb el PID.
		str r10, [r6]				@; Guardem el PIDZ del procés restaurat a la variable _gd_pidz.
			
		@; Carregar el PC del procés a restaurar a la pila SP_irq
		ldr r8, [r9, #4]			@; Carreguem el PC (el segon camp del seu PCB) del procés a restaurar.
		mov r10, sp					@; Carreguem la pila SP en mode IRQ (SP_irq) a R10.
		str r8, [r10, #60]			@; Guardem el PC del procés dins de la posició 60 del SP_irq (el Link Register)
		
		@; Carreguem el CPSR del procés a restaurar
		ldr r8, [r9, #12]			@; Carreguem el estat del processador (CPSR del procés a restaurar) de la tercera posició del seu PCB.
		msr SPSR, r8				@; Guardem el CPSR al registre SPSR
		
		@; Canviem el mode d'execució a System
		mrs r8, CPSR				@; Carreguem el estat actual del processador
		orr r8, r8, #0x1F			@; Posem els 5 bits de mode d'execució a 1 (11111b)
		msr CPSR, r8				@; Guardem el nou CPSR en mode System.
		
		@; Restaurem el punter de pila del procés
		ldr r13, [r9, #8]			@; Carreguem a R13 (en mode System equival al SP_sys) el punter del PCB del procés a restaurar.
		
		@; Desapilem els registres R0-R12 i R14 del procés a restaurar i els posem a la SP_irq
		pop {r8}               		@; Desapila R0 de la pila del procés (SP_sys)
		str r8, [r10, #40]     		@; Guarda R0 a la pila d'IRQ (pos. 10)
		pop {r8}               		@; Desapila R1 de la pila del procés
		str r8, [r10, #44]     		@; Guarda R1 a la pila d'IRQ (pos. 11) 
		pop {r8}               		@; Desapila R2 de la pila del procés
		str r8, [r10, #48]     		@; Guarda R2 a la pila d'IRQ (pos. 12) 
		pop {r8}               		@; Desapila R3 de la pila del procés
		str r8, [r10, #52]     		@; Guarda R3 a la pila d'IRQ (pos. 13) 
		pop {r8}               		@; Desapila R4 de la pila del procés
		str r8, [r10, #20]     		@; Guarda R4 a la pila d'IRQ (pos. 5) 
		pop {r8}               		@; Desapila R5 de la pila del procés
		str r8, [r10, #24]     		@; Guarda R5 a la pila d'IRQ (pos. 6)
		pop {r8}               		@; Desapila R6 de la pila del procés
		str r8, [r10, #28]     		@; Guarda R6 a la pila d'IRQ (pos. 7) 
		pop {r8}               		@; Desapila R7 de la pila del procés
		str r8, [r10, #32]     		@; Guarda R7 a la pila d'IRQ (pos. 8) 
		pop {r8}               		@; Desapila R8 de la pila del procés
		str r8, [r10, #0]      		@; Guarda R8 a la pila d'IRQ (pos. 0)
		pop {r8}               		@; Desapila R9 de la pila del procés
		str r8, [r10, #4]      		@; Guarda R9 a la pila d'IRQ (pos. 1)
		pop {r8}               		@; Desapila R10 de la pila del procés
		str r8, [r10, #8]      		@; Guarda R10 a la pila d'IRQ (pos. 2) 
		pop {r8}               		@; Desapila R11 de la pila del procés
		str r8, [r10, #12]     		@; Guarda R11 a la pila d'IRQ (pos. 3) 
		pop {r8}               		@; Desapila R12 de la pila del procés
		str r8, [r10, #56]     		@; Guarda R12 a la pila d'IRQ (pos. 14) 
		pop {r14}              		@; Desapila el registre R14 (LR_sys) de la pila del procés i el restaura directament al registre R14 del mode actual (System)
		
		@; Tornem al mode d'execució IRQ
		mrs r8, CPSR				@; Carreguem el estat actual del processador.
		and r8, r8, #0xFFFFFFE0		@; Reiniciem els 5 bits de menys pes (mode d'execució) a 0.ç
		orr r8, r8, #0x12			@; Posem els bits de mode d'execució en mode Normal Interrupt Request (10010b = 12h).
		msr CPSR, r8				@; Guardem el CPSR amb el nou mode.
	pop {r8-r11, pc}
	
	
	.global _gp_actualizarDelay
	@; Rutina para actualizar la cola de procesos retardados, poniendo en
	@; cola de READY aquellos cuyo número de tics de retardo sea 0
_gp_actualizarDelay:
	push {r0-r10, lr}
		ldr r4, =_gd_nDelay
		ldr r5, [r4]				@; Carreguem el comptador de processos de la cua Delay
		cmp r5, #0
		beq .Lfi_update_delay		@; Si no hi ha cap procés a la cua, sortim
		
		ldr r6, =_gd_qDelay			@; Carreguem adreça de la cua
		mov r7, #0					@; Inicialitzem un index i pel bucle
		
		.Lloop_chk_delay:
			cmp r7, r5				@; Si i >= nDelay, hem acabat el bucle
			bge .Lfi_update_delay
			
			@; Llegim el seguent element de qDelay
			lsl r8, r7, #2			@; Offset pels 4 bytes per entrada (i * 4)
			ldr r0, [r6, r8]		@; Carreguem el element actual
			
			sub r0, r0, #1			@; Decremenemtem el comptador de tics
			
			@; Comprovar si els tics han arribat a 0
			ldr r1, =0xFFFF			@; Màscara pels 16 bits baixos (tics)
			and r2, r0, r1			@; R2 = tics restants
			cmp r2, #0
			beq .Ldespertar_proces	@; Si els tics = 0, hem de despertar el procés
			
			str r0, [r6, r8]		@; Si encara li queden tics, actualitzem valor i passem al seguent procés
			add r7, r7, #1			@; Incrementem index i
			b .Lloop_chk_delay
			
			.Ldespertar_proces:
				lsr r9, r0, #16			@; Desplaçem per aillar el número de sòcol
				
				@; Afegir el procés a la cua de Ready
				ldr r1, =_gd_nReady
				ldr r2, [r1]			@; Carreguem el comptador de la cua de Ready
				ldr r3, =_gd_qReady		@; Adreça de la cua de Ready
				strb r9, [r3, r2]		@; Posem el sòcol a qReady[nReady]
				add r2, r2, #1
				str r2, [r1]			@; nReady++
			
			
			@; Eliminar el procés de la cua Delay
			add r10, r7, #1				@; Index (j) del procés a la dreta del procés a esborrar.	
			.Lshift_del_loop:
				cmp r10, r5
				bge .Lfi_shift_del		@; Si hem arribat al final de la cua, sortim
				
				lsl r1, r10, #2			@; Calculem el offset de l'índex j (4 bytes per entrada)
				ldr r2, [r6, r1]		@; Llegim qDelay[j]
				sub r3, r1, #4			@; Offset j - 1
				str r2, [r6, r3]		@; Guardem qDelay[j] a qDelay[j-1]
				
				add r10, r10, #1
				b .Lshift_del_loop
			
			@; Actualitzar nDelay
			.Lfi_shift_del:
				sub r5, r5, #1			@; nDelay--
				str r5, [r4]			@; Actualitzem variable global nDelay
				b .Lloop_chk_delay		@; Saltem sense incrementar R7 (i) per compensar pel desplaçament cap a l'esquerra de la cua.
		
		.Lfi_update_delay:					
	pop {r0-r10, pc}
	
	
	.global _gp_numProc
	@;Resultado
	@; R0: número de procesos total
_gp_numProc:
	push {r1-r2, lr}
	mov r0, #1				@; contar siempre 1 proceso en RUN
	ldr r1, =_gd_nReady
	ldr r2, [r1]			@; R2 = número de procesos en cola de READY
	add r0, r2				@; añadir procesos en READY
	ldr r1, =_gd_nDelay
	ldr r2, [r1]			@; R2 = número de procesos en cola de DELAY
	add r0, r2				@; añadir procesos retardados
	pop {r1-r2, pc}


	.global _gp_crearProc
	@; prepara un proceso para ser ejecutado, creando su entorno de ejecución y
	@; colocándolo en la cola de READY
	@;Parámetros
	@; R0: intFunc funcion,
	@; R1: int zocalo,
	@; R2: char *nombre
	@; R3: int arg
	@;Resultado
	@; R0: 0 si no hay problema, >0 si no se puede crear el proceso
_gp_crearProc:
	push {r4-r7, lr}
		@; Comprovacions inicials de sòcol.
		cmp r1, #0					@; Mirem si el sòcol és 0 (sistema operatiu).
		beq .Ldeny					@; Retornem error si és el sistema.
		ldr r4, =_gd_pcbs			@; Carreguem l'adreça del vector de PCBs.
		mov r5, #24					@; Tamany de cada posició del vector (6 ints * 4 bytes/int).
		mla r6, r1, r5, r4			@; Calculem l'adreça del PCB del sòcol (Núm. sòcol * Tamany de cada posició + Adreça base vector PCBs).
		ldr r7, [r6, #0]			@; Mirem el PID del procés a crear (1a posició del seu PCB).
		cmp r7, #0					@; Comprovem que el PID sigui 0 (en cas contrari, el sòcol passat per R1 està ocupat per un altre procés).
		bne .Ldeny					@; Retornem error si el sòcol està ocupat.
		
		@; Assignem un nou PID al procés
		ldr r4, =_gd_pidCount		@; Carreguem l'adreça de la variable comptador de PIDs.
		ldr r5, [r4]				@; Carreguem el valor de la variable.
		add r5, r5, #1				@; Incrementem el comptador.
		str r5, [r4]				@; Actualitzem la variable.
		str r5, [r6, #0]			@; Actualitzem el camp PID del PCB del procés (1a posició).
		
		@; Guardem la direcció inicial de la rutina dins del seu PCB.
		add r0, r0, #4				@; Sumem 4 a la direcció inicial per compensar el retorn d'excepció IRQ.
		str r0, [r6, #4]			@; Guardem la direcció inicial al camp PC del PCB del procés.
		
		@; Guardar el nom del procés.
		ldr r4, [r2]				@; Carreguem el nom.
		str r4, [r6, #16]			@; Desem el nom en el camp keyName del PCB del procés.
		
		@; Carregar la direcció de la pila del procés
		ldr r4, =_gd_stacks			@; Adreça del vector de piles dels processos.
		mov r5, #512				@; Dimensió de cada pila (128 registres * 4 bytes/registre).
		mla r7, r5, r1, r4			@; Calculem l'adreça de la pila del procés (Sòcol * Dimensió pila + Adreça base vector piles)
		add r7, r7, r5				@; Ens coloquem al TOP de la pila
		
		@; Col·locar la funció terminarProc al principi de la pila del procés (a la posició LR)
		ldr r4, =_gp_terminarProc	@; Carreguem l'adreça de la funció per finalitzar un procés usuari.
		sub r7, r7, #4				@; Fem espai a la pila del procés per l'adreça de la funció.
		str r4, [r7]				@; Guardem l'adreça de la funció a la pila del procés.
		
		@; Guardem els registres R0-R12 i R14
		mov r4, #0					@; Index del bucle.		
		mov r5, #0					@; Inicializtem els registres R1-R12 a 0.
		.Lregisters:
			sub r7, #4				@; Fem espai pel registre a la pila.
			str r5, [r7]			@; Guardem a la pila del procés.
			add r4, r4, #1			@; Incrementem index bucle.
			cmp r4, #12				@; Mirem si ha finalitzat el bucle.
			bne .Lregisters			@; Si no ha acabat, fem una altre iteració.
		sub r7, #4					@; Fem espai per R0.
		str r3, [r7]				@; Passem el/s argument/s a R0.
		
		@; Guardem la direcció de la pila al tercer camp del PCB del procés.
		str r7, [r6, #8]
		
		@; Desem el valor inicial del CPSR en el camp Status del PCB del procés.
		mov r7, #0x1F				@; Inicialitzem a R7 els 5 bits corresponents al mode System del processador (11111b).
		str r7, [r6, #12]			@; Desem el valor al camp Status del PCB.
			
		@; Inicalitzem variable workTicks a 0 i la desem al PCB.
		mov r7, #0					@; Inicialitzem R7 a 0.
		str r7, [r6, #20]			@; Desem la variable workTicks inicialitzada a 0.
		
		@; Guardem el sòcol al final de la cua de processos en estat Ready.
		ldr r4, =_gd_nReady			@; Adreça del comptador de processos en estat Ready.
		ldr r5, [r4]				@; Valor del comptador de processos en Ready.
		ldr r6, =_gd_qReady			@; Adreça de la cua de processos en Ready.
		strb r1, [r6, r5]			@; Guardem el sòcol en la cua de Ready.
		add r5, r5, #1				@; Incrementem el valor del comptador de Ready.
		str r5, [r4]				@; Guardem el valor del comptador.
	
		mov r0, #0					@; Retornem 0 per indicar que tot ha anat bé.
		b .Lend			
		
		@; Codi de tirar error.
		.Ldeny:
			mov r0, #1				@; Codi d'error.
			
		.Lend:
	pop {r4-r7, pc}


	@; Rutina para terminar un proceso de usuario:
	@; pone a 0 el campo PID del PCB del zócalo actual, para indicar que esa
	@; entrada del vector _gd_pcbs está libre; también pone a 0 el PID de la
	@; variable _gd_pidz (sin modificar el número de zócalo), para que el código
	@; de multiplexación de procesos no salve el estado del proceso terminado.
_gp_terminarProc:
	ldr r0, =_gd_pidz
	ldr r1, [r0]			@; R1 = valor actual de PID + zócalo
	and r1, r1, #0xf		@; R1 = zócalo del proceso desbancado
	bl _gp_inhibirIRQs
	str r1, [r0]			@; guardar zócalo con PID = 0, para no salvar estado			
	ldr r2, =_gd_pcbs
	mov r10, #24
	mul r11, r1, r10
	add r2, r11				@; R2 = dirección base _gd_pcbs[zocalo]
	mov r3, #0
	str r3, [r2]			@; pone a 0 el campo PID del PCB del proceso
	str r3, [r2, #20]		@; borrar porcentaje de USO de la CPU
	ldr r0, =_gd_sincMain
	ldr r2, [r0]			@; R2 = valor actual de la variable de sincronismo
	mov r3, #1
	mov r3, r3, lsl r1		@; R3 = máscara con bit correspondiente al zócalo
	orr r2, r3
	str r2, [r0]			@; actualizar variable de sincronismo
	bl _gp_desinhibirIRQs
.LterminarProc_inf:
	bl _gp_WaitForVBlank	@; pausar procesador
	b .LterminarProc_inf	@; hasta asegurar el cambio de contexto
	
	
	.global _gp_matarProc
	@; Rutina para destruir un proceso de usuario:
	@; borra el PID del PCB del zócalo referenciado por parámetro, para indicar
	@; que esa entrada del vector _gd_pcbs está libre; elimina el índice de
	@; zócalo de la cola de READY o de la cola de DELAY, esté donde esté;
	@; Parámetros:
	@;	R0:	zócalo del proceso a matar (entre 1 y 15).
_gp_matarProc:
	push {r0-r8, lr}
		
		@; Validem el sòcol
		cmp r0, #0
		beq .Lfi_matar				@; No podem matar el S.O (sòcol = 0)
		
		bl _gp_inhibirIRQs			@; Iniciem secció crítica
		
		@; Alliberem el PCB
		ldr r1, =_gd_pcbs
		mov r2, #PCB_SIZE			@; Tamany total del PCB en bytes
		mul r2, r0, r2				@; Desplaçament (Num. sòcol * Tamany PCB)
		add r1, r1, r2				@; Punter al PCB (adreça base + desplaçament)
		mov r2, #0					@; Preparem el 0 pel PID
		str r2, [r1, #PCB_PID]		@; Posem PID = 0 per marcar el sòcol com a lliure
		
		@; Buscar i eliminar de la cua de Ready
		ldr r1, =_gd_nReady
		ldr r2, [r1]				@; Comptador de la cua de ready
		ldr r3, =_gd_qReady
		mov r4, #0					@; R4 = index (i)
		
		.Lbucle_ready:
			cmp r4, r2				@; Hem acabat de mirar la cua
			bge .Lfi_ready
			ldrb r5, [r3, r4]		@; Carreguem qReady[i]
			cmp r5, r0				@; Mirem si és el sòcol que volem matar
			beq .Lesborrar_ready	@; Saltem a esborrar-lo
			add r4, r4, #1			@; Incrementem comptador i
			b .Lbucle_ready
		
		@; Desplaçem tots els elements a la dreta del procés cap a l'esquerra
		.Lesborrar_ready:
			add r5, r4, #1 			@; R5 = i + 1
		.Lshift_ready:
			cmp r5, r2
			bge .Lfi_shift_ready	@; Si hem acabat de desplaçar, sortim del bucle
			ldrb r6, [r3, r5]		@; Carreguem la seguent posicio de la cua
			sub r7, r5, #1			@; Preparem index desplaçat a l'esquerra
			strb r6, [r3, r7]		@; Guardem
			add r5, r5, #1			@; Incrementem comptador
			b .Lshift_ready
		.Lfi_shift_ready:
			sub r2, r2, #1			@; nReady--
			str r2, [r1]			@; Actualitzem la variable global nReady
		
		@; Buscar i eliminar el procés de la cua de Delay
		.Lfi_ready:
			ldr r1, =_gd_nDelay		
			ldr r2, [r1]			@; Carreguem nDelay
			ldr r3, =_gd_qDelay		@; Adreça de la cua de Delay
			mov r4, #0				@; Inicialitzem comptador pel bucle.
			
		.Lbucle_delay:
			cmp r4, r2				
			bge .Lfi_delay				@; Hem acabat de mirar la cua
			ldr r5, [r3, r4, lsl #2]	@; Carreguem qDelay[i] amb el offset dels 4 bytes
			lsr r6, r5, #16				@; Extraiem els 8 bits alts (núm. de sòcol)
			and r6, r6, #0xFF			@; Netejem per si hi han bits de més
			cmp r6, r0
			beq .Lesborrar_delay		@; Si hem trobat el sòcol, saltem a esborrar
			add r4, r4, #1				@; Incrementem comptador
			b .Lbucle_delay
		
		@; Desplaçem tots els elements a la dreta del procés cap a l'esquerra
		.Lesborrar_delay:
			add r5, r4, #1				@; R5 = i + 1
		.Lshift_delay:
			cmp r5, r2
			bge .Lfi_shift_delay		@; Si hem acabat de desplaçar, sortim
			ldr r6, [r3, r5, lsl #2]	@; Llegim la seguent posicio
			sub r7, r5, #1				@; Movem el índex a l'esquerra
			str r6, [r3, r7, lsl #2]	@; Guardem a la posició anterior
			add r5, r5, #1				@; Incrementem comptador
			b .Lshift_delay
		.Lfi_shift_delay:
			sub r2, r2, #1				@; nDelay--
			str r2, [r1]				@; Actualitzem variable global nDelay
			
		@; Comprovem si ens hem matat a nosaltres mateixos
		.Lfi_delay:
			bl _gp_desinhibirIRQs		@; Fi secció crítica
			
			ldr r1, =_gd_pidz
			ldr r1, [r1]
			and r1, r1, #0xF			@; Filtrem els 4 bits de sòcol
			cmp r1, r0					
			bne .Lfi_matar
			bl _gp_WaitForVBlank		@; Forçem el canvi de context en cas de suicidi
			
		.Lfi_matar:	

	pop {r0-r8, pc}

	
	.global _gp_retardarProc
	@; retarda la ejecución de un proceso durante cierto número de segundos,
	@; colocándolo en la cola de DELAY
	@;Parámetros
	@; R0: int nsec
_gp_retardarProc:
	push {r0-r5, lr}
		
		@; Comprovem que nsec > 0
		cmp r0, #0
		ble .Lwait_only				@; Si és 0, només cedim CPU
		
		@; Obtenir el sòcol
		ldr r3, =_gd_pidz
		ldr r3, [r3]				@; Carreguem el valor de la variable PIDZ
		and r3, r3, #0xF			@; R3 = Núm. de sòcol (4 bits baixos de PIDZ)
		cmp r3, #0					@; Mirem si és el S.O
		beq .Lwait_only				@; Si ho és, només cedim
		
		bl _gp_inhibirIRQs			@; Iniciem la secció crítica
		
		@; Calcular els tics (nsec * 60)
		mov r1, #VBLANK_FREQ		@; Carreguem la freq. de refresc
		mul r2, r0, r1				@; R2 = Tics totals
		
		@; Construim el word (8 bits alts = sòcol, 16 bits baixos = tics a retardar)
		lsl r4, r3, #16				@; Desplaçem el sòcol fins als bits 16..19
		ldr r1, =0xFFFF				@; 16 bits a 1 
		and r2, r2, r1				@; Assegurem que els tics ocupin com a molt 16 bits
		orr r4, r4, r2				@; R4 = (Sòcol << 16) | Tics
		
		@; Afegim el word a la cua de _gd_nDelay
		ldr r0, =_gd_nDelay			@; Adreça de nDelay (comptador de retards a la cua)
		ldr r1, [r0]				@; Valor de nDelay
		
		ldr r5, =_gd_qDelay			@; Adreça de qDelay (la cua de retards)
		lsl r3, r1, #2				@; Calculem el offset per la cua (nDelay * 4 bytes)
		str r4, [r5, r3]			@; Guardem a qDelay[nDelay]
		
		@; Incrementem el comptador nDelay
		add r1, r1, #1
		str r1, [r0]
		
		@; Posem el bit de més pes del PIDZ a 1
		ldr r0, =_gd_pidz
		ldr r1, [r0]
		orr r1, r1, #0x80000000 @; Posem el bit 31 a 1
		str r1, [r0]
		
		bl _gp_desinhibirIRQs		@; Finalitzem la secció crítica
		
		.Lwait_only:
			bl _gp_WaitForVBlank	@; Cedim la CPU
		
	pop {r0-r5, pc}			@; no retornará hasta que se haya agotado el retardo


	.global _gp_inihibirIRQs
	@; pone el bit IME (Interrupt Master Enable) a 0, para inhibir todas
	@; las IRQs y evitar así posibles problemas debidos al cambio de contexto
_gp_inhibirIRQs:
	push {r0-r1, lr}
		ldr r0, =IME			@; Carreguem l'adreça del IME
		mov r1, #0				@; Carreguem un 0
		str r1, [r0]			@; Guardem el 0 a l'adreça del IME
	pop {r0-r1, pc}


	.global _gp_desinihibirIRQs
	@; pone el bit IME (Interrupt Master Enable) a 1, para desinhibir todas
	@; las IRQs
_gp_desinhibirIRQs:
	push {r0-r1, lr}
		ldr r0, =IME			@; Carreguem l'adreça del IME
		mov r1, #1				@; Carreguem un 1
		str r1, [r0]			@; Guardem el 1 a l'adreça del IME
	pop {r0-r1, pc}


	.global _gp_rsiTIMER0
	@; Rutina de Servicio de Interrupción (RSI) para contabilizar los tics
	@; de trabajo de cada proceso: suma los tics de todos los procesos y calcula
	@; el porcentaje de uso de la CPU, que se guarda en los 8 bits altos de la
	@; entrada _gd_pcbs[z].workTicks de cada proceso (z) y, si el procesador
	@; gráfico secundario está correctamente configurado, se imprime en la
	@; columna correspondiente de la tabla de procesos.
_gp_rsiTIMER0:
	push {r0-r6, lr}
		
		@; Calcular Tics Totals
		ldr r4, =_gd_pcbs
		mov r5, #0						@; Acumulador de tics totals
		mov r6, #0						@; Index del bucle
		
		.Lloop_suma:
			ldr r3, [r4, #PCB_TICKS]
			ldr r2, =0xFFFFFF			@; Màscara 24 bits
			and r3, r3, r2
			add r5, r5, r3
			
			add r4, r4, #PCB_SIZE
			add r6, r6, #1
			cmp r6, #16
			blt .Lloop_suma
			
		cmp r5, #50
		blt .Lfi_timer					@; Si no ha passat 1 segon, sortim
		
		@; Calcular Percentatges i Pintar
		ldr r4, =_gd_pcbs
		mov r6, #0						@; Reiniciem index sòcol
		
		.Lloop_calc:
			ldr r3, [r4, #PCB_TICKS]
			ldr r2, =0xFFFFFF
			and r0, r3, r2				@; R0 = Tics actuals (% ús)
			
			lsl r1, r0, #24				@; Guardem el % als 8 bits alts
			str r1, [r4, #PCB_TICKS]	@; I posem a 0 els tics baixos
			
			@; Imprimim porcentatge
			push {r0-r6}				@; Guardem registres abans de pintar
			
			@; Només pintem si el PID != 0 o és el sòcol 0
			ldr r1, [r4, #PCB_PID]
			cmp r1, #0
			bne .Lpintar
			cmp r6, #0
			bne .Lno_pintar				@; Si PID=0 i no és sòcol 0, saltem
			
		.Lpintar:
			@; Convertir R0 (0-99) a text
			mov r2, r0					@; R2 = Número inicial (serà les unitats)
			mov r3, #0					@; R3 = Comptador de desenes
			
		.Ldiv10_loop:
			cmp r2, #10
			blt .Ldiv10_end
			sub r2, r2, #10				@; Restem 10
			add r3, r3, #1				@; Incrementem desenes
			b .Ldiv10_loop
			
		.Ldiv10_end:
			@; Ara R3 = Desenes, R2 = Unitats. Convertim a ASCII.
			add r2, r2, #48
			add r3, r3, #48
			
			@; Preparar buffer a la pila (4 bytes)
			sub sp, sp, #4
			mov r1, sp
			
			@; Gestió del zero a l'esquerra (si desenes és '0', posem espai)
			cmp r3, #48
			bne .Lstore_chars
			mov r3, #32					@; Espai en blanc
			
		.Lstore_chars:
			strb r3, [r1, #1]			@; Desenes
			strb r2, [r1, #2]			@; Unitats
			mov r2, #32
			strb r2, [r1, #0]			@; Espai davant (alineació)
			mov r2, #0
			strb r2, [r1, #3]			@; Final de string
			
			@; Cridar _gs_escribirStringSub
			mov r0, r1					@; String
			add r1, r6, #4				@; Fila = Sòcol + 4
			mov r2, #28					@; Columna = 28 (Uso)
			mov r3, #0					@; Color = 0 (Blanc)
			bl _gs_escribirStringSub
			
			add sp, sp, #4				@; Netejem pila local
			
		.Lno_pintar:
			pop {r0-r6}					@; Recuperem registres
			@; -----------------------------
			
			add r4, r4, #PCB_SIZE
			add r6, r6, #1
			cmp r6, #16
			blt .Lloop_calc
			
		ldr r4, =_gd_sincMain
		ldr r5, [r4]
		orr r5, r5, #1
		str r5, [r4]
		
	.Lfi_timer:
	pop {r0-r6, pc}

	
	.global _ga_send
	@; Rutina per enviar una dada de tipus int a la bústia indicada per paràmetre.
	@; Paràmetres d'entrada:
	@; R0: n (ID bústia, 0-7).
	@; R1: data (dada de tipus int).
	@; Resultat:
	@; R0: 1 si s'ha enviat amb èxit, 0 si hi ha hagut un error (bústia plena o ID invàlid)
_ga_send:
	push {r4-r8, lr}
		@; Validem n (ID de la bústia)
		cmp r0, #8
		bhs .Lsend_fail_idx				@; Saltem a retornar error si el ID de la bústia >= 8.
		
		@; Calculem l'adreça de la bústia per enviar la dada.
		ldr r4, =_gd_mailboxes			@; Carreguem l'adreça base dels vectors de les bústies.
		mov r5, #MAILBOX_STRUCT_SIZE	@; Carreguem el tamany de cada posició del vector de bústies.
		mla r4, r0, r5, r4				@; Calculem l'adreça de la bústia n (n * Tamany de cada posició + Adreça base vectors)
		
		bl _gp_inhibirIRQs				@; Iniciem la secció crítica
		
		@; Llegim el comptador de dades (count) de la bústia per comprovar que no estigui plena.
		ldr r5, [r4, #MB_COUNT]			@; Carreguem el offset 72 (count) de la bústia.
		cmp r5, #MAILBOX_QUEUE_SIZE		@; Comparem el comptador amb el nombre màxim de dades.
		bhs .Lsend_full					@; Si el comptador >= 16, la bústia està plena, per tant tirem error.
		
		@; Afegim la dada a la cua.
		ldr r6, [r4, #MB_TAIL]			@; Carreguem a R6 el índex del final de la cua (tail).
		add r7, r4, r6, lsl #2			@; Calculem l'adreça del índex tail (Adreça del inici de la bústia + (índex tail * 4).
		str r1, [r7]					@; Guardem la dada en la posició.
		
		@; Actualitzem índex tail (tail++)
		add r6, r6, #1					@; Incrementem índex tail
		cmp r6, #MAILBOX_QUEUE_SIZE		@; Mirem si el índex tail és igual a 16.
		moveq r6, #0					@; Si tail == 16, posem tail = 0 (Round Robin)
		str r6, [r4, #MB_TAIL]			@; Tornem a guardar el índex tail en el vector de la bústia.
		
		@; Incrementem variable comptador de dades
		add r5, r5, #1					@; Incrementem el comptador.
		str r5, [r4, #MB_COUNT]			@; Guardem la variable comptador en el vector de la bústia.
		
		@; Gestió de desbloqueig
		ldr r8, [r4, #MB_NWAIT]
		cmp r8, #0
		beq .Lsend_ok					@; Ningú està esperant per tant sortim
		
		add r6, r4, #MB_WAIT			@; Punter al array pWaiting
		ldrb r7, [r6]					@; R7 = PID del procés que està esperant
		
		mov r2, #0						@; Index i pel bucle de desplaçament
		@; Esborrem el procés de la cua pWaiting
		.Lshift_wait_loop:
			add r3, r2, #1				@; Index j = i + 1
			cmp r3, r8
			bge .Lshift_wait_end		@; Si j >= nWaiting, hem acabat de desplaçar
			ldrb r1, [r6, r3]			@; Carreguem pWaiting[j]
			strb r1, [r6, r2]			@; Guardem a pWaiting[i]
			add r2, r2, #1				@; Incrementem index i
			b .Lshift_wait_loop
		.Lshift_wait_end:
		
		sub r8, r8, #1				@; Decrementem comptador nWaiting
		str r8, [r4, #MB_NWAIT]		@; Actualitzem variable global
		
		@; Posem el procés a la cua de Ready
		ldr r2, =_gd_nReady
		ldr r3, [r2]				@; Comptador de processos a la cua de Ready
		ldr r1, =_gd_qReady
		strb r7, [r1, r3]			@; qReady[nReady] = Procés despertat
		
		add r3, r3, #1				@; nReady++
		str r3, [r2]				@; Actualitzem variable global
			
		.Lsend_ok:
			bl _gp_desinhibirIRQs	@; Tanquem secció crítica
			mov r0, #1				@; Codi 1 (OK)
			b .Lsend_end
			
		.Lsend_full:
			bl _gp_desinhibirIRQs	@; Tanquem secció crítica
			mov r0, #0				@; Codi 0 (Bústia plena)
		
		.Lsend_fail_idx:
			mov r0, #0				@; Codi 0 (Index invàlid)
			
		.Lsend_end:
	pop {r4-r8, pc}
	
	
	.global _ga_receive
	@; Rutina per rebre una dada a través de la bústia indicada per paràmetre.
	@; Aquesta funció bloqueja el procés que la crida en cas de que la bústia indicada estigui buida.
	@; Un procés només es desbloquejarà en el moment que la bústia que ha demanat deixi d'estar buida.
	@; Paràmetres d'entrada:
	@; R0: n (ID bústia, 0-7)
	@; Retorna:
	@; R0: la dada rebuda de la bústia
_ga_receive:
	push {r4-r8, lr}
		mov r8, r0						@; Guardem ID de bústia
		
		.Lretry_receive:
			@; Calculem adreça de la bústia
			ldr r4, =_gd_mailboxes
			mov r5, #MAILBOX_STRUCT_SIZE
			mla r4, r8, r5, r4			@; R4 = Punter a la bústia (Adreça + (desplaçament * ID))
			
			bl _gp_inhibirIRQs			@; Obrim secció crítica
			
			@; Comprovem si hi han dades
			ldr r5, [r4, #MB_COUNT]
			cmp r5, #0					
			beq .Lreceive_block			@; Si el comptador de dades = 0, la bústia està buida, bloquejem
			
			@; Llegim la dada
			ldr r6, [r4, #MB_HEAD]
			add r7, r4, r6, lsl #2		@; Adreça = Base + (HEAD * 4)
			ldr r0, [r7]				@; Carreguem la dada
			
			@; Actualitzar head i count
			add r6, r6, #1
			cmp r6, #MAILBOX_QUEUE_SIZE
			moveq r6, #0				@; Round Robin
			
			sub r5, r5, #1
			str r5, [r4, #MB_COUNT]		@; Actualitzem comptador de dades de la bústia
			
			bl _gp_desinhibirIRQs
			b .Lreceive_end
			
			@; -------------------------------BLOQUEIG DEL PROCÉS-----------------------------------------
			.Lreceive_block:
			
			@; Obtenir el sòcol
			ldr r1, =_gd_pidz
			ldr r1, [r1]
			and r1, r1, #0xF			@; Filtrem el sòcol

			@; Afegir-me a la cua d'espera de la bústia (pWaiting)
			ldr r2, [r4, #MB_NWAIT]		@; nWaiting
			add r3, r4, #MB_WAIT		@; Adreça base pWaiting
			strb r1, [r3, r2]			@; Guardem el sòcol a pWaiting[nWaiting]
			add r2, r2, #1				
			str r2, [r4, #MB_NWAIT]		@; nWaiting++

			@; Eliminar-me de la cua READY posant el bit 31 del PIDZ a 1
			ldr r0, =_gd_pidz			@; Carreguem adreça de pidz (línia nova)
			ldr r1, [r0]				@; Llegim el valor actual (línia nova)
			orr r1, r1, #0x80000000		@; Activem Bit 31 per indicar bloqueig (línia nova)
			
			and r8, r8, #0x7			@; Assegurem que l'ID (R8) és 0-7
			lsl r8, r8, #28				@; Desplacem l'ID a la posició 28 (bits alts)
			orr r1, r1, r8				@; El combinem amb el PIDZ actual
			
			str r1, [r0]				@; Guardem el canvi (línia nova)

		.Lblock_wait:
			bl _gp_desinhibirIRQs		@; Tanquem secció crítica
			bl _gp_WaitForVBlank		@; Cedim CPU
			b .Lretry_receive			@; Si algú ens desperta, tornem a mirar a veure si hi han dads

		.Lreceive_end:
	pop {r4-r8, pc}
			

	
.end
