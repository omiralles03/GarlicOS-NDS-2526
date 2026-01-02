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
	.ascii	"TEST INICIO\012\000"
	.align	2
.LC1:
	.ascii	"TEST FIN\012\000"
	.text
	.align	2
	.global	_start
	.syntax unified
	.arm
	.fpu softvfp
	.type	_start, %function
_start:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #12
	str	r0, [sp, #4]
	ldr	r0, .L3
	bl	GARLIC_printf
	ldr	r0, .L3+4
	bl	GARLIC_delay
	ldr	r0, .L3+8
	bl	GARLIC_printf
	mov	r3, #0
	mov	r0, r3
	add	sp, sp, #12
	@ sp needed
	ldr	pc, [sp], #4
.L4:
	.align	2
.L3:
	.word	.LC0
	.word	5000
	.word	.LC1
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
