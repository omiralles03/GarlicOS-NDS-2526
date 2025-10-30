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

@; Llamadas progG
    .global GARLIC_spriteSet
GARLIC_spriteSet:
    push {r4, lr}
    mov r4, #0
    mov lr, pc
    ldr pc, [r4, #20]       @; llamada indirecta a rutina 0x05 (_ga_spriteSet)
    pop {r4, pc}

    .global GARLIC_spriteMove
GARLIC_spriteMove:
    push {r4, lr}
    mov r4, #0
    mov lr, pc
    ldr pc, [r4, #24]       @; llamada indirecta a rutina 0x06 (_ga_spriteMove)
    pop {r4, pc}

    .global GARLIC_spriteShow
GARLIC_spriteShow:
    push {r4, lr}
    mov r4, #0
    mov lr, pc
    ldr pc, [r4, #28]       @; llamada indirecta a rutina 0x07 (_ga_spriteShow)
    pop {r4, pc}

    .global GARLIC_spriteHide
GARLIC_spriteHide:
    push {r4, lr}
    mov r4, #0
    mov lr, pc
    ldr pc, [r4, #32]       @; llamada indirecta a rutina 0x08 (_ga_spriteHide)
    pop {r4, pc}

    .global GARLIC_clearScreen
GARLIC_clearScreen:
    push {r4, lr}
    mov r4, #0
    mov lr, pc
    ldr pc, [r4, #36]       @; llamada indirecta a rutina 0x09 (_ga_clearScreen)
    pop {r4, pc}

.end
