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
	.ascii	"-- Programa DNIF  -  PID (%d) --\012\000"
	.align	2
.LC1:
	.ascii	"TRWAGMYFPDXBNJZSQVHLCKE\000"
	.align	2
.LC2:
	.ascii	"\012NIE: %c-%d\000"
	.align	2
.LC3:
	.ascii	"%c\012\012\000"
	.align	2
.LC4:
	.ascii	"\012DNI: %d-%c\012\012\000"
	.text
	.align	2
	.global	dnif
	.syntax unified
	.arm
	.fpu softvfp
	.type	dnif, %function
dnif:
	@ args = 0, pretend = 0, frame = 40
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #44
	str	r0, [sp, #4]
	bl	GARLIC_pid
	mov	r3, r0
	mov	r1, r3
	ldr	r0, .L14
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
	ldr	r3, .L14+4
	str	r3, [sp, #28]
	ldr	r3, [sp, #4]
	cmp	r3, #0
	beq	.L6
	mov	r1, #0
	mov	r0, #3
	bl	random_inRange
	mov	r3, r0
	strh	r3, [sp, #34]	@ movhi
	ldr	r1, .L14+8
	ldr	r0, .L14+12
	bl	random_inRange
	str	r0, [sp, #24]
	ldrsh	r3, [sp, #34]
	ldr	r2, .L14+16
	mul	r3, r2, r3
	mov	r2, r3
	ldr	r3, [sp, #24]
	add	r3, r2, r3
	str	r3, [sp, #36]
	b	.L7
.L6:
	ldr	r1, .L14+16
	ldr	r0, .L14+20
	bl	random_inRange
	str	r0, [sp, #36]
.L7:
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
	ldr	r3, [sp, #4]
	cmp	r3, #0
	beq	.L8
	ldrsh	r3, [sp, #34]
	cmp	r3, #0
	bne	.L9
	mov	r3, #88
	strh	r3, [sp, #32]	@ movhi
.L9:
	ldrsh	r3, [sp, #34]
	cmp	r3, #1
	bne	.L10
	mov	r3, #89
	strh	r3, [sp, #32]	@ movhi
	b	.L11
.L10:
	mov	r3, #90
	strh	r3, [sp, #32]	@ movhi
.L11:
	ldrsh	r3, [sp, #32]
	ldr	r2, [sp, #36]
	mov	r1, r3
	ldr	r0, .L14+24
	bl	GARLIC_printf
	ldrb	r3, [sp, #23]	@ zero_extendqisi2
	mov	r1, r3
	ldr	r0, .L14+28
	bl	GARLIC_printf
	b	.L12
.L8:
	ldrb	r3, [sp, #23]	@ zero_extendqisi2
	mov	r2, r3
	ldr	r1, [sp, #36]
	ldr	r0, .L14+32
	bl	GARLIC_printf
.L12:
	ldrb	r3, [sp, #23]	@ zero_extendqisi2
	mov	r0, r3
	add	sp, sp, #44
	@ sp needed
	ldr	pc, [sp], #4
.L15:
	.align	2
.L14:
	.word	.LC0
	.word	.LC1
	.word	1000000
	.word	9000000
	.word	10000000
	.word	90000000
	.word	.LC2
	.word	.LC3
	.word	.LC4
	.size	dnif, .-dnif
	.ident	"GCC: (devkitARM release 46) 6.3.0"
