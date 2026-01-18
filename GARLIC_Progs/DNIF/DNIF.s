	.arch armv5te
	.eabi_attribute 23, 1
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"DNIF.c"
	.text
	.align	2
	.global	random_inRange
	.syntax unified
	.arm
	.fpu softvfp
	.type	random_inRange, %function
random_inRange:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #20
	str	r0, [sp, #4]
	str	r1, [sp]
	bl	GARLIC_random
	mov	r3, r0
	mov	r0, r3
	add	r3, sp, #12
	add	r2, sp, #8
	ldr	r1, [sp, #4]
	bl	GARLIC_divmod
	ldr	r2, [sp, #12]
	ldr	r3, [sp]
	add	r3, r2, r3
	mov	r0, r3
	add	sp, sp, #20
	@ sp needed
	ldr	pc, [sp], #4
	.size	random_inRange, .-random_inRange
	.section	.rodata
	.align	2
.LC0:
	.ascii	"%0-- Programa DNIF  -  PID (%d) --\012\000"
	.align	2
.LC1:
	.ascii	"DNI\000"
	.align	2
.LC2:
	.ascii	"NIE\000"
	.align	2
.LC3:
	.ascii	"\012%0Argument rebut: %2%d %0(%3%s%0)\012\000"
	.align	2
.LC4:
	.ascii	"TRWAGMYFPDXBNJZSQVHLCKE\000"
	.align	2
.LC5:
	.ascii	"\012%0Random Digit NIE: %2%d\012\000"
	.align	2
.LC6:
	.ascii	"%0Random Generat: %2%d\012\000"
	.align	2
.LC7:
	.ascii	"%0Numero NIE: %2%d\012\000"
	.align	2
.LC8:
	.ascii	"\012%0Random DNI Generat: %2%d\012\000"
	.align	2
.LC9:
	.ascii	"%0Residu (%1%d%0 %% %123%0) = %2%d\012\000"
	.align	2
.LC10:
	.ascii	"%0Lletres[%1%s%0]\012\000"
	.align	2
.LC11:
	.ascii	"%0Lletra DNI: Lletres[%1%d%0] = %2%c\012\000"
	.align	2
.LC12:
	.ascii	"%0digitoNIE[X=0, Y=1, Z>1]: %2%d\012\000"
	.align	2
.LC13:
	.ascii	"\012%0NIE resultant: %2%c-%d\000"
	.align	2
.LC14:
	.ascii	"%c\012\012\000"
	.align	2
.LC15:
	.ascii	"\012%0DNI resultant: %2%d\000"
	.align	2
.LC16:
	.ascii	"-%c\012\012\000"
	.text
	.align	2
	.global	_start
	.syntax unified
	.arm
	.fpu softvfp
	.type	_start, %function
_start:
	@ args = 0, pretend = 0, frame = 40
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #44
	str	r0, [sp, #4]
	ldr	r0, .L16
	bl	GARLIC_printf
	ldr	r3, [sp, #4]
	cmp	r3, #1
	bgt	.L4
	ldr	r3, [sp, #4]
	cmp	r3, #0
	bge	.L5
.L4:
	mov	r3, #0
	str	r3, [sp, #4]
.L5:
	ldr	r3, [sp, #4]
	cmp	r3, #0
	bne	.L6
	ldr	r3, .L16+4
	b	.L7
.L6:
	ldr	r3, .L16+8
.L7:
	mov	r2, r3
	ldr	r1, [sp, #4]
	ldr	r0, .L16+12
	bl	GARLIC_printf
	ldr	r3, .L16+16
	str	r3, [sp, #28]
	ldr	r3, [sp, #4]
	cmp	r3, #0
	beq	.L8
	mov	r1, #0
	mov	r0, #3
	bl	random_inRange
	mov	r3, r0
	strh	r3, [sp, #34]	@ movhi
	ldr	r1, .L16+20
	ldr	r0, .L16+24
	bl	random_inRange
	str	r0, [sp, #24]
	ldrsh	r3, [sp, #34]
	ldr	r2, .L16+28
	mul	r3, r2, r3
	mov	r2, r3
	ldr	r3, [sp, #24]
	add	r3, r2, r3
	str	r3, [sp, #36]
	ldrsh	r3, [sp, #34]
	mov	r1, r3
	ldr	r0, .L16+32
	bl	GARLIC_printf
	ldr	r1, [sp, #24]
	ldr	r0, .L16+36
	bl	GARLIC_printf
	ldr	r1, [sp, #36]
	ldr	r0, .L16+40
	bl	GARLIC_printf
	b	.L9
.L8:
	ldr	r1, .L16+28
	ldr	r0, .L16+44
	bl	random_inRange
	str	r0, [sp, #36]
	ldr	r1, [sp, #36]
	ldr	r0, .L16+48
	bl	GARLIC_printf
.L9:
	add	r3, sp, #16
	add	r2, sp, #12
	mov	r1, #23
	ldr	r0, [sp, #36]
	bl	GARLIC_divmod
	ldr	r3, [sp, #16]
	ldr	r2, [sp, #28]
	add	r3, r2, r3
	ldrb	r3, [r3]
	strb	r3, [sp, #23]
	ldr	r3, [sp, #16]
	mov	r2, r3
	ldr	r1, [sp, #36]
	ldr	r0, .L16+52
	bl	GARLIC_printf
	ldr	r1, [sp, #28]
	ldr	r0, .L16+56
	bl	GARLIC_printf
	ldr	r3, [sp, #16]
	ldrb	r2, [sp, #23]	@ zero_extendqisi2
	mov	r1, r3
	ldr	r0, .L16+60
	bl	GARLIC_printf
	ldr	r3, [sp, #4]
	cmp	r3, #0
	ble	.L10
	ldrsh	r3, [sp, #34]
	cmp	r3, #0
	bne	.L11
	mov	r3, #88
	strh	r3, [sp, #32]	@ movhi
.L11:
	ldrsh	r3, [sp, #34]
	cmp	r3, #1
	bne	.L12
	mov	r3, #89
	strh	r3, [sp, #32]	@ movhi
	b	.L13
.L12:
	mov	r3, #90
	strh	r3, [sp, #32]	@ movhi
.L13:
	ldrsh	r3, [sp, #34]
	mov	r1, r3
	ldr	r0, .L16+64
	bl	GARLIC_printf
	ldrsh	r3, [sp, #32]
	ldr	r2, [sp, #36]
	mov	r1, r3
	ldr	r0, .L16+68
	bl	GARLIC_printf
	ldrb	r3, [sp, #23]	@ zero_extendqisi2
	mov	r1, r3
	ldr	r0, .L16+72
	bl	GARLIC_printf
	b	.L14
.L10:
	ldr	r1, [sp, #36]
	ldr	r0, .L16+76
	bl	GARLIC_printf
	ldrb	r3, [sp, #23]	@ zero_extendqisi2
	mov	r1, r3
	ldr	r0, .L16+80
	bl	GARLIC_printf
.L14:
	ldrb	r3, [sp, #23]	@ zero_extendqisi2
	mov	r0, r3
	add	sp, sp, #44
	@ sp needed
	ldr	pc, [sp], #4
.L17:
	.align	2
.L16:
	.word	.LC0
	.word	.LC1
	.word	.LC2
	.word	.LC3
	.word	.LC4
	.word	1000000
	.word	9000000
	.word	10000000
	.word	.LC5
	.word	.LC6
	.word	.LC7
	.word	90000000
	.word	.LC8
	.word	.LC9
	.word	.LC10
	.word	.LC11
	.word	.LC12
	.word	.LC13
	.word	.LC14
	.word	.LC15
	.word	.LC16
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
