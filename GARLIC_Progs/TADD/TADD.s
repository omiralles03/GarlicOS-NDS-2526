	.arch armv5te
	.eabi_attribute 23, 1
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"TADD.c"
	.section	.rodata
	.align	2
.LC0:
	.ascii	"-- Programa TADD - PID (%d) --\012\000"
	.align	2
.LC1:
	.ascii	"Prova GARLIC_malloc()\012\000"
	.align	2
.LC2:
	.ascii	"  Bloc %d (%d bytes) reservat a: %x\012\000"
	.align	2
.LC3:
	.ascii	"ERROR: No s'ha pogut reservar el bloc %d (%d bytes)"
	.ascii	"\012\000"
	.align	2
.LC4:
	.ascii	"Intent reservar 5\350 bloc\012\000"
	.align	2
.LC5:
	.ascii	"  OK: El 5\350 malloc ha retornat 0 com s'esperava."
	.ascii	"\012\000"
	.align	2
.LC6:
	.ascii	"  ERROR: El 5\350 malloc ha retornat un punter (%x)"
	.ascii	"! No hauria de poder.\012\000"
	.align	2
.LC7:
	.ascii	"Prova GARLIC_free() bloc 1 (%x)\012\000"
	.align	2
.LC8:
	.ascii	"OK: Bloc 1 alliberat correctament.\012\000"
	.align	2
.LC9:
	.ascii	"ERROR: GARLIC_free() ha fallat per al bloc 1.\012\000"
	.align	2
.LC10:
	.ascii	"INFO: Bloc 1 no estava reservat, no es pot allibera"
	.ascii	"r.\012\000"
	.align	2
.LC11:
	.ascii	"Intentant reservar un nou bloc (ara hauria de funci"
	.ascii	"onar)...\012\000"
	.align	2
.LC12:
	.ascii	"OK: Nou bloc reservat a: %x\012\000"
	.align	2
.LC13:
	.ascii	"ERROR: No s'ha pogut reservar el nou bloc despr\351"
	.ascii	"s de free.\012\000"
	.align	2
.LC14:
	.ascii	"Intentant alliberar punter inv\340lid (0x1234)...\012"
	.ascii	"\000"
	.align	2
.LC15:
	.ascii	"OK: GARLIC_free() ha retornat 0 per a punter inv\340"
	.ascii	"lid.\012\000"
	.align	2
.LC16:
	.ascii	"ERROR: GARLIC_free() no ha detectat un punter inv\340"
	.ascii	"lid.\012\000"
	.align	2
.LC17:
	.ascii	"Alliberar la resta de blocs\012\000"
	.align	2
.LC18:
	.ascii	"Bloc a %x alliberat.\012\000"
	.align	2
.LC19:
	.ascii	"ERROR alliberant bloc a %x.\012\000"
	.align	2
.LC20:
	.ascii	"-- Fi Programa TADD - PID (%d) --\012\000"
	.text
	.align	2
	.global	_start
	.syntax unified
	.arm
	.fpu softvfp
	.type	_start, %function
_start:
	@ args = 0, pretend = 0, frame = 48
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #52
	str	r0, [sp, #4]
	bl	GARLIC_pid
	str	r0, [sp, #40]
	ldr	r1, [sp, #40]
	ldr	r0, .L21
	bl	GARLIC_printf
	ldr	r0, .L21+4
	bl	GARLIC_printf
	mov	r3, #0
	str	r3, [sp, #44]
	b	.L2
.L5:
	ldr	r3, [sp, #44]
	add	r2, r3, #1
	mov	r3, r2
	lsl	r3, r3, #2
	add	r3, r3, r2
	lsl	r3, r3, #1
	str	r3, [sp, #36]
	ldr	r3, [sp, #36]
	lsl	r3, r3, #16
	lsr	r3, r3, #16
	mov	r0, r3
	bl	GARLIC_malloc
	mov	r2, r0
	ldr	r3, [sp, #44]
	lsl	r3, r3, #2
	add	r1, sp, #48
	add	r3, r1, r3
	str	r2, [r3, #-40]
	ldr	r3, [sp, #44]
	lsl	r3, r3, #2
	add	r2, sp, #48
	add	r3, r2, r3
	ldr	r3, [r3, #-40]
	cmp	r3, #0
	beq	.L3
	ldr	r3, [sp, #44]
	lsl	r3, r3, #2
	add	r2, sp, #48
	add	r3, r2, r3
	ldr	r3, [r3, #-40]
	ldr	r2, [sp, #36]
	ldr	r1, [sp, #44]
	ldr	r0, .L21+8
	bl	GARLIC_printf
	ldr	r3, [sp, #44]
	lsl	r3, r3, #2
	add	r2, sp, #48
	add	r3, r2, r3
	ldr	r3, [r3, #-40]
	ldr	r2, [sp, #44]
	and	r2, r2, #255
	add	r2, r2, #65
	and	r2, r2, #255
	strb	r2, [r3]
	b	.L4
.L3:
	ldr	r2, [sp, #36]
	ldr	r1, [sp, #44]
	ldr	r0, .L21+12
	bl	GARLIC_printf
.L4:
	ldr	r3, [sp, #44]
	add	r3, r3, #1
	str	r3, [sp, #44]
.L2:
	ldr	r3, [sp, #44]
	cmp	r3, #3
	ble	.L5
	ldr	r0, .L21+16
	bl	GARLIC_printf
	mov	r0, #50
	bl	GARLIC_malloc
	mov	r3, r0
	str	r3, [sp, #24]
	ldr	r3, [sp, #24]
	cmp	r3, #0
	bne	.L6
	ldr	r0, .L21+20
	bl	GARLIC_printf
	b	.L7
.L6:
	ldr	r3, [sp, #24]
	mov	r1, r3
	ldr	r0, .L21+24
	bl	GARLIC_printf
	ldr	r3, [sp, #24]
	mov	r0, r3
	bl	GARLIC_free
.L7:
	ldr	r3, [sp, #12]
	mov	r1, r3
	ldr	r0, .L21+28
	bl	GARLIC_printf
	ldr	r3, [sp, #12]
	cmp	r3, #0
	beq	.L8
	ldr	r3, [sp, #12]
	mov	r0, r3
	bl	GARLIC_free
	str	r0, [sp, #32]
	ldr	r3, [sp, #32]
	cmp	r3, #0
	beq	.L9
	ldr	r0, .L21+32
	bl	GARLIC_printf
	mov	r3, #0
	str	r3, [sp, #12]
	b	.L11
.L9:
	ldr	r0, .L21+36
	bl	GARLIC_printf
	b	.L11
.L8:
	ldr	r0, .L21+40
	bl	GARLIC_printf
.L11:
	ldr	r0, .L21+44
	bl	GARLIC_printf
	mov	r0, #15
	bl	GARLIC_malloc
	mov	r3, r0
	str	r3, [sp, #24]
	ldr	r3, [sp, #24]
	cmp	r3, #0
	beq	.L12
	ldr	r3, [sp, #24]
	mov	r1, r3
	ldr	r0, .L21+48
	bl	GARLIC_printf
	ldr	r3, [sp, #24]
	mov	r2, #90
	strb	r2, [r3]
	b	.L13
.L12:
	ldr	r0, .L21+52
	bl	GARLIC_printf
.L13:
	ldr	r0, .L21+56
	bl	GARLIC_printf
	ldr	r0, .L21+60
	bl	GARLIC_free
	str	r0, [sp, #28]
	ldr	r3, [sp, #28]
	cmp	r3, #0
	bne	.L14
	ldr	r0, .L21+64
	bl	GARLIC_printf
	b	.L15
.L14:
	ldr	r0, .L21+68
	bl	GARLIC_printf
.L15:
	ldr	r0, .L21+72
	bl	GARLIC_printf
	mov	r3, #0
	str	r3, [sp, #44]
	b	.L16
.L19:
	ldr	r3, [sp, #44]
	lsl	r3, r3, #2
	add	r2, sp, #48
	add	r3, r2, r3
	ldr	r3, [r3, #-40]
	cmp	r3, #0
	beq	.L17
	ldr	r3, [sp, #44]
	lsl	r3, r3, #2
	add	r2, sp, #48
	add	r3, r2, r3
	ldr	r3, [r3, #-40]
	mov	r0, r3
	bl	GARLIC_free
	mov	r3, r0
	cmp	r3, #0
	beq	.L18
	ldr	r3, [sp, #44]
	lsl	r3, r3, #2
	add	r2, sp, #48
	add	r3, r2, r3
	ldr	r3, [r3, #-40]
	mov	r1, r3
	ldr	r0, .L21+76
	bl	GARLIC_printf
	b	.L17
.L18:
	ldr	r3, [sp, #44]
	lsl	r3, r3, #2
	add	r2, sp, #48
	add	r3, r2, r3
	ldr	r3, [r3, #-40]
	mov	r1, r3
	ldr	r0, .L21+80
	bl	GARLIC_printf
.L17:
	ldr	r3, [sp, #44]
	add	r3, r3, #1
	str	r3, [sp, #44]
.L16:
	ldr	r3, [sp, #44]
	cmp	r3, #4
	ble	.L19
	ldr	r1, [sp, #40]
	ldr	r0, .L21+84
	bl	GARLIC_printf
	mov	r3, #0
	mov	r0, r3
	add	sp, sp, #52
	@ sp needed
	ldr	pc, [sp], #4
.L22:
	.align	2
.L21:
	.word	.LC0
	.word	.LC1
	.word	.LC2
	.word	.LC3
	.word	.LC4
	.word	.LC5
	.word	.LC6
	.word	.LC7
	.word	.LC8
	.word	.LC9
	.word	.LC10
	.word	.LC11
	.word	.LC12
	.word	.LC13
	.word	.LC14
	.word	4660
	.word	.LC15
	.word	.LC16
	.word	.LC17
	.word	.LC18
	.word	.LC19
	.word	.LC20
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
