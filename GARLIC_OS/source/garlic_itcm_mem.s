@;==============================================================================
@;
@;	"garlic_itcm_mem.s":	código de rutinas de soporte a la carga de
@;							programas en memoria (version 2.0)
@;
@;==============================================================================

NUM_FRANJAS = 768
INI_MEM_PROC = 0x01002000

.section .dtcm,"wa",%progbits
	.align 2

	.global _gm_zocMem
_gm_zocMem:	.space NUM_FRANJAS			@; vector de ocupaci�n de franjas mem.


.section .itcm,"ax",%progbits

	.arm
	.align 2


	.global _gm_reubicar
	@; rutina de soporte a _gm_cargarPrograma(), que interpreta los 'relocs'
	@; de un fichero ELF, contenido en un buffer *fileBuf, y ajustar las
	@; direcciones de memoria correspondientes a las referencias de tipo
	@; R_ARM_ABS32, a partir de las direcciones de memoria destino de código
	@; (dest_code) y datos (dest_data), y según el valor de las direcciones de
	@; las referencias a reubicar y de las direcciones de inicio de los
	@; segmentos de código (pAddr_code) y datos (pAddr_data)
	@;Parámetros:
	@; R0: dirección inicial del buffer de fichero (char *fileBuf)
	@; R1: dirección de inicio de segmento de código (unsigned int pAddr_code)
	@; R2: dirección de destino en la memoria (unsigned int *dest_code)
	@; R3: dirección de inicio de segmento de datos (unsigned int pAddr_data)
	@; (pila): dirección de destino en la memoria (unsigned int *dest_data)
	@;Resultado:
	@; cambio de las direcciones de memoria que se tienen que ajustar
_gm_reubicar:
	push {r4-r11, lr}
	
	ldr r4,  [sp, #36]	@; recuperacion "r5" de la pila
	
	@; calculo offsets code y data
	sub r5, r2, r1		
	sub r6, r4, r3

	mov r4, r0
	
	@; buscar la taula de seccions del .elf
    ldr r7, [r4, #32]	@; e_shoff
    add r7, r4, r7
    ldrh r8, [r4, #48]	@; e_shnum
    ldrh r9, [r4, #46]	@; e_shentsize

.Lbucle_seccions:
	cmp r8, #0
    beq .Lfi_reubicacio

    ldr r0, [r7, #4]	@; sh_type
    cmp r0, #9          @; seccio de reubicació (SHT_REL) ==? 9
    bne .Lnext_seccio

    ldr r10, [r7, #16]	@;sh_offset
    add r10, r4, r10
    ldr r11, [r7, #20]	@;sh_size
    add r11, r1, r11	
	
.Lbucle_reubicadors:
	cmp r10, r11
    bge .Lnext_seccio

    ldr r0, [r10], #4    @; r_offset
    ldr r1, [r10], #4    @; r_info (tipo de reubicación)

    and r1, r1, #0xFF
    cmp r1, #2           @; tipus R_ARM_ABS32 ? 
    bne .Lbucle_reubicadors

    @; correccio de l'adreça
    add r0, r0, r5       @; adreça real a modificar = (r_offset + code offset)
    ldr r1, [r0]        
	
	@;decisio offset aplicable 
	cmp r3, #0			@; existeix segment dades?
	beq .Lreub_code
	cmp r1, r3			@; valor apunta a zona de dades?
	blo .Lreub_code
	
@;aplica offset data
.Lreub_data:
	add r1, r1, r6
	b .Lreub_store

@;aplica offset codi	
.Lreub_code:
	add r1, r1, r5

.Lreub_store:
	str r1, [r0]
	b .Lbucle_reubicadors

.Lnext_seccio:
	add r7, r7, r9          @;next SH entry
    sub r8, r8, #1
    b .Lbucle_seccions
	
.Lfi_reubicacio:
	pop {r4-r11, pc}

.global _gm_reservarMem
	@; Rutina para reservar un conjunto de franjas de memoria libres
	@; consecutivas que proporcionen un espacio suficiente para albergar
	@; el tama�o de un segmento de c�digo o datos del proceso (seg�n indique
	@; tipo_seg), asignado al n�mero de z�calo que se pasa por par�metro;
	@; tambi�n se encargar� de invocar a la rutina _gm_pintarFranjas(), para
	@; representar gr�ficamente la ocupaci�n de la memoria de procesos;
	@; la rutina devuelve la primera direcci�n del espacio reservado; 
	@; en el caso de que no quede un espacio de memoria consecutivo del
	@; tama�o requerido, devuelve cero.
	@;Par�metros
	@;	R0: el n�mero de z�calo que reserva la memoria
	@;	R1: el tama�o en bytes que se quiere reservar
	@;	R2: el tipo de segmento reservado (0 -> c�digo, 1 -> datos)
	@;Resultado
	@;	R0: direcci�n inicial de memoria reservada (0 si no es posible)
_gm_reservarMem:
	push {r4- r9, lr}

	@;calcul franges -> num_franges (sencer cap adalt) = (r1 + 31) / 32
	add r4, r1, #31
	mov r4, r4, lsr #5
	
	ldr r5, =_gm_zocMem
	mov r6, #0			@; i, index actual 
	mov r7, #0			@; comptador de franges consecutives lliures
	
.Lbuscar_franges:
	cmp r6, #NUM_FRANJAS
	bge .Lerror_reserva
	
	ldrb r8, [r5, r6]           
    cmp r8, #0                  @; zócalo franja i =? lliure
    beq .Lfranja_lliure
    
    mov r7, #0                  
    add r6, #1					@;i+=1, buscar següent
    b .Lbuscar_franges
	
.Lfranja_lliure:
	add r7, #1
    cmp r7, r4                  @;suficients franjes consecutives?
    beq .Ltrobat
    add r6, #1
    b .Lbuscar_franges

.Ltrobat:
	@;calcul index inicial lliure = index final trobat - franges necessaries + 1
	sub r9, r6, r4
	add r9, #1
	
	mov r1, #0					@; comptador

.Lloop_marcar:
	strb r0, [r5, r9]			@; _gm_zocMem[pos] = num_zocalo 
	add r9, #1
	add r1, #1
	cmp r1, r4
	blt .Lloop_marcar
	
	@; restaurar index_ini_lliure
	sub r9, r9, r4
	
	@;pintar pantalla inferior
	@;_gs_pintarFranjas(zocalo, index_ini, num_franjas, tipo_seg)
	push {r0-r3}
	mov r3, r2
	mov r1, r9
	mov r2, r4
	
	bl _gs_pintarFranjas
	pop {r0-r3}
	
	@;calculo dir. retorno = INI_MEM_PROC + (index_ini * 32)
	@; asegurant adreçes multiples de 4 per cada segment 
	ldr r0, =INI_MEM_PROC
	add r0, r0, r9, lsl #5
	pop {r4-r9, pc}

.Lerror_reserva:
	mov r0, #0
	pop {r4-r9, pc}
	


	.global _gm_liberarMem
	@; Rutina para liberar todas las franjas de memoria asignadas al proceso
	@; del z�calo indicado por par�metro; tambi�n se encargar� de invocar a la
	@; rutina _gm_pintarFranjas(), para actualizar la representaci�n gr�fica
	@; de la ocupaci�n de la memoria de procesos.
	@;Par�metros
	@;	R0: el n�mero de z�calo que libera la memoria
_gm_liberarMem:
	push {r4-r8, lr}
	mov r4, r0
	ldr r5, =_gm_zocMem
	mov r6, #0					@;index

.Lfree_loop:
	cmp r6, #NUM_FRANJAS
	bge .Lfree_end
	
	ldrb r7, [r5, r6]
	cmp r7, r4					@;_gm_zocMem[i] pertany a zocalo?
	bne .Lfree_next
	@;sino, lliberar franja
	mov r8, #0
	strb r8, [r5, r6]
	
	@;pintar pantalla inferior
	@;_gs_pintarFranjas(zocalo, index_ini, num_franjas, tipo_seg)
	push {r0-r3}
	mov r0, #0					@;0 per borrar
	mov r1, r6
	mov r2, #1					@;vaig pintant segons trobo caselles
	mov r3, #0					@;indiferent
	bl _gs_pintarFranjas
	pop {r0-r3}
	
	
.Lfree_next:
	add r6, #1
	b .Lfree_loop
	
.Lfree_end:
	pop {r4-r8, pc}



	.global _gm_rsiTIMER1
	@; Rutina de Servicio de Interrupci�n (RSI) para actualizar la representa-
	@; ci�n de la pila y el estado de los procesos activos.
_gm_rsiTIMER1:
	push {r0-r10, lr}
	bl _gs_representarPilas		@;pintar columna Pi
	
	mov r4, #0					@;index pel numero de zocalo 
.Lloop_state:
	cmp r4, #16
	bge .Lrsi_end
	
	ldr r5, =_gd_pcbs			@; vector procs. actius
	@;calcular offset = index zocal * 24 (mida pcb -> 16 zocalos, 6 camps, 4B cada camp)
	mov r0, #24
	mla r5, r4, r0, r5			@;PCB zocalo-i (z*24 + base)
	ldr r6, [r5]				@;PID
	
	@;PROBLEMA: al començar en 0 es borrara i mai escriura res
	@;al proc de control (zocalo 0)
	cmp r4, #0
	beq .Lexcepcio_zocalo
	cmp r6, #0
	beq .Lborrar_state
	
.Lexcepcio_zocalo:
	@;busqueda valor estat
	ldr r7, =_gd_pidz			@;PID+zocalo
	ldr r7, [r7]
	and r7, r7, #0xF			@;mascara para numero de zocalo (2^4 = 16 ventanas)
	cmp r7, r4
	beq .Lstate_R
	
	ldr r8, =_gd_nDelay			@;num procs. en blocked
	cmp r8, #0
	beq .Lstate_Y				@;si no hay, proceso es ready
	
	ldr r9, =_gd_qDelay			@;cua procs. retardats
	mov r10, #0					@;index cua

.Lbusqueda_delay:
	ldr r0, [r9, r10, lsl #2]	@;word 32 bits
	mov r0, r0, lsr #24
	cmp r0, r4
	beq .Lstate_B
	add r10, #1
	cmp r10, r8
	blt .Lbusqueda_delay
	
.Lstate_Y:
	ldr r0, =.Lstr_Y
	mov r3, #0					@;color blanc (0)
	b .Lescriure_lletra
	
.Lstate_B:
	ldr r0, =.Lstr_B
	mov r3, #0
	b .Lescriure_lletra
 
.Lstate_R:
	ldr r0, =.Lstr_R
	mov r3, #1					@;color blau (1)
	b .Lescriure_lletra

.Lborrar_state:
	ldr r0, =.Lstr_Empty
	mov r3, #0
	
.Lescriure_lletra:
	@;_gs_escribirStringSub(char *s, int fil, int col, int color)
	add r1, r4, #4				@;primera fila = 4
	mov r2, #26					@; columna E = 26
	bl _gs_escribirStringSub
	
	add r4, #1
	b .Lloop_state
	
.Lrsi_end:
	pop {r0-r10, pc}
	
.section .rodata
	.align 2
	.Lstr_R:     .asciz "R"
	.Lstr_Y:     .asciz "Y"
	.Lstr_B:     .asciz "B"
	.Lstr_Empty: .asciz " "
	
	
	.global _gm_pintarFranjas
	
	@; Rutina adicional del progM permet distingir les franges
	@; dels processos d'usuari que estan ocupades per memoria dinamica
	@; mitjançant les funcions _gm_do_malloc per reservar 
	@; & _gm_do_free per lliberar, ambdues tambe modificades.
	@; Parametres:
	@; r0 = zocalo
	@; r1 = index_ini
	@; r2 = n_franjes
	@; r3 = tipus franja - 0: franja normal; 1: franja invertida
	
	@;_gs_pintarFranjas(zocalo, index_ini, num_franjas, tipo_seg)
	@;96 -> gris en _gs_pintarFranja -> _gs_colZoc
_gm_pintarFranjas:
	@;push { , lr}
	@;pop { , pc}
	
.end

