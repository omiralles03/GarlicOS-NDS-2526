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
	.ascii	"TEST INICIO PROVANT MEMORIA DINAMICA\012\000"
	.align	2
.LC1:
	.ascii	"- P1 en %x\012\000"
	.align	2
.LC2:
	.ascii	"- P2 en %x\012\000"
	.align	2
.LC3:
	.ascii	"TEST FIN\012\000"
	.text
	.align	2
	.global	_start
	.syntax unified
	.arm
	.fpu softvfp
	.type	_start, %function
_start:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #20
	str	r0, [sp, #4]
	mov	r3, #2
	mov	r2, #0
	mov	r1, #0
	ldr	r0, .L5
	bl	GARLIC_printf
	mov	r0, #64
	bl	GARLIC_malloc
	str	r0, [sp, #12]
	ldr	r3, [sp, #12]
	cmp	r3, #0
	beq	.L2
	mov	r3, #2
	mov	r2, #0
	ldr	r1, [sp, #12]
	ldr	r0, .L5+4
	bl	GARLIC_printf
.L2:
	mov	r0, #2
	bl	GARLIC_delay
	mov	r0, #32
	bl	GARLIC_malloc
	str	r0, [sp, #8]
	ldr	r3, [sp, #8]
	cmp	r3, #0
	beq	.L3
	ldr	r1, [sp, #8]
	ldr	r0, .L5+8
	bl	GARLIC_printf
.L3:
	mov	r0, #4
	bl	GARLIC_delay
	ldr	r0, [sp, #12]
	bl	GARLIC_free
	ldr	r0, [sp, #8]
	bl	GARLIC_free
	mov	r3, #2
	mov	r2, #0
	mov	r1, #0
	ldr	r0, .L5+12
	bl	GARLIC_printf
	mov	r3, #0
	mov	r0, r3
	add	sp, sp, #20
	@ sp needed
	ldr	pc, [sp], #4
.L6:
	.align	2
.L5:
	.word	.LC0
	.word	.LC1
	.word	.LC2
	.word	.LC3
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
