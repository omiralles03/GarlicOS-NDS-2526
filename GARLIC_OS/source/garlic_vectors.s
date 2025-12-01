@;==============================================================================
@;
@;	"garlic_vector.s":	vector de direcciones de rutinas del API de GARLIC 2.0
@;
@;==============================================================================

.section .vectors,"a",%note


APIVector:						@; Vector de direcciones de rutinas del API
	.word	_ga_pid				@; (código de rutinas en "garlic_itcm_api.s")
	.word	_ga_random
	.word	_ga_divmod
	.word	_ga_divmodL
	.word	_ga_printf
	.word	_ga_printchar
	.word	_ga_printmat
	.word	_ga_delay
	.word	_ga_clear
	@; Vectores progG
    .word   _ga_spriteSet
    .word   _ga_spriteMove
    .word   _ga_spriteShow
    .word   _ga_spriteHide
	.word   _ga_clearScreen
	@; Vectores progP
	.word 	_ga_send			@; Nova entrada per GARLIC_send
	.word	_ga_receive			@; Nova entrada per GARLIC_receive
	@; Vectores progM
	.word 	_ga_malloc			@; direccion a func. adicional 1 progM
	.word	_ga_free			@; direccion a func. adicional 2 progM

.end
