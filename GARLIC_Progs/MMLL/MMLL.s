	.arch armv5te
	.eabi_attribute 23, 1
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"MMLL.c"
	.text
	.align	2
	.global	_power100
	.syntax unified
	.arm
	.fpu softvfp
	.type	_power100, %function
_power100:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	sub	sp, sp, #24
	str	r0, [sp, #4]
	mov	r2, #1
	mov	r3, #0
	strd	r2, [sp, #16]
	mov	r3, #0
	str	r3, [sp, #12]
	b	.L2
.L3:
	ldr	r3, [sp, #20]
	mov	r2, #100
	mul	r2, r3, r2
	ldr	r3, [sp, #16]
	mov	r1, #0
	mul	r3, r1, r3
	add	r1, r2, r3
	ldr	r0, [sp, #16]
	mov	ip, #100
	umull	r2, r3, r0, ip
	add	r1, r1, r3
	mov	r3, r1
	strd	r2, [sp, #16]
	strd	r2, [sp, #16]
	ldr	r3, [sp, #12]
	add	r3, r3, #1
	str	r3, [sp, #12]
.L2:
	ldr	r2, [sp, #12]
	ldr	r3, [sp, #4]
	cmp	r2, r3
	blt	.L3
	ldrd	r2, [sp, #16]
	mov	r0, r2
	mov	r1, r3
	add	sp, sp, #24
	@ sp needed
	bx	lr
	.size	_power100, .-_power100
	.align	2
	.global	_GARLIC_random64
	.syntax unified
	.arm
	.fpu softvfp
	.type	_GARLIC_random64, %function
_GARLIC_random64:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 0, uses_anonymous_args = 0
	push	{r4, r5, lr}
	sub	sp, sp, #20
	bl	GARLIC_random
	mov	r3, r0
	str	r3, [sp, #12]
	bl	GARLIC_random
	mov	r3, r0
	str	r3, [sp, #8]
	ldr	r3, [sp, #12]
	mov	r2, r3
	mov	r3, #0
	mov	r5, r2
	mov	r4, #0
	ldr	r3, [sp, #8]
	mov	r2, r3
	mov	r3, #0
	orr	r2, r2, r4
	orr	r3, r3, r5
	strd	r2, [sp]
	ldrd	r2, [sp]
	mov	r0, r2
	mov	r1, r3
	add	sp, sp, #20
	@ sp needed
	pop	{r4, r5, pc}
	.size	_GARLIC_random64, .-_GARLIC_random64
	.section	.rodata
	.align	2
.LC0:
	.ascii	"-- Programa MMLL - PID (%d) --\012\000"
	.align	2
.LC1:
	.ascii	"Generant 100^%d elements...\012\000"
	.align	2
.LC2:
	.ascii	"Nombre d'elements 0. No es pot calcular min/max.\012"
	.ascii	"\000"
	.align	2
.LC3:
	.ascii	"Calcul finalitzat.\012\000"
	.align	2
.LC4:
	.ascii	"Minim: %x%x (Hex Alta, Baixa)\012\000"
	.align	2
.LC5:
	.ascii	"Maxim: %x%x (Hex Alta, Baixa)\012\000"
	.align	2
.LC6:
	.ascii	"-- Fi Programa MMLL - PID (%d) --\012\000"
	.text
	.align	2
	.global	_start
	.syntax unified
	.arm
	.fpu softvfp
	.type	_start, %function
_start:
	@ args = 0, pretend = 0, frame = 72
	@ frame_needed = 0, uses_anonymous_args = 0
	push	{r4, r5, r6, r7, lr}
	sub	sp, sp, #76
	str	r0, [sp, #4]
	bl	GARLIC_pid
	str	r0, [sp, #44]
	ldr	r3, [sp, #4]
	cmp	r3, #0
	bge	.L8
	mov	r3, #0
	str	r3, [sp, #4]
	b	.L9
.L8:
	ldr	r3, [sp, #4]
	cmp	r3, #3
	ble	.L9
	mov	r3, #3
	str	r3, [sp, #4]
.L9:
	ldr	r3, [sp, #4]
	add	r3, r3, #1
	mov	r0, r3
	bl	_power100
	strd	r0, [sp, #32]
	ldr	r1, [sp, #44]
	ldr	r0, .L17
	bl	GARLIC_printf
	ldr	r3, [sp, #4]
	add	r3, r3, #1
	mov	r1, r3
	ldr	r0, .L17+4
	bl	GARLIC_printf
	ldrd	r2, [sp, #32]
	orrs	r3, r2, r3
	beq	.L10
	bl	_GARLIC_random64
	strd	r0, [sp, #56]
	ldrd	r2, [sp, #56]
	strd	r2, [sp, #64]
	mov	r2, #1
	mov	r3, #0
	strd	r2, [sp, #48]
	b	.L13
.L10:
	ldr	r0, .L17+8
	bl	GARLIC_printf
	mov	r3, #0
	b	.L12
.L16:
	bl	_GARLIC_random64
	strd	r0, [sp, #24]
	ldrd	r0, [sp, #24]
	ldrd	r2, [sp, #64]
	cmp	r0, r2
	sbcs	r3, r1, r3
	bge	.L14
	ldrd	r2, [sp, #24]
	strd	r2, [sp, #64]
.L14:
	ldrd	r2, [sp, #24]
	ldrd	r0, [sp, #56]
	cmp	r0, r2
	sbcs	r3, r1, r3
	bge	.L15
	ldrd	r2, [sp, #24]
	strd	r2, [sp, #56]
.L15:
	ldrd	r2, [sp, #48]
	adds	r2, r2, #1
	adc	r3, r3, #0
	strd	r2, [sp, #48]
.L13:
	ldrd	r0, [sp, #48]
	ldrd	r2, [sp, #32]
	cmp	r1, r3
	cmpeq	r0, r2
	bcc	.L16
	ldrd	r2, [sp, #64]
	mov	r6, r3
	asr	r7, r3, #31
	mov	r3, r6
	str	r3, [sp, #20]
	ldr	r3, [sp, #64]
	str	r3, [sp, #16]
	ldrd	r2, [sp, #56]
	mov	r4, r3
	asr	r5, r3, #31
	mov	r3, r4
	str	r3, [sp, #12]
	ldr	r3, [sp, #56]
	str	r3, [sp, #8]
	ldr	r0, .L17+12
	bl	GARLIC_printf
	ldr	r2, [sp, #16]
	ldr	r1, [sp, #20]
	ldr	r0, .L17+16
	bl	GARLIC_printf
	ldr	r2, [sp, #8]
	ldr	r1, [sp, #12]
	ldr	r0, .L17+20
	bl	GARLIC_printf
	ldr	r1, [sp, #44]
	ldr	r0, .L17+24
	bl	GARLIC_printf
	mov	r3, #0
.L12:
	mov	r0, r3
	add	sp, sp, #76
	@ sp needed
	pop	{r4, r5, r6, r7, pc}
.L18:
	.align	2
.L17:
	.word	.LC0
	.word	.LC1
	.word	.LC2
	.word	.LC3
	.word	.LC4
	.word	.LC5
	.word	.LC6
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
