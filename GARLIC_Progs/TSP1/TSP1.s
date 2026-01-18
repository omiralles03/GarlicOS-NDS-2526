	.arch armv5te
	.eabi_attribute 23, 1
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"TSP1.c"
	.section	.rodata
	.align	2
.LC0:
	.ascii	"\012\012\012\012\012\000"
	.align	2
.LC1:
	.ascii	"\012%0Sprite[%d]: \000"
	.align	2
.LC2:
	.ascii	"%0[%d, %d]\012\000"
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
	ldr	r0, .L9
	bl	GARLIC_printf
	mov	r3, #0
	strb	r3, [sp, #15]
	mov	r3, #0
	strb	r3, [sp, #14]
	mov	r3, #112
	strh	r3, [sp, #12]	@ movhi
	mov	r3, #80
	strh	r3, [sp, #10]	@ movhi
	ldrb	r2, [sp, #14]	@ zero_extendqisi2
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r1, r2
	mov	r0, r3
	bl	GARLIC_spriteSet
	ldrsh	r2, [sp, #10]
	ldrsh	r1, [sp, #12]
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteMove
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteShow
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r1, r3
	ldr	r0, .L9+4
	bl	GARLIC_printf
	ldrsh	r3, [sp, #12]
	ldrsh	r2, [sp, #10]
	mov	r1, r3
	ldr	r0, .L9+8
	bl	GARLIC_printf
	mov	r3, #1
	strb	r3, [sp, #15]
	mov	r3, #9
	strb	r3, [sp, #14]
	mvn	r3, #15
	strh	r3, [sp, #12]	@ movhi
	mvn	r3, #15
	strh	r3, [sp, #10]	@ movhi
	ldrb	r2, [sp, #14]	@ zero_extendqisi2
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r1, r2
	mov	r0, r3
	bl	GARLIC_spriteSet
	ldrsh	r2, [sp, #10]
	ldrsh	r1, [sp, #12]
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteMove
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteShow
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r1, r3
	ldr	r0, .L9+4
	bl	GARLIC_printf
	ldrsh	r3, [sp, #12]
	ldrsh	r2, [sp, #10]
	mov	r1, r3
	ldr	r0, .L9+8
	bl	GARLIC_printf
	mov	r3, #2
	strb	r3, [sp, #15]
	mov	r3, #15
	strb	r3, [sp, #14]
	mov	r3, #50
	strh	r3, [sp, #12]	@ movhi
	mov	r3, #80
	strh	r3, [sp, #10]	@ movhi
	ldrb	r2, [sp, #14]	@ zero_extendqisi2
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r1, r2
	mov	r0, r3
	bl	GARLIC_spriteSet
	ldrsh	r2, [sp, #10]
	ldrsh	r1, [sp, #12]
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteMove
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteShow
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r1, r3
	ldr	r0, .L9+4
	bl	GARLIC_printf
	ldrsh	r3, [sp, #12]
	ldrsh	r2, [sp, #10]
	mov	r1, r3
	ldr	r0, .L9+8
	bl	GARLIC_printf
	ldr	r3, [sp, #4]
	cmp	r3, #3
	ldrls	pc, [pc, r3, asl #2]
	b	.L2
.L4:
	.word	.L3
	.word	.L5
	.word	.L6
	.word	.L7
.L3:
	mov	r3, #3
	strb	r3, [sp, #15]
	mov	r3, #3
	strb	r3, [sp, #14]
	mov	r3, #150
	strh	r3, [sp, #12]	@ movhi
	mov	r3, #150
	strh	r3, [sp, #10]	@ movhi
	ldrb	r2, [sp, #14]	@ zero_extendqisi2
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r1, r2
	mov	r0, r3
	bl	GARLIC_spriteSet
	ldrsh	r2, [sp, #10]
	ldrsh	r1, [sp, #12]
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteMove
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteShow
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r1, r3
	ldr	r0, .L9+4
	bl	GARLIC_printf
	ldrsh	r3, [sp, #12]
	ldrsh	r2, [sp, #10]
	mov	r1, r3
	ldr	r0, .L9+8
	bl	GARLIC_printf
	mov	r3, #4
	strb	r3, [sp, #15]
	mov	r3, #24
	strb	r3, [sp, #14]
	mov	r3, #220
	strh	r3, [sp, #12]	@ movhi
	mov	r3, #113
	strh	r3, [sp, #10]	@ movhi
	ldrb	r2, [sp, #14]	@ zero_extendqisi2
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r1, r2
	mov	r0, r3
	bl	GARLIC_spriteSet
	ldrsh	r2, [sp, #10]
	ldrsh	r1, [sp, #12]
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteMove
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteShow
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r1, r3
	ldr	r0, .L9+4
	bl	GARLIC_printf
	ldrsh	r3, [sp, #12]
	ldrsh	r2, [sp, #10]
	mov	r1, r3
	ldr	r0, .L9+8
	bl	GARLIC_printf
	b	.L2
.L5:
	mov	r3, #0
	strb	r3, [sp, #15]
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteHide
	mov	r3, #1
	strb	r3, [sp, #15]
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteHide
	mov	r3, #2
	strb	r3, [sp, #15]
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteHide
	b	.L2
.L6:
	mov	r3, #3
	strb	r3, [sp, #15]
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteHide
	mov	r3, #4
	strb	r3, [sp, #15]
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteHide
	b	.L2
.L7:
	mov	r3, #3
	strb	r3, [sp, #15]
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteHide
	mov	r3, #4
	strb	r3, [sp, #15]
	ldrb	r3, [sp, #15]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteHide
	nop
.L2:
	mov	r3, #0
	mov	r0, r3
	add	sp, sp, #20
	@ sp needed
	ldr	pc, [sp], #4
.L10:
	.align	2
.L9:
	.word	.LC0
	.word	.LC1
	.word	.LC2
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
