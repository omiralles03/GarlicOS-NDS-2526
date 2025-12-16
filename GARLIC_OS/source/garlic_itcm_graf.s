@;==============================================================================
@;
@;	"garlic_itcm_graf.s":	código de rutinas de soporte a la gestión de
@;							ventanas gráficas (versión 1.0)
@;
@;==============================================================================

NVENT	= 16					@; número de ventanas totales
PPART	= 4					@; número de ventanas horizontales o verticales
							@; (particiones de pantalla)
L2_PPART = 2				@; log base 2 de PPART

VCOLS	= 32				@; columnas y filas de cualquier ventana
VFILS	= 24
PCOLS	= VCOLS * PPART		@; número de columnas totales (en pantalla)
PFILS	= VFILS * PPART		@; número de filas totales (en pantalla)

WBUFS_LEN = 68				@; longitud de cada buffer de ventana (32+4)

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
        mul r5, r6, r5          @; R5 = (fila * VFILS) * PCOLS
        mov r6, #VCOLS
        mla r5, r3, r6, r5      @; R5 =  (columna * VCOLS) + (fila * VFILS * PCOLS)

        @; Fila f on es vol escriure (Pos. ini V + offset f)
        mov r6, #PCOLS
        mla r5, r1, r6, r5      @; R5 = Pos. ini V + (fila * PCOLS)

        @; Obtenir la direccio on es vol escriure en la VRAM
        ldr r3, =0x06000000		@; Carregar adreca base VRAM (0x06000000)
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
        
        add r3, #2       		@; Incrementar VRAM (2 bytes)
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
	push {r1-r7, lr}

        and r1, r0, #L2_PPART   @; R1 = columna = v % PPART
        lsr r2, r0, #L2_PPART   @; R2 = fila = v / PPART

        @; Posicio inicial de V = (fila * VFILS * PCOLS) + (columna * VCOLS)
        mov r3, #VFILS
        mul r3, r2, r3          @; R3 = fila * VFILS
        mov r4, #PCOLS
        mul r3, r4, r3          @; R3 = (fila * VFILS) * PCOLS
        mov r4, #VCOLS
        mla r3, r1, r4, r3      @; R3 =  (columna * VCOLS) + (fila * VFILS * PCOLS)

        @; Obtenir la direccio de la VRAM
        ldr r1, =0x06000000		@; Carregar adreca base VRAM (0x06000000)    
        lsl r3, #1              @; R3 *= 2 (cada baldosa son 2 bytes (halfword))
        add r1, r3              @; R1 = VRAM = bg2 + Offset V

        @; Punters per el scroll
        mov r4, #PCOLS
        lsl r4, #1              @; R4 = PCOLS * 2 (Salt de linia en bytes)

        add r2, r1, r4          @; R2 = Fila Origen (Fila i+1)
                                @; R1 = Fila Desti (Fila i)
        
        mov r3, #VFILS
        sub r3, #1              @; R3 = Delimitant de Files (VFILS - 1)

    .Lscroll_LineLoop:
        cmp r3, #0
        ble .Lclear_LastLine    @; Si R3 = 0 s'han copiat totes les linies

        mov r5, #0              @; R5 = index columna
        mov r6, #VCOLS          @; R6 = index columnes restants

    .Lscroll_CopyLoop:
        cmp r6, #0
        ble .Lscroll_CopyEnd    @; Si R6 = 0 s'ha copiat la linia actual

        ldrh r7, [r2, r5]       @; R7 = Halfword Origen (Fila i+1)
        strh r7, [r1, r5]       @; Guardar Halfword al Desti (Fila i)

        add r5, #2              @; R5 = seguent columna (2 bytes)
        sub r6, #1              @; Decrementar comptador de columnes
        b .Lscroll_CopyLoop

    .Lscroll_CopyEnd:
        add r1, r4              @; R1 = avancar Desti (Fila i)
        add r2, r4              @; R2 = avancar Origen (Fila i+1)
        sub r3, #1              @; Decrementar comptador de linies
        b .Lscroll_LineLoop

    .Lclear_LastLine:
        mov r3, #0              @; R3 = Espai Blanc
        mov r5, #0              @; R5 = index columna
        mov r6, #VCOLS          @; R6 = index columnes restants
        
    .Lclear_Loop:
        cmp r6, #0
        ble .Lend_scroll

        strh r3, [r1, r5]       @; Escriure espai blanc en la columna
        add r5, #2              @; R5 = seguent columna (2 bytes)
        sub r6, #1              @; Decrementar comptador de columnes
        b .Lclear_Loop

    .Lend_scroll:
	pop {r1-r7, pc}

	.global _gg_escribirLineaTabla
	@; escribe los campos básicos de una linea de la tabla correspondiente al
	@; zócalo indicado por parámetro con el color especificado; los campos
	@; son: número de zócalo, PID, keyName y dirección inicial
	@;Parámetros:
	@;	R0 (z)		->	número de zócalo
	@;	R1 (color)	->	número de color (0..3)
_gg_escribirLineaTabla:
	push {lr}


	pop {pc}



	.global _gg_escribirCar
	@; escribe un carácter (baldosa) en la posición de la ventana indicada,
	@; con un color concreto;
	@;Parámetros:
	@;	R0 (vx)		->	coordenada x de ventana (0..31)
	@;	R1 (vy)		->	coordenada y de ventana (0..23)
	@;	R2 (car)	->	código del carácter, como número de baldosa (0..127)
	@;	R3 (color)	->	número de color del texto (0..3)
	@; pila (vent)	->	número de ventana (0..15)
_gg_escribirCar:
	push {lr}
	

	pop {pc}



	.global _gg_escribirMat
	@; escribe una matriz de 8x8 carácteres a partir de una posición de la
	@; ventana indicada, con un color concreto;
	@;Parámetros:
	@;	R0 (vx)		->	coordenada x inicial de ventana (0..31)
	@;	R1 (vy)		->	coordenada y inicial de ventana (0..23)
	@;	R2 (m)		->	puntero a matriz 8x8 de códigos ASCII (dirección)
	@;	R3 (color)	->	número de color del texto (0..3)
	@; pila	(vent)	->	número de ventana (0..15)
_gg_escribirMat:
	push {lr}
	

	pop {pc}



	.global _gg_rsiTIMER2
	@; Rutina de Servicio de Interrupción (RSI) para actualizar la representa-
	@; ción del PC actual.
_gg_rsiTIMER2:
	push {lr}


	pop {pc}

.end

