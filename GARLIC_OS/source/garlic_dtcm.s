@;==============================================================================
@;
@;	"garlic_dtcm.s":	zona de datos básicos del sistema GARLIC 1.0
@;						(ver "garlic_system.h" para descripción de variables)
@;
@;==============================================================================

.section .dtcm,"wa",%progbits

	.align 2

	.global _gd_pidz												@; Identificador de proceso + zócalo actual
_gd_pidz:	.word 0

	.global _gd_pidCount											@; Contador global de PIDs
_gd_pidCount:	.word 0

	.global _gd_tickCount											@; Contador global de tics
_gd_tickCount:	.word 0

	.global _gd_seed												@; Semilla para generación de números aleatorios
_gd_seed:	.word 0xFFFFFFFF

	.global _gd_nReady												@; Número de procesos en la cola de READY
_gd_nReady:	.word 0

	.global _gd_qReady												@; Cola de READY (procesos preparados)
_gd_qReady:	.space 16

	.global _gd_pcbs												@; Vector de PCBs de los procesos activos
_gd_pcbs:	.space 16 * 6 * 4

	.global _gd_wbfs												@; Vector de WBUFs de las ventanas disponibles
_gd_wbfs:	.space 4 * (4 + 32)

	.global _gd_stacks												@; Vector de pilas de los procesos activos
_gd_stacks:	.space 15 * 128 * 4

@; -- Variables per la funcionalitat addicional (Sprites) --
    .global _gd_sprites
_gd_sprites: .space 128 * 8     									@; Vector de sprites


@; -- Variables per la funcionalitat addicional (bústies) --

MAILBOX_QUEUE_SIZE = 16												@; Número de posicions de cadascuna de les bústies.

@; Estructura de cada bústia
@; Offset 0: Inici array per la cua (MAILBOX_QUEUE_SIZE * 4 bytes)
@; Offset 64: Posició inici/cap de la cua (head index, int)
@; Offset 68: Posició final/cua de la cua (tail index, int)
@; Offset 72: Comptador de dades (count, int)
MAILBOX_STRUCT_SIZE = (MAILBOX_QUEUE_SIZE * 4) + 4 + 4 + 4			@; Variable del tamany del struct de cada bústia (64 + 4 + 4 + 4 = 76 bytes).

	.global _gd_mailboxes
_gd_mailboxes: .space 8 * MAILBOX_STRUCT_SIZE						@; Vector per les 8 bústies.

.end

