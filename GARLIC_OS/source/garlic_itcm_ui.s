@;==============================================================================
@;
@;	"garlic_itcm_ui.s":	código de variables y rutinas de soporte a la interficie
@;						de usuario para GARLIC 2.0
@;						(ver "garlic_system.h" para descripción)
@;
@;==============================================================================


.section .dtcm,"wa",%progbits

	.align 2

	.global _gi_za				@; zócalo seleccionado actualmente
_gi_za:			.word 0

	.global _gi_nFrames
_gi_nFrames:	.hword 0		@; número de frames de la animación
	.global _gi_orgX
_gi_orgX:		.hword 0		@; origen X de los fondos de las ventanas
	.global _gi_orgY
_gi_orgY:		.hword 0		@; origen Y de los fondos de las ventanas
_gi_orgX_ant:	.hword 0		@; origen X anterior de las ventanas
_gi_orgY_ant:	.hword 0		@; origen Y anterior de las ventanas
	.global _gi_zoom
_gi_zoom:		.hword 0x200	@; zoom de los fondos de las ventanas
_gi_zoom_ant:	.hword 0x200	@; zoom anterior de las ventanas
								@; 	inicialmente zoom intermedio (1/2)
	.global _gi_vvis
_gi_vvis:		.hword 0x33		@; ventanas visibles (1 bit por ventana)
								@; 	inicialmente estan visibles ventanas 0,1,4,5

.section .itcm,"ax",%progbits

	.arm
	.align 2

_gi_enable_IRQVcount:
	push {r11-r12, lr}
	mov	r12, #0x4000000
	add	r12, r12, #0x210
	ldr r11, [r12]				@; R11 = REG_IE
	orr r11, #0x4				@; activar bit de IRQ_YTRIGGER
	str r11, [r12]				@; interrupciones Vcount permitidas
	pop {r11-r12, pc}

_gi_disable_IRQVcount:
	push {r11-r12, lr}
	mov	r12, #0x4000000
	add	r12, r12, #0x210
	ldr r11, [r12]				@; R11 = REG_IE
	bic r11, #0x4				@; desactivar bit de IRQ_YTRIGGER
	str r11, [r12]				@; interrupciones Vcount NO permitidas
	pop {r11-r12, pc}


	@; Rutina para actualizar los bits de las ventanas visibles en la variable
	@; global _gi_vvis
_gi_actualizarVvis:
	push {r0-r4, lr}
	
	ldr r1, =_gi_zoom
	ldrh r2, [r1]				@; R2 = _gi_zoom
	cmp r2, #1024				@; con zoom mínimo (16 ventanas visibles)
	moveq r0, #0xFF				@; 	cualquier ventana es visible
	orreq r0, #0xFF00
	beq .Lavv_end
	
	ldr r1, =_gi_za
	ldr r3, [r1]				@; R3 = _gi_za
	mov r4, #1
	mov r4, r4, lsl r3			@; R4 = 1 << _gi_za (bit corresp. a zoc. act.)
	
	cmp r2, #256				@; con zoom máximo (1 ventana visible)		
	moveq r0, r4				@;	solo la ventana _gi_za es visible
	beq .Lavv_end				@; con zoom intermedio (4 ventanas visibles)
								@;	la CPU llega a esta sección
	mov r0, #0x33				@; R3 = máscara de ventanas 0,1,4,5
	tst r4, r0					@; comprovar coincidencia de bits
	bne .Lavv_end
	mov r0, #0xCC				@; máscara ventanas 2,3,6,7
	tst r4, r0					@; comprovar coincidencia de bits
	bne .Lavv_end
	mov r0, #0x3300				@; máscara ventanas 8,9,12,13
	tst r4, r0					@; comprovar coincidencia de bits
	moveq r0, #0xCC00			@; máscara ventanas 10,11,14,15

.Lavv_end:		
	ldr r3, =_gi_vvis
	strh r0, [r3]				@; actualizar _gi_vvis

	pop {r0-r4, pc}


	@; Rutina para determinar si la ventana correspondiente al zócalo que se
	@; pasa por parámetro está visible o no en función de la ventana en foco
	@; actual y del zoom actual;
	@;Parámetros:
	@;	R0: número de zócalo/ventana a consultar (int v)
	@;Resultado:
	@;	R0: booleano indicando si la ventana está visible (1) o no (0)
	.global _gi_ventanaVisible
_gi_ventanaVisible:
	push {r1, r2, lr}
	
	ldr r1, =_gi_vvis
	ldrh r2, [r1]				@; R2 = _gi_vvis
	mov r1, #1
	mov r1, r1, lsl r0			@; R1 = 1 << v (bit corresp. a ventana indicada)
	tst r1, r2
	moveq r0, #0				@; no hay coincidencia
	movne r0, #1				@; sí hay coincidencia
	
	pop {r1, r2, pc}



	.global _gi_movimientoVentanas
_gi_movimientoVentanas:
	push {r0-r3, r8-r9, lr}
	
	ldr r0, =_gi_nFrames
	ldrh r1, [r0]				@; R1 = numero actual de frames
	cmp r1, #0
	bne .Lmv_cont
	bl _gi_disable_IRQVcount	@; si nFrames = 0, desactivar interrupciones,
	bl _gi_actualizarVvis		@;	actualizar bits de ventanas visibles,
	bl _gg_actualiza_sprites
  @;bl _gg_actualizarZoomSpr	@; transferir factor zoom al grupo rot./esc. 0
  @;bl _gg_desbloquearVisibles	@;  desbloquear los sprites de ventanas visibles
	b .Lmv_fin					@;	y salir de esta RSI
.Lmv_cont:
	sub r1, #1
	strh r1, [r0]				@; _gi_nFrames--;
	
	@; actualizar posición X de las ventanas
	ldr r0, =_gi_orgX
	ldrh r2, [r0]				@; R2 = origen X de fondos de ventanas
	ldr r3, =_gi_orgX_ant
	ldrh r8, [r3]				@; R8 = _gi_orgX_ant
	cmp r8, r2
	beq .Lmv_fin_orgX			@; si orgX = orgX_ant, final ajuste orgX
	sub r9, r2, r8				@; R9 = orgX - orgX_ant
	mul r0, r9, r1 				@; R0 = (orgX - orgX_ant) * nFrames
	sub r2, r0, asr #5			@; R2 = orgX - ((orgX - orgX_ant) * nFrames)/32
	mov r9, r2, lsl #8			@; convertir a coma fija 24.8
	mov r0, #0x04000000
	add r0, #0x28				@; R0 es dirección de BG2X
	str r9, [r0]
	str r9, [r0, #0x10]			@; actualizar fondos 2 y 3
	cmp r1, #0
	bne .Lmv_fin_orgX			@; si nFrames != 0, final ajuste orgX
	strh r2, [r3]				@; sino, _gi_orgX_ant = _gi_orgX;
.Lmv_fin_orgX:

	@; actualizar posición Y de las ventanas
	ldr r0, =_gi_orgY
	ldrh r2, [r0]				@; R2 = origen Y de fondos de ventanas
	ldr r3, =_gi_orgY_ant
	ldrh r8, [r3]				@; R8 = _gi_orgY_ant
	cmp r8, r2
	beq .Lmv_fin_orgY			@; si orgY = orgY_ant, final ajuste orgY
	sub r9, r2, r8
	mul r0, r9, r1 
	sub r2, r0, asr #5			@; R2 = orgY - ((orgY - orgY_ant) * nFrames)/32
	mov r9, r2, lsl #8			@; convertir a coma fija 24.8
	mov r0, #0x04000000
	add r0, #0x2C				@; R0 es dirección de BG2Y
	str r9, [r0]
	str r9, [r0, #0x10]			@; actualizar fondos 2 y 3
	cmp r1, #0
	bne .Lmv_fin_orgY			@; si nFrames != 0, final ajuste orgY
	strh r2, [r3]				@; sino, _gi_orgY_ant = _gi_orgY;
.Lmv_fin_orgY:

	@; actualizar zoom de las ventanas
	ldr r0, =_gi_zoom
	ldrh r2, [r0]				@; R2 = zoom actual de ventanas
	ldr r3, =_gi_zoom_ant
	ldrh r8, [r3]				@; R8 = _gi_zoom_ant
	cmp r8, r2
	beq .Lmv_fin				@; si zoom = zoom_ant, final RSI
	sub r9, r2, r8
	mul r0, r9, r1
	sub r2, r0, lsr #5			@; R2 = zoom - ((zoom - zoom_ant) * nFrames)/32
	mov r0, #0x04000000
	add r0, #0x20				@; R0 es dirección de BG2PA
	strh r2, [r0]				@; actualizar PA y PD del fondo 2
	strh r2, [r0, #0x06]
	add r0, #0x10				@; R0 es dirección de BG3PA
	strh r2, [r0]				@; actualizar PA y PD del fondo 3
	strh r2, [r0, #0x06]
	cmp r1, #0
	bne .Lmv_fin				@; si nFrames != 0, final RSI
	strh r2, [r3]				@; sino, _gi_zoom_ant = _gi_zoom;

.Lmv_fin:
	pop {r0-r3, r8-r9, pc}



	@; _gi_ajustarVentanas: función auxiliar para iniciar el ajuste del scroll
	@;						y el zoom de las ventanas según el zócalo actual y
	@;						el factor de zoom actual
	@;	parámetro R0: 	=0 -> activar animación solo si es necesario
	@;					=1 -> forzar inicio de animación
_gi_ajustarVentanas:
	push {r0-r12, lr}

	mov r12, r0					@; R12 preservará el parámetro
	ldr r0, =_gi_za
	ldr r1, [r0]				@; R1 = _gi_za
	and r2, r1, #0x03			@; R2 es zmod4 = _gi_za & 3;
	mov r3, r1, lsr #2			@; R3 es zdiv4 = _gi_za >> 2;
	ldr r0, =_gi_zoom
	ldrh r4, [r0]				@; R4 = _gi_zoom
	@;if (_gi_zoom == 1024)
	@;	{ d_orgX = 0; d_orgY = 0; }	// zoom mínimo (1/4) -> no hay scroll
	cmp r4, #1024
	bne .LaS_else1_1
	mov r6, #0					@; R6 es d_orgX (= 0 para zoom mínimo)
	mov r7, #0					@; R7 es d_orgY (= 0 para zoom mínimo)
	b .LaS_finif1
	@;else if (_gi_zoom == 512)
	@;	{ d_orgX = (zmod4 / 2) * 512;	// zoom intermedio (1/2) -> scroll en
	@;	  d_orgY = (zdiv4 / 2) * 384;	// 4 cuadrantes
	@;	}
.LaS_else1_1:
	cmp r4, #512
	bne .LaS_else1_2
	mov r6, r2, lsr #1			@; elimina bit de menos peso de zmod4
	mov r6, r6, lsl #9			@; multiplicar por 512
	mov r8, r3, lsr #1			@; elimina bit de menos peso de zdiv4
	mov r9, #384
	mul r7, r8, r9
	b .LaS_finif1
	@;else {	d_orgX = zmod4 * 256;	// zoom máximo (1/1) -> scroll centrado
	@;		d_orgY = zdiv4 * 192;	}	// en cada ventana
.LaS_else1_2:
	mov r6, r2, lsl #8
	mov r9, #192
	mul r7, r3, r9
.LaS_finif1:
	ldr r10, =_gi_orgX
	ldrh r8, [r10]				@; R8 es _gi_orgX
	ldr r11, =_gi_orgY
	ldrh r9, [r11]				@; R9 es _gi_orgY
	@;if ((d_orgX != _gi_orgX) || (d_orgY != _gi_orgY))
	@;{
	cmp r6, r8					@; en caso de que haya cambio de ventana en foco
	bne .LaS_if2				@; pero no sea necesario mover ventanas,
	cmp r7, r9					@; saltar directamente al final sin activar
	beq .LaS_finif2				@; animación (desplazamiento rápido de _gi_za)
.LaS_if2:
	@;		// iniciar un nuevo scroll
	ldr r5, =_gi_orgX_ant
	strh r8, [r5]				@;	_gi_orgX_ant = _gi_orgX;
	ldr r5, =_gi_orgY_ant
	strh r9, [r5]				@;	_gi_orgY_ant = _gi_orgY;
	strh r6, [r10]				@;	_gi_orgX = d_orgX;
	strh r7, [r11]				@;	_gi_orgY = d_orgY;
	mov r12, #1					@; forzar inicio de animación
.LaS_finif2:
	cmp r12, #1
	bne .LaS_finif3
	ldr r0, =_gi_nFrames
	mov r9, #32
	strh r9, [r0]				@;	_gi_nFrames = 32;
  @;bl _gg_bloquearVisibles		@; bloquear los sprites de ventanas visibles
    bl _gg_ocultar_sprites_OAM
	bl _gi_enable_IRQVcount		@; reactivar interrupciones Vcount
	@;}
.LaS_finif3:
	
	pop {r0-r12, pc}




	.global _gi_redibujarZocalo
	@; R0 = seleccionar
_gi_redibujarZocalo:
	push {r0-r5, lr}

	ldr r5, =_gi_za
	ldr r1, [r5]				@; R1 = _gi_za
	@;color = (seleccionar == 0 ? ((_gi_za == 0) || (_gd_pcbs[_gi_za].PID != 0) ? 0 : 3) : 2);
	mov r4, #2					@; R4 es variable color (por defecto = 2)
	cmp r0, #0
	bne .LrZ_cont				@; si seleccionar = 1, continuar con color = 2
	mov r4, #3					@; si zócalo vacío, color = 3
	cmp r1, #0
	beq .LrZ_col0				@; si _gi_za = 0, salta a fijar color a 0
	ldr r0, =_gd_pcbs
	mov r2, #24
	mul r3, r2, r1				@; R3 = offset _gd_pcbs[_gi_za]
	ldr r2, [r0, r3]			@; R2 = _gd_pcbs[_gi_za].PID
	cmp r2, #0
	beq .LrZ_cont				@; si PID = 0, continua con color = 3
.LrZ_col0:
	mov r4, #0					@; color = 0 (proceso activo)
.LrZ_cont:
	mov r5, r1
	@;_gg_escribirLineaTabla(_gi_za, color);
	mov r0, r1
	mov r1, r4
	bl _gg_escribirLineaTabla
	@;_gg_generarMarco(_gi_za, color);
	mov r0, r5
	mov r1, r4
	bl _gg_generarMarco
	
	pop {r0-r5, pc}




	.global _gi_controlInterfaz
	@; R0 = key
_gi_controlInterfaz:
	push {r0-r4, lr}
	
	ldr r4, =_gi_nFrames
	ldrh r3, [r4]				@; R3 es _gi_nFrames
	cmp r3, #0					@; ignorar pulsaciones mientras no se haya
	bne .LcI_finswitch			@; terminado un movimiento de ventanas en curso
	
	mov r4, r0					@; R4 guardará el parámetro key
	ldr r1, =_gi_za
	ldr r2, [r1]				@; R2 = _gi_za
	@;switch (key)
	@;{
	@;case KEY_UP:
	tst r4, #0x0040
	beq .LcI_cont1
	@;	if (_gi_za >= 4)
	cmp r2, #4
	blo .LcI_finswitch
	@;	{
	mov r0, #0
	bl _gi_redibujarZocalo
	sub r2, #4					@; subir la selección de zócalo
	str r2, [r1]				@; _gi_za -= 4;
	mov r0, #1
	bl _gi_redibujarZocalo
	mov r0, #0
	bl _gi_ajustarVentanas
	@;	}
	@;	break;
	b .LcI_finswitch
.LcI_cont1:
	@;case KEY_DOWN:
	tst r4, #0x0080
	beq .LcI_cont2
	@;	if (_gi_za < 12)
	cmp r2, #12
	bhs .LcI_finswitch
	@;	{
	mov r0, #0
	bl _gi_redibujarZocalo
	add r2, #4					@; bajar la selección de zócalo
	str r2, [r1]				@; _gi_za += 4;
	mov r0, #1
	bl _gi_redibujarZocalo
	mov r0, #0
	bl _gi_ajustarVentanas
	@;	}
	@;	break;
	b .LcI_finswitch
.LcI_cont2:
	@;case KEY_LEFT:
	tst r4, #0x0020
	beq .LcI_cont3
	@;	if ((_gi_za % 4) >= 1)
	and r3, r2, #0x03			@; R3 = _gi_za % 4
	cmp r3, #1
	blo .LcI_finswitch
	@;	{
	mov r0, #0
	bl _gi_redibujarZocalo
	sub r2, #1					@; selección de zócalo izquierdo
	str r2, [r1]				@; _gi_za -= 1;
	mov r0, #1
	bl _gi_redibujarZocalo
	mov r0, #0
	bl _gi_ajustarVentanas
	@;	}
	@;	break;
	b .LcI_finswitch
.LcI_cont3:
	@;case KEY_RIGHT:
	tst r4, #0x0010
	beq .LcI_cont4
	@;	if ((_gi_za % 4) < 3)
	and r3, r2, #0x03			@; R3 = _gi_za % 4
	cmp r3, #3
	bhs .LcI_finswitch
	@;	{
	mov r0, #0
	bl _gi_redibujarZocalo
	add r2, #1					@; selección de zócalo derecho
	str r2, [r1]				@; _gi_za += 1;
	mov r0, #1
	bl _gi_redibujarZocalo
	mov r0, #0
	bl _gi_ajustarVentanas
	@;	}
	@;	break;
	b .LcI_finswitch
.LcI_cont4:
	ldr r1, =_gi_zoom
	ldrh r2, [r1]				@; R2 = _gi_zoom
	ldr r0, =_gi_zoom_ant
	ldrh r3, [r2]				@; R3 = _gi_zoom_ant
	cmp r2, r3					@; si los valores de zoom son iguales,
	beq .LcI_finswitch			@; ignorar teclas de cambio de zoom
	@;case KEY_START:
	tst r4, #0x0008
	beq .LcI_cont5
	strh r2, [r0]				@; _gi_zoom_ant = _gi_zoom;
	mov r2, #256
	strh r2, [r1]				@; _gi_zoom = 1 << 8;
	mov r0, #1
	bl _gi_ajustarVentanas
	@;	break;
	b .LcI_finswitch
.LcI_cont5:
	@;case KEY_L:
	tst r4, #0x0200
	beq .LcI_cont6
	@;	if (_gi_zoom > 256)
	cmp r2, #256
	bls .LcI_finswitch
	@;	{
	strh r2, [r0]				@; _gi_zoom_ant = _gi_zoom;
	mov r2, r2, lsr #1			@; dividir por 2 el factor de zoom actual
	strh r2, [r1]				@; _gi_zoom >>= 1;
	mov r0, #1
	bl _gi_ajustarVentanas
	@;	break;
	b .LcI_finswitch
.LcI_cont6:
	@;case KEY_R:
	tst r4, #0x0100
	beq .LcI_finswitch
	@;	if (_gi_zoom < 1024)
	cmp r2, #1024
	bhs .LcI_finswitch
	@;	{
	strh r2, [r0]				@; _gi_zoom_ant = _gi_zoom;
	mov r2, r2, lsl #1			@; multiplicar por 2 el factor d zoom actual
	strh r2, [r1]				@; _gi_zoom <<= 1;
	mov r0, #1
	bl _gi_ajustarVentanas
	@;	break;
	@;}
.LcI_finswitch:

	pop {r0-r4, pc}

.end
