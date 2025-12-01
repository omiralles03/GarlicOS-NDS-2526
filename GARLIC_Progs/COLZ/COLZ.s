	.arch armv5te
	.eabi_attribute 23, 1
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"COLZ.c"
	.text
	.align	2
	.global	power_of_10
	.syntax unified
	.arm
	.fpu softvfp
	.type	power_of_10, %function
power_of_10:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	sub	sp, sp, #16
	str	r0, [sp, #4]
	mov	r3, #1
	str	r3, [sp, #12]
	mov	r3, #0
	str	r3, [sp, #8]
	b	.L2
.L5:
	ldr	r3, [sp, #12]
	ldr	r2, .L6
	cmp	r3, r2
	bls	.L3
	mvn	r3, #0
	b	.L4
.L3:
	ldr	r2, [sp, #12]
	mov	r3, r2
	lsl	r3, r3, #2
	add	r3, r3, r2
	lsl	r3, r3, #1
	str	r3, [sp, #12]
	ldr	r3, [sp, #8]
	add	r3, r3, #1
	str	r3, [sp, #8]
.L2:
	ldr	r2, [sp, #8]
	ldr	r3, [sp, #4]
	cmp	r2, r3
	blt	.L5
	ldr	r3, [sp, #12]
.L4:
	mov	r0, r3
	add	sp, sp, #16
	@ sp needed
	bx	lr
.L7:
	.align	2
.L6:
	.word	429496729
	.size	power_of_10, .-power_of_10
	.section	.rodata
	.align	2
.LC0:
	.ascii	"--- Programa COLZ (PID %d) ---\012\000"
	.align	2
.LC1:
	.ascii	"Argument rebut: %d\012\000"
	.align	2
.LC2:
	.ascii	"Av\355s: El l\355mit 10^%d desborda 32 bits!\012\000"
	.align	2
.LC3:
	.ascii	"L\355mit superior: %d (10^%d)\012\000"
	.align	2
.LC4:
	.ascii	"N\372mero aleatori generat n = %d\012\000"
	.align	2
.LC5:
	.ascii	"n = 0, no s'aplica la seq\374\350ncia.\012\000"
	.align	2
.LC6:
	.ascii	"Iniciant Collatz per %d...\012\000"
	.align	2
.LC7:
	.ascii	"ATENCI\323: Desbordament calculant 3n+1!\012\000"
	.align	2
.LC8:
	.ascii	"Seq\374\350ncia finaliztada en %d passos.\012\000"
	.align	2
.LC9:
	.ascii	"Aturat despr\351s de %d passos (l\355mit assolit).\012"
	.ascii	"\000"
	.align	2
.LC10:
	.ascii	"Error inesperat, no s'ha arribat a 1.\012\000"
	.align	2
.LC11:
	.ascii	"--- FI PROGRAMA COLZ (PID %d) ---\012\000"
	.text
	.align	2
	.global	_start
	.syntax unified
	.arm
	.fpu softvfp
	.type	_start, %function
_start:
	@ args = 0, pretend = 0, frame = 56
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #60
	str	r0, [sp, #4]
	mov	r3, #0
	str	r3, [sp, #48]
	ldr	r3, [sp, #4]
	cmp	r3, #0
	bge	.L9
	mov	r3, #0
	str	r3, [sp, #4]
	b	.L10
.L9:
	ldr	r3, [sp, #4]
	cmp	r3, #3
	ble	.L10
	mov	r3, #3
	str	r3, [sp, #4]
.L10:
	bl	GARLIC_pid
	mov	r3, r0
	mov	r1, r3
	ldr	r0, .L25
	bl	GARLIC_printf
	ldr	r1, [sp, #4]
	ldr	r0, .L25+4
	bl	GARLIC_printf
	ldr	r3, [sp, #4]
	add	r3, r3, #5
	str	r3, [sp, #44]
	ldr	r0, [sp, #44]
	bl	power_of_10
	str	r0, [sp, #40]
	ldr	r3, [sp, #40]
	cmn	r3, #1
	bne	.L11
	ldr	r3, [sp, #44]
	cmp	r3, #0
	ble	.L11
	ldr	r1, [sp, #44]
	ldr	r0, .L25+8
	bl	GARLIC_printf
.L11:
	ldr	r2, [sp, #44]
	ldr	r1, [sp, #40]
	ldr	r0, .L25+12
	bl	GARLIC_printf
	ldr	r3, [sp, #40]
	cmp	r3, #0
	bne	.L12
	mov	r3, #0
	str	r3, [sp, #20]
	b	.L13
.L12:
	bl	GARLIC_random
	mov	r3, r0
	str	r3, [sp, #36]
	add	r3, sp, #20
	add	r2, sp, #16
	ldr	r1, [sp, #40]
	ldr	r0, [sp, #36]
	bl	GARLIC_divmod
.L13:
	ldr	r3, [sp, #20]
	mov	r1, r3
	ldr	r0, .L25+16
	bl	GARLIC_printf
	ldr	r3, [sp, #20]
	str	r3, [sp, #52]
	ldr	r3, [sp, #52]
	cmp	r3, #0
	bne	.L14
	ldr	r0, .L25+20
	bl	GARLIC_printf
	b	.L15
.L14:
	ldr	r1, [sp, #52]
	ldr	r0, .L25+24
	bl	GARLIC_printf
	ldr	r3, .L25+28
	str	r3, [sp, #32]
	b	.L16
.L21:
	add	r3, sp, #12
	add	r2, sp, #16
	mov	r1, #2
	ldr	r0, [sp, #52]
	bl	GARLIC_divmod
	ldr	r3, [sp, #12]
	cmp	r3, #0
	bne	.L17
	ldr	r3, [sp, #16]
	str	r3, [sp, #52]
	b	.L18
.L17:
	ldr	r3, [sp, #52]
	mov	r0, r3
	mov	r1, #0
	mov	r2, r0
	mov	r3, r1
	adds	r2, r2, r2
	adc	r3, r3, r3
	adds	r2, r2, r0
	adc	r3, r3, r1
	adds	r2, r2, #1
	adc	r3, r3, #0
	strd	r2, [sp, #24]
	ldrd	r2, [sp, #24]
	mvn	r0, #0
	mov	r1, #0
	cmp	r3, r1
	cmpeq	r2, r0
	bls	.L19
	ldr	r0, .L25+32
	bl	GARLIC_printf
	ldr	r3, [sp, #32]
	str	r3, [sp, #48]
	b	.L20
.L19:
	ldr	r3, [sp, #24]
	str	r3, [sp, #52]
.L18:
	ldr	r3, [sp, #48]
	add	r3, r3, #1
	str	r3, [sp, #48]
.L16:
	ldr	r3, [sp, #52]
	cmp	r3, #1
	bls	.L20
	ldr	r2, [sp, #48]
	ldr	r3, [sp, #32]
	cmp	r2, r3
	bcc	.L21
.L20:
	ldr	r3, [sp, #52]
	cmp	r3, #1
	bne	.L22
	ldr	r1, [sp, #48]
	ldr	r0, .L25+36
	bl	GARLIC_printf
	b	.L15
.L22:
	ldr	r2, [sp, #48]
	ldr	r3, [sp, #32]
	cmp	r2, r3
	bcc	.L23
	ldr	r1, [sp, #32]
	ldr	r0, .L25+40
	bl	GARLIC_printf
	b	.L15
.L23:
	ldr	r0, .L25+44
	bl	GARLIC_printf
.L15:
	bl	GARLIC_pid
	mov	r3, r0
	mov	r1, r3
	ldr	r0, .L25+48
	bl	GARLIC_printf
	mov	r3, #0
	mov	r0, r3
	add	sp, sp, #60
	@ sp needed
	ldr	pc, [sp], #4
.L26:
	.align	2
.L25:
	.word	.LC0
	.word	.LC1
	.word	.LC2
	.word	.LC3
	.word	.LC4
	.word	.LC5
	.word	.LC6
	.word	100000
	.word	.LC7
	.word	.LC8
	.word	.LC9
	.word	.LC10
	.word	.LC11
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
