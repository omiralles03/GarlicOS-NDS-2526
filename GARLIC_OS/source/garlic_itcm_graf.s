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
MASK_PPART = 3                          @; Mascara per fer Columna % 4

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

        and r3, r0, #MASK_PPART   @; R3 = columna = v % MASK_PPART
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
        lsl r2, r2, #1
    .Lloop:
        cmp r5, r2
        bhs .Lend_loop          @; Sortir si r5 >= n

        @; Fase 2: pChars es short -> halfword
        ldrh r6, [r4, r5]       @; R6 = char ASCII (_gd_wbfs[v].pChars[r5])
        sub r6, #32             @; Convertir ASCII a index Baldosa
        strh r6, [r3]           @; Guardar baldosa a VRAM[R3]
        
        add r3, #2              @; Incrementar VRAM (2 bytes)
        add r5, #2              @; Incrementar index chars
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

        and r1, r0, #MASK_PPART   @; R1 = columna = v % MASK_PPART
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
	push {r4-r8, lr}

            mov r4, r0
            mov r5, r1
			
            ldr r6, =_gd_pcbs
            mov r7, #24                 @; PC 6*4bytes
            mla r8, r4, r7, r6          @; R8 = adreca _gd_pcbs[z]

            ldr r0, [r8, #0]            @; R0 = PID a _gd_pcbs offset 0
            cmp r0, #0
            beq .Lzero_zocalo           @; Si PID = 0 mirar si zocalo es del OS

            .LwirteData:
                sub sp, #8              @; Buffer a la pila per el string del PID (4 chars + centinela = 5 bytes)
                mov r0, sp              @; Desti del string
                mov r1, #4              @; Max 4 digits
                ldr r2, [r8]            @; PID
                bl _gs_num2str_dec

                mov r0, sp              @; PID en string
                add r1, r4, #4          @; Fila = z + 4 
                mov r2, #5              @; Columna del PID
                mov r3, r5              @; Color
                bl _gs_escribirStringSub
                add sp, #8              @; Alliberar espai reservat

                add r0, r8, #16         @; R0 = dir. keyName a _gd_pcbs offset 16
                add r1, r4, #4          @; Fila = z + 4 
                mov r2, #9              @; Columna del keyName
                mov r3, r5              @; Color
                bl _gs_escribirStringSub
                b .Lnum_zocalo

            .Lzero_zocalo:
                cmp r4, #0                  @; Si zocalo = 0 escriure GARL
                beq .LwirteData
                
                @; Si zocalo != 0, esborrar linia
                ldr r0, =blankPID           @; R0 = "    "
                add r1, r4, #4              @; Fila = z + 4 
                mov r2, #4                  @; Columna del PID
                mov r3, r5                  @; Color
                bl _gs_escribirStringSub    @; Esborrar PID

                ldr r0, =blankPID
                add r1, r4, #4
                mov r2, #9					@; Columna del keyName
                mov r3, r5
                bl _gs_escribirStringSub    @; Esborrar keyName

            .Lnum_zocalo:
                sub sp, #8              @; Buffer a la pila per el string del Zocalo (2 digits + centinela = 3 bytes)
                mov r0, sp              @; Desti del string
                mov r1, #3              @; Max 2 digits + centinela
                mov r2, r4              @; R2 = z
                bl _gs_num2str_dec

                mov r0, sp              @; Zocalo en string
                add r1, r4, #4          @; Fila = z + 4 
                mov r2, #1              @; Columna del Zocalo
                mov r3, r5              @; Color
                bl _gs_escribirStringSub
                add sp, #8              @; Alliberar espai reservat

	pop {r4-r8, pc}



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
	push {r4-r7, lr}

        ldr r4, [sp, #20]       @; 4 * 5 regs (r4-r7 + lr)

        and r5, r4, #MASK_PPART   @; R5 = columna = v % MASK_PPART
        lsr r6, r4, #L2_PPART   @; R6 = fila = v / PPART

        @; Posicio inicial de V = (fila * VFILS * PCOLS) + (columna * VCOLS)
        mov r7, #VFILS
        mul r7, r6, r7          @; R7 = fila * VFILS
        mov r4, #PCOLS
        mul r7, r4, r7          @; R7 = (fila * VFILS) * PCOLS
        mov r4, #VCOLS
        mla r7, r5, r4, r7      @; R7 =  (columna * VCOLS) + (fila * VFILS * PCOLS)

        mov r4, #PCOLS
        mla r7, r1, r4, r7      @; R7 + vy * PCOLS
        add r7, r0              @; R7 + vx

        @; Obtenir la direccio de la VRAM
        ldr r5, =0x06000000
        lsl r7, #1              @; R7 *= 2 (cada baldosa son 2 bytes (halfword))
        add r5, r7              @; R5 = VRAM + Offset Vxy

        lsl r3, #7              @; R3 = color * 128
        add r6, r2, r3          @; R6 = char + color
        strh r6, [r5]           @; Escriure color a la VRAM

	pop {r4-r7, pc}



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
	push {r4-r8, lr}
 
		ldr r4, [sp, #24]       @; 4 * 6 regs (r4-r8 + lr)

		and r5, r4, #MASK_PPART   @; R5 = columna = v % MASK_PPART
		lsr r6, r4, #L2_PPART   @; R6 = fila = v / PPART

		@; Posicio inicial de V = (fila * VFILS * PCOLS) + (columna * VCOLS)
		mov r7, #VFILS
		mul r7, r6, r7          @; R7 = fila * VFILS
		mov r4, #PCOLS
		mul r7, r4, r7          @; R7 = (fila * VFILS) * PCOLS
		mov r4, #VCOLS
		mla r7, r5, r4, r7      @; R7 =  (columna * VCOLS) + (fila * VFILS * PCOLS)

		mov r4, #PCOLS
		mla r7, r1, r4, r7      @; vy * PCOLS + R7
		add r7, r0              @; R7 + vx

		@; Obtenir la direccio de la VRAM
		ldr r5, =0x06000000
		lsl r7, #1              @; R7 *= 2 (cada baldosa son 2 bytes (halfword))
		add r5, r7              @; R5 = VRAM + Offset Vxy
		
		mov r0, #PCOLS
		lsl r0, #1              @; R0 = PCOLS * 2
		lsl r3, #7              @; R3 = color * 128

		mov r4, #0              @; R4 = i (files 0..7)
		.Lrow_loop:
			cmp r4, #8
			bge .Lend_row

			mov r6, #0          @; R6 = j (columnes 0..7)
			.Lcol_loop:
				cmp r6, #8
				bge .Lnext_row

				mov r1, #8
				mla r7, r4, r1, r6      @; R7 = i*8 + j
				ldrb r8, [r2, r7]       @; R8 = m[i][j]
				
				cmp r8, #0
				beq .Lskip_char			@; No pintar ni escriure si es espai en blanc

				sub r8, #32             @; R8 = codi ASCII
				add r8, r3              @; codi amb color
				
				mov r1, #2
				mla r7, r6, r1, r5      @; R7 = j*2 + VRAM
				strh r8, [r7]           @; Guardar m[i][j] a VRAM
				
				.Lskip_char:
				add r6, #1              @; j++
				b .Lcol_loop
				
			.Lnext_row:
				add r5, r0              @; Seguent posicio VRAM
				add r4, #1              @; i++
				b .Lrow_loop
		.Lend_row:
		
        pop {r4-r8, pc} 


	.global _gg_rsiTIMER2
	@; Rutina de Servicio de Interrupción (RSI) para actualizar la representa-
	@; ción del PC actual.
_gg_rsiTIMER2:
	push {r0-r5, lr}

            @; 
            sub sp, #12                     @; Reservar espai per string "XXXXXXXX\0" (8+1 bytes)
            ldr r4, =_gd_pcbs
            mov r5, #0                      @; Zocalo actual

            .Lloop_rsi:
                ldr r0, [r4, #0]            @; R0 = PID
                cmp r0, #0
                bne .LupdatePC
                cmp r5, #0                  @; Si PID i Zocalo = 0, actualizar sempre (OS)
                beq .LupdatePC

                ldr r0, =blankPC            @; R0 = "        "
                add r1, r5, #4              @; Fila = z + 4 
                mov r2, #14                 @; Columna PC
                mov r3, #0                  @; Color blanc
                bl _gs_escribirStringSub
                b .Lcontinue_rsi

            .LupdatePC:
                @; Convertir PC a Hexa
                mov r0, sp                  @; Buffer desti
                mov r1, #9                  @; 8 digits hexa + sentinella
                ldr r2, [r4, #4]            @; R2 = PC (PCB offset 4)
                bl _gs_num2str_hex

                @; Escriure el PC en Hexa a la taula
                mov r0, sp                  @; Buffer hexa
                add r1, r5, #4              @; Fila = z + 4 
                mov r2, #14                 @; Columna del PC
                mov r3, #0                  @; Color
                bl _gs_escribirStringSub

            .Lcontinue_rsi:
                add r4, #24                 @; PCB del seguent zocalo
                add r5, #1                  @; z++
                cmp r5, #16
                blo .Lloop_rsi              @; While z < 16

                add sp, #12                 @; Alliberar espai reservat
                
	pop {r0-r5, pc}

.end

