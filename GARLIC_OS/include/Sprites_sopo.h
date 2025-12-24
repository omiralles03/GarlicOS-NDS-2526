/*------------------------------------------------------------------------------

	$Id: Sprites_sopo.h $

	Declaraciones de funciones globales de 'Sprites_sopo.s'

------------------------------------------------------------------------------*/

extern void SPR_actualiza_sprites(u16* base, unsigned char limite);
extern void SPR_crea_sprite(unsigned char indice, unsigned char forma,
								unsigned char tam, unsigned short baldosa);
extern void SPR_muestra_sprite(unsigned char indice);
extern void SPR_oculta_sprite(unsigned char indice);
extern void SPR_oculta_sprites(unsigned char limite);
extern void SPR_mueve_sprite(unsigned char indice, short px, short py);
extern void SPR_fija_prioridad(unsigned char indice, unsigned char prioridad);
extern void SPR_activa_rotacionEscalado(unsigned char indice,
														unsigned char grupo);
extern void SPR_desactiva_rotacionEscalado(unsigned char indice);
extern void SPR_fija_escalado(unsigned char igrp,
										unsigned short sx, unsigned short sy);
