@;=                                                               		=
@;== Sprites_sopo.s: rutinas de manipular sprites para plataforma NDS ===
@;=                                                         			=
@;=== Analista-programador: santiago.romani@urv.cat			 		  ===
@;=                                                         	      	=


@;-- .bss. data section ---
.bss
		.align 2
	oam_data:	.space 128 * 8		@; espacio de trabajo para 128 sprites

@;-- .text. Program code ---
.text	
		.align 2
		.arm


@;SPR_actualiza_sprites(u16* base, unsigned char limite);
@;Rutina para copiar la información de los sprites en los registros de E/S
@;correspondientes, según la base OAM pasada por parámetro
@;Parámetros:
@;	base (R0):	0x7000000 para procesador gráfico principal
@;				0x7000400 para procesador gráfico secundario
@;	limite (R1):	valor máximo del índice de los sprites (1..128)
	.global SPR_actualiza_sprites
SPR_actualiza_sprites:
		push {r1-r4, lr}
		
		ldr r4, =oam_data		@; R4 = dirección inicial de datos oam
		mov r1, r1, lsl #3		@; R1 = límite índice * 8 (= límite posiciones)
		mov r2, #0				@; R2 = índice de posiciones
	.LaS_bucle:
		cmp r2, r1				@; mientras índice < límite (*8)
		beq .LaS_fibucle
		ldr r3, [r4, r2]		@; carga valor de atributos 0 y 1
		str r3, [r0, r2]		@; guarda el valor en los registros de E/S
		add r2, #4
		ldr r3, [r4, r2]		@; carga valor de atributo 2 + Rot/esc
		str r3, [r0, r2]		@; guarda el valor en los registros de E/S
		add r2, #4
		b .LaS_bucle
	.LaS_fibucle:
		pop {r1-r4, pc}



@;SPR_crea_sprite(unsigned char indice, unsigned char forma,
@;								unsigned char tam, unsigned short baldosa);
@;Rutina para configurar el sprite indicado por parámetro
@;Parámetros:
@;	indice (R0):	índice del sprite a crear (0..127)
@;	forma (R1):		0-> cuadrada, 1-> horizontal, 2-> vertical
@;	tam (R2):	forma cuadrada		0-> 8x8, 1-> 16x16, 2-> 32x32, 3-> 64x64
@;				forma horizontal	0-> 8x16, 1-> 8x32, 2-> 16x32, 3-> 32x64
@;				forma vertical		0-> 16x8, 1-> 32x8, 2-> 32x16, 3-> 64x32
@;	baldosa (R3):	índice de baldosa de 8x8 píxeles (0..1023)
	.global SPR_crea_sprite
SPR_crea_sprite:
		push {r0-r5, lr}
		
		and r0, #127			@; filtra índice de sprite
		and r1, #3				@; filtra forma
		and r2, #3				@; filtra tamaño
		bic r3, #0xFC00			@; filtra índice de baldosa
		ldr r4, =oam_data		@; R4 = direccion inicial de datos oam
		add r4, r0, lsl #3		@; suma índice de sprite * 8
		ldrh r5, [r4]			@; carga valor de atributo 0
		orr r5, #0x2000			@; activa bit 13 (256 colores)
		bic r5, #0xC000			@; borra bits 15..14
		orr r5, r1, lsl #14		@; activa bits forma, desplazado a bits 15..14
		strh r5, [r4]			@; guarda el nuevo valor del atributo 0
		ldrh r5, [r4, #2]		@; carga valor de atributo 1
		bic r5, #0xC000			@; borra bits 15..14
		orr r5, r2, lsl #14		@; activa bits tamaño, desplazado a bits 15..14
		strh r5, [r4, #2]		@; guarda el nuevo valor del atributo 1
		ldrh r5, [r4, #4]		@; carga valor de atributo 2
		bic r5, #0x00FF			@; borra bits 7..0
		bic r5, #0x0300			@; borra bits 9..8
		orr r5, r3, lsl #1		@; activa bits índice baldosa (desplazado un
								@; un bit a la izquierda por ser 256 colores)
		strh r5, [r4, #4]		@; guarda el nuevo valor del atributo 2
		
		pop {r0-r5, pc}



@;SPR_muestra_sprite(unsigned char indice);
@;Rutina para mostrar el sprite indicado por parámetro
@;Parámetros:
@;	indice (R0):	índice del sprite a mostrar (0..127)
	.global SPR_muestra_sprite
SPR_muestra_sprite:
		push {r0-r3, lr}
		
		and r0, #127			@; filtra índice de sprite
		ldr r1, =oam_data		@; R1 = dirección inicial de datos oam
		mov r2, r0, lsl #3		@; R2 = índice sprite * 8
		ldrh r3, [r1, r2]		@; carga valor de atributo 0
		bic r3, #0x0200			@; desactiva bit 9 para mostrar sprite
		strh r3, [r1, r2]		@; guarda el nuevo valor del atributo
		
		pop {r0-r3, pc}


@;SPR_oculta_sprite(unsigned char indice);
@;Rutina para ocultar el sprite indicado por parámetro
@;Parámetros:
@;	indice (R0):	índice del sprite a ocultar (0..127)
	.global SPR_oculta_sprite
SPR_oculta_sprite:
		push {r0-r3, lr}
		
		and r0, #127			@; filtra índice de sprite
		ldr r1, =oam_data		@; R1 = direccion inicial de datos oam
		mov r2, r0, lsl #3		@; R2 = índice sprite * 8
		ldrh r3, [r1, r2]		@; cargar valor de atributo 0
		orr r3, #0x0200			@; activar bit 9 para ocultar sprite
		strh r3, [r1, r2]		@; guarda el nuevo valor del atributo
		
		pop {r0-r3, pc}


@;SPR_oculta_sprites(unsigned char limite);
@;Rutina para ocultar todos los sprites hasta el límite indicado
@;Parámetros:
@;	limite (R0):	valor máximo del índice de los sprites (1..128)
	.global SPR_oculta_sprites
SPR_oculta_sprites:
		push {r0-r1, lr}
		
		mov r1, r0				@; R1 guarda el límite
		mov r0, #0				@; R0 = índice de sprite
	.LbSbucle:
		cmp r0, r1
		beq .LbS_fibucle		@; por cada índice,
		bl SPR_oculta_sprite	@; llama a la rutina que efectúa la ocultación
		add r0, #1
		b .LbSbucle
	.LbS_fibucle:
		
		pop {r0-r1, pc}



@;SPR_mueve_sprite(unsigned char indice, short px, short py);
@;Rutina para mover el extremo superior-izquierdo
@;hasta la posición (px, py) indicada por parámetro
@;Parámetros:
@;	indice (R0):	índice del sprite a mover (0..127)
@;	px (R1):		nueva coordenada x del sprite
@;	py (R2):		nueva coordenada y del sprite
	.global SPR_mueve_sprite
SPR_mueve_sprite:
		push {r0-r2, r4-r5, lr}
		
		and r0, #127			@; filtra índice de sprite
		bic r1, #0xFE00			@; filtra coordenada X (0..511)
		and r2, #255			@; filtra coordenada Y (0..255)
		ldr r4, =oam_data		@; R4 = direccion inicial de datos oam
		add r4, r0, lsl #3		@; suma índice de sprite * 8
		ldrh r5, [r4]			@; carga valor de atributo 0
		bic r5, #0x00FF			@; borra bits 7..0
		orr r5, r2				@; activa bits py
		strh r5, [r4]			@; guarda el nuevo valor del atributo 0
		ldrh r5, [r4, #2]		@; carga valor de atributo 1
		bic r5, #0x00FF			@; borra bits 7..0
		bic r5, #0x0100			@; borra bit 8
		orr r5, r1				@; activa bits px
		strh r5, [r4, #2]		@; guarda el nuevo valor del atributo 1
		
		pop {r0-r2, r4-r5, pc}


@;SPR_fija_prioridad(unsigned char indice, unsigned char prioridad);
@;Rutina para fijar la prioridad del sprite respecto a los fondos gráficos
@;Parámetros:
@;	indice (R0):	índice del sprite a modificar su prioridad (0..127)
@;	prioridad (R1):	prioridad relativa (0..3, 0 -> màxima)
	.global SPR_fija_prioridad
SPR_fija_prioridad:
		push {r0-r3, lr}
		
		and r0, #127			@; filtra índice de sprite
		and r1, #3				@; filtra prioridad
		ldr r2, =oam_data		@; R2 = direccion inicial de datos oam
		add r2, r0, lsl #3		@; suma índice de sprite * 8
		ldrh r3, [r2, #4]		@; carga valor de atributo 2
		bic r3, #0x0C00			@; borra bits 11..10
		orr r3, r1, lsl #10		@; añade prioridad, desplazada a bits 11..10
		strh r3, [r2, #4]		@; guarda el nuevo valor del atributo
		
		pop {r0-r3, pc}



@;SPR_activa_rotacionEscalado(unsigned char indice, unsigned char grupo);
@;Rutina para asignar un grupo de rotación/escalado al sprite indicado
@;Parámetros:
@;	indice (R0):	índice del sprite a activar su grupo de R/E (0..127)
@;	grupo (R1):		índice del grupo (0..31)
	.global SPR_activa_rotacionEscalado
SPR_activa_rotacionEscalado:
		push {r0-r1, r4-r5, lr}
		
		and r0, #127			@; filtra índice de sprite
		and r1, #31				@; filtra índice de grupo
		ldr r4, =oam_data		@; R4 = direccion inicial de datos oam
		add r4, r0, lsl #3		@; suma índice de sprite * 8
		ldrh r5, [r4, #2]		@; carga valor de atributo 1
		bic r5, #0x3E00			@; borra bits 13..9
		orr r5, r1, lsl #9		@; fija grupo, desplazado a bits 13..9
		strh r5, [r4, #2]		@; guarda el nuevo valor del atributo 1
		ldrh r5, [r4]			@; carga valor de atributo 0
		orr r5, #0x0100			@; activa bit 8 (rotación/escalado activo)
		bic r5, #0x0200			@; desactiva bit 9 (tamaño normal)
		strh r5, [r4]			@; guarda el nuevo valor del atributo 0
		
		pop {r0-r1, r4-r5, pc}


@;SPR_desactiva_rotacionEscalado(unsigned char indice);
@;Rutina para desactivar la rotación/escalado del sprite indicado
@;Restricciones: el sprite quedará visible, porque se supone que ya lo era;
@;	en caso contrario, habrá que llamar a SPR_oculta_sprite() después de
@;	llamar a esta rutina.
@;Parámetros:
@;	indice (R0):	índice del sprite a desactivar su R/E (0..127)
	.global SPR_desactiva_rotacionEscalado
SPR_desactiva_rotacionEscalado:
		push {r0, r4-r5, lr}
		
		and r0, #127			@; filtra índice de sprite
		ldr r4, =oam_data		@; R4 = direccion inicial de datos oam
		add r4, r0, lsl #3		@; suma índice de sprite * 8
		ldrh r5, [r4]			@; carga valor de atributo 0
		bic r5, #0x0300			@; desactiva bit 8 (rotación/escalado)
								@; desactiva bit 9 (sprite visible)
		strh r5, [r4]			@; guarda el nuevo valor del atributo 0
		
		pop {r0, r4-r5, pc}


@;SPR_fija_escalado(unsigned char igrp, unsigned short sx, unsigned short sy);
@;Rutina para fijar un valor de escala en cada coordenada (sx,sy) de un grupo
@;	de rotación/escalado indicado en el parámetro igrp
@;Parámetros:
@;	igrp (R0):		índice del grupo de rotación-escalado (0..31)
@;	sx (R1):		factor de escalado x (formato 0.8.8)
@;	sy (R2):		factor de escalado y (formato 0.8.8) 
	.global SPR_fija_escalado
SPR_fija_escalado:
		push {r0, r4-r5, lr}
		
		and r0, #31				@; filtra índice de grupo
		mov r5, #0
		ldr r4, =oam_data		@; R4 = direccion inicial de datos oam
		add r4, r0, lsl #5		@; suma índice de grupo * 32
		strh r1, [r4, #6]		@; PA = sx
		strh r5, [r4, #14]		@; PB = 0
		strh r5, [r4, #22]		@; PC = 0
		strh r2, [r4, #30]		@; PD = sy
		
		pop {r0, r4-r5, pc}




.end
