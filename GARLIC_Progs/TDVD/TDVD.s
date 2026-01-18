	.arch armv5te
	.eabi_attribute 23, 1
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"TDVD.c"
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
	mov	r3, #224
	strh	r3, [sp, #18]	@ movhi
	mov	r3, #160
	strh	r3, [sp, #16]	@ movhi
	mov	r3, #0
	strh	r3, [sp, #14]	@ movhi
	mov	r3, #0
	strh	r3, [sp, #12]	@ movhi
	ldr	r3, [sp, #4]
	add	r3, r3, #2
	lsl	r3, r3, #16
	lsr	r3, r3, #16
	lsl	r3, r3, #3
	lsl	r3, r3, #16
	lsr	r3, r3, #16
	strh	r3, [sp, #30]	@ movhi
	ldr	r3, [sp, #4]
	add	r3, r3, #2
	lsl	r3, r3, #16
	lsr	r3, r3, #16
	lsl	r3, r3, #2
	lsl	r3, r3, #16
	lsr	r3, r3, #16
	strh	r3, [sp, #28]	@ movhi
	bl	GARLIC_pid
	mov	r2, r0
	ldr	r3, [sp, #4]
	mul	r2, r3, r2
	asr	r3, r2, #31
	lsr	r3, r3, #28
	add	r2, r2, r3
	and	r2, r2, #15
	sub	r3, r2, r3
	strb	r3, [sp, #11]
	ldr	r2, [sp, #4]
	mov	r3, r2
	lsl	r3, r3, #1
	add	r3, r3, r2
	add	r2, r3, #7
	asr	r3, r2, #31
	lsr	r3, r3, #27
	add	r2, r2, r3
	and	r2, r2, #31
	sub	r3, r2, r3
	strb	r3, [sp, #10]
	ldrh	r3, [sp, #14]	@ movhi
	strh	r3, [sp, #26]	@ movhi
	ldrh	r3, [sp, #12]	@ movhi
	strh	r3, [sp, #24]	@ movhi
	ldrb	r2, [sp, #10]	@ zero_extendqisi2
	ldrb	r3, [sp, #11]	@ zero_extendqisi2
	mov	r1, r2
	mov	r0, r3
	bl	GARLIC_spriteSet
	ldrsh	r2, [sp, #24]
	ldrsh	r1, [sp, #26]
	ldrb	r3, [sp, #11]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteMove
	ldrb	r3, [sp, #11]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteShow
	mov	r3, #0
	str	r3, [sp, #20]
	b	.L2
.L7:
	mov	r0, #0
	bl	GARLIC_delay
	ldrh	r2, [sp, #26]
	ldrh	r3, [sp, #30]
	add	r3, r2, r3
	lsl	r3, r3, #16
	lsr	r3, r3, #16
	strh	r3, [sp, #26]	@ movhi
	ldrh	r2, [sp, #24]
	ldrh	r3, [sp, #28]
	add	r3, r2, r3
	lsl	r3, r3, #16
	lsr	r3, r3, #16
	strh	r3, [sp, #24]	@ movhi
	ldrsh	r2, [sp, #26]
	ldrsh	r3, [sp, #18]
	cmp	r2, r3
	blt	.L3
	ldrh	r3, [sp, #18]	@ movhi
	strh	r3, [sp, #26]	@ movhi
	ldrh	r3, [sp, #30]
	rsb	r3, r3, #0
	lsl	r3, r3, #16
	lsr	r3, r3, #16
	strh	r3, [sp, #30]	@ movhi
	b	.L4
.L3:
	ldrsh	r2, [sp, #26]
	ldrsh	r3, [sp, #14]
	cmp	r2, r3
	bgt	.L4
	ldrh	r3, [sp, #14]	@ movhi
	strh	r3, [sp, #26]	@ movhi
	ldrh	r3, [sp, #30]
	rsb	r3, r3, #0
	lsl	r3, r3, #16
	lsr	r3, r3, #16
	strh	r3, [sp, #30]	@ movhi
.L4:
	ldrsh	r2, [sp, #24]
	ldrsh	r3, [sp, #16]
	cmp	r2, r3
	blt	.L5
	ldrh	r3, [sp, #16]	@ movhi
	strh	r3, [sp, #24]	@ movhi
	ldrh	r3, [sp, #28]
	rsb	r3, r3, #0
	lsl	r3, r3, #16
	lsr	r3, r3, #16
	strh	r3, [sp, #28]	@ movhi
	b	.L6
.L5:
	ldrsh	r2, [sp, #24]
	ldrsh	r3, [sp, #12]
	cmp	r2, r3
	bgt	.L6
	ldrh	r3, [sp, #12]	@ movhi
	strh	r3, [sp, #24]	@ movhi
	ldrh	r3, [sp, #28]
	rsb	r3, r3, #0
	lsl	r3, r3, #16
	lsr	r3, r3, #16
	strh	r3, [sp, #28]	@ movhi
.L6:
	ldrsh	r2, [sp, #24]
	ldrsh	r1, [sp, #26]
	ldrb	r3, [sp, #11]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteMove
	ldr	r3, [sp, #20]
	add	r3, r3, #1
	str	r3, [sp, #20]
.L2:
	ldr	r3, [sp, #20]
	cmp	r3, #500
	blt	.L7
	ldrb	r3, [sp, #11]	@ zero_extendqisi2
	mov	r0, r3
	bl	GARLIC_spriteHide
	mov	r3, #0
	mov	r0, r3
	add	sp, sp, #36
	@ sp needed
	ldr	pc, [sp], #4
	.size	_start, .-_start
	.ident	"GCC: (devkitARM release 46) 6.3.0"
