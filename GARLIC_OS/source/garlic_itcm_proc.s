@;==============================================================================
@;
@;	"garlic_itcm_proc.s":	código de las funciones de control de procesos (1.0)
@;						(ver "garlic_system.h" para descripción de funciones)
@;
@;==============================================================================

.section .itcm,"ax",%progbits

	.arm
	.align 2
	
	
	MAILBOX_QUEUE_SIZE = 16
	MAILBOX_STRUCT_SIZE = (MAILBOX_QUEUE_SIZE * 4) + 4 + 4 + 4
	
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
		@; Incrementar comptador tics.
		ldr r4, =_gd_tickCount		@; Carreguem l'adreça de la variable comptador de tics global.
		ldr r5, [r4] 				@; Carreguem el valor de la variable comptador de tics.
		add r5, #1					@; Incrementem el valor de la variable.
		str r5, [r4]				@; Guardem el valor modificat.
		
		@; Comprovar si hi ha algun procés a la cua nReady.
		ldr r6, =_gd_nReady			@; Carregum l'adreça de la variable de nombre de processos a la cua.
		ldr r7, [r6]				@; Carreguem el valor de la variable.
		cmp r7, #0					@; Mirem si hi han processos a la cua.
		beq .Lfinal					@; Si no hi han processos a la cua, finalitzem la RSI.
		
		@; Comprovar si el procés no és del S.O i el seu PID és 0.
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
		
		
	@;.Lfinal:
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
		@; Guardar el número de sòcol a la cua de Ready
		ldr r8, [r6]				@; Carreguem el valor del PID i el número de sòcol del procés a salvar.
		and r8, r8, #0xF			@; Filtrem els 4 bits baixos (el número de sòcol).
		ldr r9, =_gd_qReady			@; Carreguem l'adreça de la cua de Ready.
		strb r8, [r9, r5]			@; Guardar el número de sòcol a la cua de Ready a la següent posició buida.
		add r5, #1					@; Incrementem el comptador de processos en estat Ready.
		
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
	push {lr}


	pop {pc}

	
	.global _gp_retardarProc
	@; retarda la ejecución de un proceso durante cierto número de segundos,
	@; colocándolo en la cola de DELAY
	@;Parámetros
	@; R0: int nsec
_gp_retardarProc:
	push {lr}


	pop {pc}			@; no retornará hasta que se haya agotado el retardo


	.global _gp_inihibirIRQs
	@; pone el bit IME (Interrupt Master Enable) a 0, para inhibir todas
	@; las IRQs y evitar así posibles problemas debidos al cambio de contexto
_gp_inhibirIRQs:
	push {lr}


	pop {pc}


	.global _gp_desinihibirIRQs
	@; pone el bit IME (Interrupt Master Enable) a 1, para desinhibir todas
	@; las IRQs
_gp_desinhibirIRQs:
	push {lr}


	pop {pc}


	.global _gp_rsiTIMER0
	@; Rutina de Servicio de Interrupción (RSI) para contabilizar los tics
	@; de trabajo de cada proceso: suma los tics de todos los procesos y calcula
	@; el porcentaje de uso de la CPU, que se guarda en los 8 bits altos de la
	@; entrada _gd_pcbs[z].workTicks de cada proceso (z) y, si el procesador
	@; gráfico secundario está correctamente configurado, se imprime en la
	@; columna correspondiente de la tabla de procesos.
_gp_rsiTIMER0:
	push {lr}

	
	pop {pc}


	
	.global _ga_send
	@; Rutina per enviar una dada de tipus int a la bústia indicada per paràmetre.
	@; Paràmetres d'entrada:
	@; R0: n (ID bústia, 0-7).
	@; R1: data (dada de tipus int).
	@; Resultat:
	@; R0: 1 si s'ha enviat amb èxit, 0 si hi ha hagut un error (bústia plena o ID invàlid)
_ga_send:
	push {r4-r7, lr}
		@; Validem n (ID de la bústia)
		cmp r0, #8
		bhs .Lsend_error				@; Saltem a retornar error si el ID de la bústia >= 8.
		
		@; Calculem l'adreça de la bústia per enviar la dada.
		ldr r4, =_gd_mailboxes			@; Carreguem l'adreça base dels vectors de les bústies.
		mov r5, #MAILBOX_STRUCT_SIZE	@; Carreguem el tamany de cada posició del vector de bústies.
		mla r4, r0, r5, r4				@; Calculem l'adreça de la bústia n (n * Tamany de cada posició + Adreça base vectors)
		
		@; Llegim el comptador de dades (count) de la bústia per comprovar que no estigui plena.
		ldr r5, [r4, #72]				@; Carreguem el offset 72 (count) de la bústia.
		cmp r5, #MAILBOX_QUEUE_SIZE		@; Comparem el comptador amb el nombre màxim de dades.
		bhs .Lsend_error				@; Si el comptador >= 16, la bústia està plena, per tant tirem error.
		
		@; Afegim la dada a la cua.
		ldr r6, [r4, #68]				@; Carreguem a R6 el índex del final de la cua (tail).
		add r7, r4, r6, lsl #2			@; Calculem l'adreça del índex tail (Adreça del inici de la bústia + (índex tail * 4).
		str r1, [r7]					@; Guardem la dada en la posició.
		
		@; Actualitzem índex tail (tail++)
		add r6, r6, #1					@; Incrementem índex tail
		cmp r6, #MAILBOX_QUEUE_SIZE		@; Mirem si el índex tail és igual a 16.
		moveq r6, #0					@; Si tail == 16, posem tail = 0 (Round Robin)
		str r6, [r4, #68]				@; Tornem a guardar el índex tail en el vector de la bústia.
		
		@; Incrementem variable comptador de dades
		add r5, r5, #1					@; Incrementem el comptador.
		str r5, [r4, #72]				@; Guardem la variable comptador en el vector de la bústia.
		
		@; Retornem codi d'èxit per R0
		mov r0, #1						@; Codi èxit.
		b .Lsend_end					@; Saltem al final de la funció
		
		.Lsend_error:
			mov r0, #0					@; Codi d'error.
		
		.Lsend_end:
	pop {r4-r7, pc}
	
	
	.global _ga_receive
	@; Rutina per rebre una dada a través de la bústia indicada per paràmetre.
	@; Aquesta funció bloqueja el procés que la crida en cas de que la bústia indicada estigui buida.
	@; Un procés només es desbloquejarà en el moment que la bústia que ha demanat deixi d'estar buida.
	@; Paràmetres d'entrada:
	@; R0: n (ID bústia, 0-7)
	@; Retorna:
	@; R0: la dada rebuda de la bústia
_ga_receive:
	push {r4-r7, lr}
		@; Calculem l'adreça de la bústia
		ldr r4, =_gd_mailboxes			@; Carreguem l'adreça base dels vectors de les bústies.
		mov r5, #MAILBOX_STRUCT_SIZE	@; Carreguem el tamany de cada posició del vector de bústies.
		mla r4, r0, r5, r4				@; Calculem l'adreça de la bústia n (n * Tamany de cada posició + Adreça base vectors).
		
		@; Bucle de consulta del estat de la bústia
		.Lreceive_loop:
			@; Comprovar si està buida la bústia
			ldr r5, [r4, #72]			@; Carreguem la variable comptador de dades (count).
			cmp r5, #0					@; Mirem si el comptador == 0.
			beq .Lreceive_wait			@; Saltar al bucle d'espera (per bloquejar) si count == 0 (bústia buida).
			
			@; Treiem la dada de la cua
			ldr r6, [r4, #64]			@; Carreguem la variable del principi de la cua (head).
			add r7, r4, r6, lsl #2		@; Calculem l'adreça de la posició head (Adreça base de la bústia + (índex head * 4).
			ldr r0, [r7]				@; Carreguem a R0 la dada per retornar-la.
			
			@; Actualitzem índex head (head++)
			add r6, r6, #1				@; Incrementem índex head.
			cmp r6, #MAILBOX_QUEUE_SIZE	@; Mirem si el índex head és igual a 16
			moveq r6, #0				@; Si head == 16, posem head = 0 (Round Robin)
			str r6, [r4, #64]			@; Guardem el valor actualitzat del head.
			
			@; Decrementar count
			sub r5, r5, #1				@; Fem count--
			str r5, [r4, #72]			@; Guardar el nou valor del count.
			
			b .Lreceive_end				@; Hem rebut la dada, sortir
			
		@; La bústia està buida, esperar al següent VBlank (bloquejar el procés).	
		.Lreceive_wait:
			bl _gp_WaitForVBlank		@; Cedim CPU i esperar un 'tic'
			b .Lreceive_loop			@; Tornem a comprovar si la bústia és buida.
			
		.Lreceive_end:
	pop {r4-r7, pc}
			

	
.end

