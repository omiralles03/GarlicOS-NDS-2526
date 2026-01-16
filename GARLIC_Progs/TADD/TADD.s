	.arch armv5te
	.eabi_attribute 23, 1
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"TADD.c"
	.text
	.align	2
	.global	mi_delay
	.syntax unified
	.arm
	.fpu softvfp
	.type	mi_delay, %function
mi_delay:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #20
	str	r0, [sp, #4]
	ldr	r2, [sp, #4]
	mov	r3, r2
	lsl	r3, r3, #4
	sub	r3, r3, r2
	lsl	r3, r3, #2
	str	r3, [sp, #12]
	b	.L2
.L3:
	mov	r0, #0
	bl	GARLIC_delay
	ldr	r3, [sp, #12]
	sub	r3, r3, #1
	str	r3, [sp, #12]
.L2:
	ldr	r3, [sp, #12]
	cmp	r3, #0
	bgt	.L3
	nop
	add	sp, sp, #20
	@ sp needed
	ldr	pc, [sp], #4
	.size	mi_delay, .-mi_delay
	.section	.rodata
	.align	2
.LC0:
	.ascii	"[TADD %d] TEST MEMORIA DINAMICA\012\000"
	.align	2
.LC1:
	.ascii	"Reserva Gran (10 franges)\012\000"
	.align	2
.LC2:
	.ascii	"- p1(64B): OK en %x\012\000"
	.align	2
.LC3:
	.ascii	"- p1 (64B): ERROR\012\000"
	.align	2
.LC4:
	.ascii	"Emplenant slots (max 4)\012\000"
	.align	2
.LC5:
	.ascii	"-OK: 4 blocs reservats\012\000"
	.align	2
.LC6:
	.ascii	"-ERROR: en reserva 4 slots\012\000"
	.align	2
.LC7:
	.ascii	"Intent 5o bloc...\012\000"
	.align	2
.LC8:
	.ascii	" -> OK: Bloquejat (retorno 0)\012\000"
	.align	2
.LC9:
	.ascii	" -> FAIL: S'ha permes la 5a reserva\012\000"
	.align	2
.LC10:
	.ascii	"Test Free Invalid\012\000"
	.align	2
.LC11:
	.ascii	" -> OK: Detectado ptr invalid\012\000"
	.align	2
.LC12:
	.ascii	" -> FAIL: Free ha acceptat brossa\012\000"
	.align	2
.LC13:
	.ascii	"Test Huecos (Llibero P2)\012\000"
	.align	2
.LC14:
	.ascii	" Emplenant hueco...\012\000"
	.align	2
.LC15:
	.ascii	" -> Re-reservt en %x\012\000"
	.align	2
.LC16:
	.ascii	"Neteja final...\012\000"
	.align	2
.LC17:
	.ascii	"[TADD %d] END Test\012\000"
	.text
	.align	2
	.global	_start
	.syntax unified
	.arm
	.fpu softvfp
	.type	_start, %function
_start:
	@ args = 0, pretend = 0, frame = 32
	@ frame_needed = 0, uses_anonymous_args = 0
	str	lr, [sp, #-4]!
	sub	sp, sp, #36
	str	r0, [sp, #4]
	mov	r3, #0
	mov	r2, #0
	mov	r1, #0
	ldr	r0, .L15
	bl	GARLIC_printf
	mov	r3, #0
	mov	r2, #0
	mov	r1, #0
	ldr	r0, .L15+4
	bl	GARLIC_printf
	mov	r0, #320
	bl	GARLIC_malloc
	str	r0, [sp, #28]
	ldr	r3, [sp, #28]
	cmp	r3, #0
	beq	.L5
	mov	r3, #0
	mov	r2, #0
	ldr	r1, [sp, #28]
	ldr	r0, .L15+8
	bl	GARLIC_printf
	b	.L6
.L5:
	mov	r3, #0
	mov	r2, #0
	mov	r1, #0
	ldr	r0, .L15+12
	bl	GARLIC_printf
.L6:
	mov	r0, #2
	bl	mi_delay
	mov	r3, #0
	mov	r2, #0
	mov	r1, #0
	ldr	r0, .L15+16
	bl	GARLIC_printf
	mov	r0, #32
	bl	GARLIC_malloc
	str	r0, [sp, #24]
	mov	r0, #32
	bl	GARLIC_malloc
	str	r0, [sp, #20]
	mov	r0, #32
	bl	GARLIC_malloc
	str	r0, [sp, #16]
	ldr	r3, [sp, #24]
	cmp	r3, #0
	beq	.L7
	ldr	r3, [sp, #20]
	cmp	r3, #0
	beq	.L7
	ldr	r3, [sp, #16]
	cmp	r3, #0
	beq	.L7
	mov	r3, #0
	mov	r2, #0
	mov	r1, #0
	ldr	r0, .L15+20
	bl	GARLIC_printf
	b	.L8
.L7:
	mov	r3, #0
	mov	r2, #0
	mov	r1, #0
	ldr	r0, .L15+24
	bl	GARLIC_printf
.L8:
	mov	r0, #2
	bl	mi_delay
	mov	r3, #0
	mov	r2, #0
	mov	r1, #0
	ldr	r0, .L15+28
	bl	GARLIC_printf
	mov	r0, #32
	bl	GARLIC_malloc
	str	r0, [sp, #12]
	ldr	r3, [sp, #12]
	cmp	r3, #0
	bne	.L9
	mov	r3, #0
	mov	r2, #0
	mov	r1, #0
	ldr	r0, .L15+32
	bl	GARLIC_printf
	b	.L10
.L9:
	mov	r3, #0
	mov	r2, #0
	mov	r1, #0
	ldr	r0, .L15+36
	bl	GARLIC_printf
.L10:
	mov	r0, #2
	bl	mi_delay
	mov	r3, #0
	mov	r2, #0
	mov	r1, #0
	ldr	r0, .L15+40
	bl	GARLIC_printf
	ldr	r0, .L15+44
	bl	GARLIC_free
	str	r0, [sp, #8]
	ldr	r3, [sp, #8]
	cmp	r3, #0
	bne	.L11
	mov	r3, #0
	mov	r2, #0
	mov	r1, #0
	ldr	r0, .L15+48
	bl	GARLIC_printf
	b	.L12
.L11:
	mov	r3, #0
	mov	r2, #0
	mov	r1, #0
	ldr	r0, .L15+52
	bl	GARLIC_printf
.L12:
	mov	r0, #2
	bl	mi_delay
	mov	r3, #0
	mov	r2, #0
	mov	r1, #0
	ldr	r0, .L15+56
	bl	GARLIC_printf
	ldr	r0, [sp, #24]
	bl	GARLIC_free
	mov	r0, #2
	bl	mi_delay
	mov	r3, #0
	mov	r2, #0
	mov	r1, #0
	ldr	r0, .L15+60
	bl	GARLIC_printf
	mov	r0, #32
	bl	GARLIC_malloc
	str	r0, [sp, #24]
	ldr	r3, [sp, #24]
	cmp	r3, #0
	beq	.L13
	mov	r3, #0
	mov	r2, #0
	ldr	r1, [sp, #24]
	ldr	r0, .L15+64
	bl	GARLIC_printf
.L13:
	mov	r0, #2
	bl	mi_delay
	mov	r3, #0
	mov	r2, #0
	mov	r1, #0
	ldr	r0, .L15+68
	bl	GARLIC_printf
	ldr	r0, [sp, #28]
	bl	GARLIC_free
	ldr	r0, [sp, #24]
	bl	GARLIC_free
	ldr	r0, [sp, #20]
	bl	GARLIC_free
	ldr	r0, [sp, #16]
	bl	GARLIC_free
	mov	r3, #0
	mov	r2, #0
	mov	r1, #0
	ldr	r0, .L15+72
	bl	GARLIC_printf
	mov	r3, #0
	mov	r0, r3
	add	sp, sp, #36
	@ sp needed
	ldr	pc, [sp], #4
.L16:
	.align	2
.L15:
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
	.word	-559038737
	.word	.LC11
	.word	.LC12
	.word	.LC13
	.word	.LC14
	.word	.LC15
	.word	.LC16
	.word	.LC17
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
