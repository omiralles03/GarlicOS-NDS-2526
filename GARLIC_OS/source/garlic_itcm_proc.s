@;==============================================================================
@;
@;	"garlic_itcm_proc.s":	código de las funciones de control de procesos (1.0)
@;						(ver "garlic_system.h" para descripción de funciones)
@;
@;==============================================================================

.section .itcm,"ax",%progbits

	.arm
	.align 2
	
	.global _gp_WaitForVBlank
	@; rutina para pausar el procesador mientras no se produzca una interrupción
	@; de retrazado vertical (VBL); es un sustituto de la "swi #5", que evita
	@; la necesidad de cambiar a modo supervisor en los procesos GARLIC
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
	@; Manejador principal de interrupciones del sistema Garlic
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
		ldr r4, =_gd_pidz			@; Carreguem adreça de la variable PID i sòcol del procés actual
		ldr r4, [r4]				@; Carreguem el valor de la variable PIDZ
		cmp r4, #0					@; Si PIDZ = 0, és el sistema operatiu -> Salvem el seu estat.
		beq .LsalvarProces			
		mov r4, r4, lsr #4			@; Aillem els 28 bits alts del PID
		cmp r4, #0					@; Si el PID és 0, el procés ha acabat -> Restaurem el següent procés.
		beq .LrestaurarProces
		
		@; Crida a la funció de salvar l'estat del procés.
		.LsalvarProces:
		ldr r4, =_gd_nReady			@; Preparem els paràmetres per la crida a _gp_salvarProc
		ldr r5, [r4]
		ldr r6, = _gd_pidz
		bl _gp_salvarProc			@; Cridem la funció _gp_salvarProc
		str r5, [r4]				@; Guardem el valor actualitzat del nombre de processos a la cua Ready.
		
		@; Crida a la funció de restaurar l'estat del procés.
		.LrestaurarProces:
		ldr r4, =_gd_nReady			@; Preparem els paràmetres per la crida a _gp_restaurarProc
		ldr r5, [r4]
		ldr r6, = _gd_pidz
		bl _gp_restaurarProc		@; Cridem la funció _gp_restaurarProc
		
		
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
		mrs CPSR, r8				@; Tornem a guardar el CPSR amb el mode sistema actiu.
		
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
		mrs CPSR, r8				@; Guardem el CPSR per confirmar el canvi de mode.
		
	pop {r8-r11, pc}


	@; Rutina para restaurar el estado del siguiente proceso en la cola de READY
	@;Parámetros
	@; R4: dirección _gd_nReady
	@; R5: número de procesos en READY
	@; R6: dirección _gd_pidz
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
		mrs CPSR, r8				@; Guardem el nou CPSR en mode System.
		
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
		mrs CPSR, r8				@; Guardem el CPSR amb el nou mode.
	pop {r8-r11, pc}


	.global _gp_numProc
	
	
	@; Retorna el nombre total de processos en el sistema (Procés en Run + Processos en Ready)
	@; Resultado
	@; R0: número de procesos total
_gp_numProc:
	push {r1, lr}
		ldr r1, =_gd_nReady			@; Carreguem direcció de variable de nombre de processos en Ready.
		ldr r1, [r1]				@; Carreguem el valor de la variable.
		add r0, r1, #1				@; Retornem per R0 (Nombre de processos Ready + 1) per tenir en compte el procés en estat Run.
	pop {r1, pc}


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
	push {lr}


	pop {pc}


	@; Rutina para terminar un proceso de usuario:
	@; pone a 0 el campo PID del PCB del zócalo actual, para indicar que esa
	@; entrada del vector _gd_pcbs está libre; también pone a 0 el PID de la
	@; variable _gd_pidz (sin modificar el número de zócalo), para que el código
	@; de multiplexación de procesos no salve el estado del proceso terminado.
_gp_terminarProc:
	ldr r0, =_gd_pidz
	ldr r1, [r0]			@; R1 = valor actual de PID + zócalo
	and r1, r1, #0xf		@; R1 = zócalo del proceso desbancado
	str r1, [r0]			@; guardar zócalo con PID = 0, para no salvar estado			
	ldr r2, =_gd_pcbs
	mov r10, #24
	mul r11, r1, r10
	add r2, r11				@; R2 = dirección base _gd_pcbs[zocalo]
	mov r3, #0
	str r3, [r2]			@; pone a 0 el campo PID del PCB del proceso
.LterminarProc_inf:
	bl _gp_WaitForVBlank	@; pausar procesador
	b .LterminarProc_inf	@; hasta asegurar el cambio de contexto
	
.end

