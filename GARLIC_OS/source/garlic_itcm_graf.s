@;==============================================================================
@;
@;	"garlic_itcm_graf.s":	código de rutinas de soporte a la gestión de
@;							ventanas gráficas (versión 1.0)
@;
@;==============================================================================

NVENT	= 4					@; número de ventanas totales
PPART	= 2					@; número de ventanas horizontales o verticales
							@; (particiones de pantalla)
L2_PPART = 1				@; log base 2 de PPART

VCOLS	= 32				@; columnas y filas de cualquier ventana
VFILS	= 24
PCOLS	= VCOLS * PPART		@; número de columnas totales (en pantalla)
PFILS	= VFILS * PPART		@; número de filas totales (en pantalla)

WBUFS_LEN = 36				@; longitud de cada buffer de ventana (32+4)

.section .itcm,"ax",%progbits

	.arm
	.align 2


	.global _gg_escribirLinea
	@; Rutina para escribir toda una linea de caracteres almacenada en el
	@; buffer de la ventana especificada;
	@;Parámetros:
	@;	R0: ventana a actualizar (int v)
	@;	R1: fila actual (int f)
	@;	R2: número de caracteres a escribir (int n)
_gg_escribirLinea:
	push {r3-r6, lr}

        and r3, r0, #L2_PPART   @; R3 = columna = v % PPART
        lsr r4, r0, #L2_PPART   @; R4 = fila = v / PPART

        @; Posicio inicial de V = (fila * VFILS * PCOLS) + (columna * VCOLS)
        mov r5, #VFILS
        mul r5, r4, r5          @; R5 = fila * VFILS
        mov r6, #PCOLS
        mul r5, r5, r6          @; R5 = (fila * VFILS) * PCOLS
        mov r6, #VCOLS
        mla r5, r3, r6, r5      @; R5 =  (columna * VCOLS) + (fila * VFILS * PCOLS)

        @; Fila f on es vol escriure (Pos. ini V + offset f)
        mov r6, #PCOLS
        mla r5, r1, r6, r5      @; R5 = Pos. ini V + (fila * PCOLS)

        @; Obtenir la direccio on es vol escriure en la VRAM
        ldr r3, =bg2map
        ldr r3, [r3]            @; Carregar adreca base VRAM (0x06000000)
        lsl r5, #1              @; R5 *= 2 (cada baldosa son 2 bytes (halfword))
        add r3, r5              @; R3 = VRAM = bg2 + Offset f en V

        @; Obtenir Buffer pChars[]
        mov r5, #WBUFS_LEN
        mul r6, r0, r5          @; R6 = desplacament a la pos. ini de _gd_wbfs en V
        ldr r4, =_gd_wbfs       @; R4 = adreca del vector _gd_wbfs
        add r4, r6              @; R4 = _gd_wbfsp[v] (@_gd_wbfs + WBUFS_LEN*V)
        add r4, #4              @; R4 = pChars (pControl son 4 bytes)

        @; Bucle per escriure
        mov r5, #0              @; R5 = index de chars
    .Lloop:
        cmp r5, r2
        bhs .Lend_loop          @; Sortir si r5 >= n

        ldrb r6, [r4, r5]       @; R6 = char ASCII (_gd_wbfs[v].pChars[r5])
        sub r6, #32             @; Convertir ASCII a index Baldosa
        strh r6, [r3]           @; Guardar baldosa a VRAM[R3]
        
        add r3, #L2_PPART       @; Incrementar VRAM
        add r5, #1              @; Incrementar index chars
        b .Lloop

    .Lend_loop:
    pop {r3-r6, pc}


	.global _gg_desplazar
	@; Rutina para desplazar una posición hacia arriba todas las filas de la
	@; ventana (v), y borrar el contenido de la última fila
	@;Parámetros:
	@;	R0: ventana a desplazar (int v)
_gg_desplazar:
	push {lr}


	pop {pc}


.end

