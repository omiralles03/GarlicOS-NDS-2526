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
	.ascii	"DNI: %d-%c\012\000"
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
	bl	GARLIC_pid
	mov	r3, r0
	mov	r1, r3
	ldr	r0, .L11
	bl	GARLIC_printf
	ldr	r3, [sp, #4]
	cmp	r3, #0
	bne	.L4
	ldr	r3, [sp, #4]
	cmp	r3, #1
	beq	.L5
.L4:
	mov	r3, #0
	str	r3, [sp, #4]
.L5:
	ldr	r3, .L11+4
	str	r3, [sp, #28]
	ldr	r3, [sp, #4]
	cmp	r3, #0
	beq	.L6
	mov	r1, #0
	mov	r0, #3
	bl	random_inRange
	str	r0, [sp, #24]
	ldr	r1, .L11+8
	ldr	r0, .L11+12
	bl	random_inRange
	str	r0, [sp, #20]
	ldr	r3, [sp, #24]
	ldr	r2, .L11+16
	mul	r2, r3, r2
	ldr	r3, [sp, #20]
	add	r3, r2, r3
	str	r3, [sp, #36]
	b	.L7
.L6:
	ldr	r1, .L11+16
	ldr	r0, .L11+20
	bl	random_inRange
	str	r0, [sp, #36]
.L7:
	add	r3, sp, #12
	add	r2, sp, #8
	mov	r1, #23
	ldr	r0, [sp, #36]
	bl	GARLIC_divmod
	ldr	r3, [sp, #12]
	ldr	r2, [sp, #28]
	add	r3, r2, r3
	ldrb	r3, [r3]
	strb	r3, [sp, #19]
	mov	r3, #0
	str	r3, [sp, #32]
	b	.L8
.L9:
	ldrb	r3, [sp, #19]	@ zero_extendqisi2
	mov	r2, r3
	ldr	r1, [sp, #36]
	ldr	r0, .L11+24
	bl	GARLIC_printf
	ldr	r3, [sp, #32]
	add	r3, r3, #1
	str	r3, [sp, #32]
.L8:
	ldr	r3, [sp, #32]
	cmp	r3, #29
	ble	.L9
	ldrb	r3, [sp, #19]	@ zero_extendqisi2
	mov	r0, r3
	add	sp, sp, #44
	@ sp needed
	ldr	pc, [sp], #4
.L12:
	.align	2
.L11:
	.word	.LC0
	.word	.LC1
	.word	1000000
	.word	9000000
	.word	10000000
	.word	90000000
	.word	.LC2
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
