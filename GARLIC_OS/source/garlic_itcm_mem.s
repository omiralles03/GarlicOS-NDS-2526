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
	push {lr}


	pop {pc}



	.global _gm_liberarMem
	@; Rutina para liberar todas las franjas de memoria asignadas al proceso
	@; del z�calo indicado por par�metro; tambi�n se encargar� de invocar a la
	@; rutina _gm_pintarFranjas(), para actualizar la representaci�n gr�fica
	@; de la ocupaci�n de la memoria de procesos.
	@;Par�metros
	@;	R0: el n�mero de z�calo que libera la memoria
_gm_liberarMem:
	push {lr}


	pop {pc}



	.global _gm_rsiTIMER1
	@; Rutina de Servicio de Interrupci�n (RSI) para actualizar la representa-
	@; ci�n de la pila y el estado de los procesos activos.
_gm_rsiTIMER1:
	push {lr}


	pop {pc}
	
.end

