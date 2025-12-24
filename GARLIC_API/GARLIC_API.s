@;==============================================================================
@;
@;	"GARLIC_API.s":	implementación de funciones del API del sistema operativo
@;					GARLIC 2.0 (descripción de funciones en "GARLIC_API.h")
@;
@;==============================================================================

.text
	.arm
	.align 2

@;==============================================================================
@;	GARLIC
@;==============================================================================
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

	.global GARLIC_printchar
GARLIC_printchar:
	push {r4, lr}
	mov r4, #0
	mov lr, pc
	ldr pc, [r4, #20]		@; llamada indirecta a rutina 0x05
	pop {r4, pc}

	.global GARLIC_printmat
GARLIC_printmat:
	push {r4, lr}
	mov r4, #0
	mov lr, pc
	ldr pc, [r4, #24]		@; llamada indirecta a rutina 0x06
	pop {r4, pc}

	.global GARLIC_delay
GARLIC_delay:
	push {r4, lr}
	mov r4, #0
	mov lr, pc
	ldr pc, [r4, #28]		@; llamada indirecta a rutina 0x07
	pop {r4, pc}

	.global GARLIC_clear
GARLIC_clear:
	push {r4, lr}
	mov r4, #0
	mov lr, pc
	ldr pc, [r4, #32]		@; llamada indirecta a rutina 0x08
	pop {r4, pc}		

@;==============================================================================
@;	ProgG
@;==============================================================================
    .global GARLIC_spriteSet
GARLIC_spriteSet:
    push {r4, lr}
    mov r4, #0
    mov lr, pc
    ldr pc, [r4, #36]       @; llamada indirecta a rutina 0x09 (_ga_spriteSet)
    pop {r4, pc}

    .global GARLIC_spriteMove
GARLIC_spriteMove:
    push {r4, lr}
    mov r4, #0
    mov lr, pc
    ldr pc, [r4, #40]       @; llamada indirecta a rutina 0xA (_ga_spriteMove)
    pop {r4, pc}

    .global GARLIC_spriteShow
GARLIC_spriteShow:
    push {r4, lr}
    mov r4, #0
    mov lr, pc
    ldr pc, [r4, #44]       @; llamada indirecta a rutina 0xB (_ga_spriteShow)
    pop {r4, pc}

    .global GARLIC_spriteHide
GARLIC_spriteHide:
    push {r4, lr}
    mov r4, #0
    mov lr, pc
    ldr pc, [r4, #48]       @; llamada indirecta a rutina 0xC (_ga_spriteHide)
    pop {r4, pc}

    .global GARLIC_clearScreen
GARLIC_clearScreen:
    push {r4, lr}
    mov r4, #0
    mov lr, pc
    ldr pc, [r4, #52]       @; llamada indirecta a rutina 0xD (_ga_clearScreen)
    pop {r4, pc}

@;==============================================================================
@;	ProgP
@;==============================================================================
	.global GARLIC_send
GARLIC_send:
	push {r4, lr}
	mov r4, #0
	mov lr, pc
	ldr pc, [r4, #56]		@; Cridem indirectament a la rutina 0xE de la API
	pop {r4, pc}
	
	.global GARLIC_receive
GARLIC_receive:
	push {r4, lr}
	mov r4, #0
	mov lr, pc
	ldr pc, [r4, #60]		@; Cridem indirectament a la rutina 0xF de la API
	pop {r4, pc}

@;==============================================================================
@;	ProgM
@;==============================================================================
	.global GARLIC_malloc
GARLIC_malloc:
	push {r4, lr}
	mov r4, #0
	mov lr, pc
	ldr pc, [r4, #64]		@; llamada indirecta a rutina 0x10
	pop {r4, pc}

	.global GARLIC_free
GARLIC_free:
	push {r4, lr}
	mov r4, #0
	mov lr, pc
	ldr pc, [r4, #68] 		@; llamada indirecta a rutina 0x11
	pop {r4, pc}
	
.end
