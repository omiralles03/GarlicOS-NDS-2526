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
	.ascii	"%1TADD:%0 Probando memoria dinamica...\012\000"
	.align	2
.LC1:
	.ascii	"Fin del test TADD.\012\000"
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
	mov	r3, #0
	str	r3, [sp, #12]
	ldr	r0, .L3
	bl	GARLIC_printf
	mov	r0, #1000
	bl	GARLIC_malloc
	str	r0, [sp, #8]
	ldr	r0, [sp, #8]
	bl	GARLIC_free
	ldr	r0, .L3+4
	bl	GARLIC_printf
	mov	r0, #5
	bl	GARLIC_delay
	mov	r3, #0
	str	r3, [sp, #12]
	ldr	r3, [sp, #12]
	mov	r0, r3
	add	sp, sp, #20
	@ sp needed
	ldr	pc, [sp], #4
.L4:
	.align	2
.L3:
	.word	.LC0
	.word	.LC1
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
