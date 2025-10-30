@;==============================================================================
@;
@;	"GARLIC_API.s":	implementación de funciones del API del sistema operativo
@;					GARLIC 1.0 (descripción de funciones en "GARLIC_API.h")
@;
@;==============================================================================

.text
	.arm
	.align 2

	.global GARLIC_pid
GARLIC_pid:
	push {r4, lr}
	mov r4, #0				@; vector base de rutinas API de GARLIC
	mov lr, pc				@; guardar dirección de retorno
	ldr pc, [r4]			@; llamada indirecta a rutina 0x00
	pop {r4, pc}

	.global GARLIC_random
GARLIC_random:
	push {r4, lr}
	mov r4, #0
	mov lr, pc
	ldr pc, [r4, #4]		@; llamada indirecta a rutina 0x01
	pop {r4, pc}

	.global GARLIC_divmod
GARLIC_divmod:
	push {r4, lr}
	mov r4, #0
	mov lr, pc
	ldr pc, [r4, #8]		@; llamada indirecta a rutina 0x02
	pop {r4, pc}

	.global GARLIC_divmodL
GARLIC_divmodL:
	push {r4, lr}
	mov r4, #0
	mov lr, pc
	ldr pc, [r4, #12]		@; llamada indirecta a rutina 0x03
	pop {r4, pc}

	.global GARLIC_printf
GARLIC_printf:
	push {r4, lr}
	mov r4, #0
	mov lr, pc
	ldr pc, [r4, #16]		@; llamada indirecta a rutina 0x04
	pop {r4, pc}
	
	.global GARLIC_send
GARLIC_send:
	push {r4, lr}
		mov r4, #0
		mov lr, pc
		ldr pc, [r4, #20]	@; Cridem indirectament a la rutina 5 de la API (0x05)
	pop {r4, pc}
	
	.global GARLIC_receive
GARLIC_receive:
	push {r4, lr}
		mov r4, #0
		mov lr, pc
		ldr pc, [r4, #24]	@; Cridem indirectament a la rutina 6 de la API (0x06)
	pop {r4, pc}
		

.end
