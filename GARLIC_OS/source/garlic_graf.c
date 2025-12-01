/*------------------------------------------------------------------------------
        "garlic_graf.c" : fase 1 / programador G

        Funciones de gestión de las ventanas de texto (gráficas), para
GARLIC 1.0
------------------------------------------------------------------------------*/
#include <nds.h>

#include <garlic_font.h>   // definición gráfica de caracteres
#include <garlic_system.h> // definición de funciones y variables de sistema
#include <icons.h>
#include <Sprites_sopo.h>

/* definiciones para realizar cálculos relativos a la posición de los
caracteres dentro de las ventanas gráficas, que pueden ser 4 o 16 */
#define NVENT 4 // número de ventanas totales
#define PPART 2 // número de ventanas horizontales (particiones de pantalla)

#define VCOLS 32 // columnas y filas de cualquier ventana
#define VFILS 24
#define PCOLS VCOLS *PPART // número de columnas totales
#define PFILS VFILS *PPART // número de filas totales

int bg2, bg3;

/* _gg_generarMarco: dibuja el marco de la ventana que se indica por parámetro*/
void _gg_generarMarco(int v) {

  // Fila inicial de la particio
  int Fp = (v / PPART) * VFILS;
  // Columna inicial de la particio
  int Cp = (v % PPART) * VCOLS;

  // Punter a la base del mapa 3 en la finestra v
  // bgGetMapPtr retorna la coordenada (0,0)
  // Calcular offset per accedir a la matriu 2D en array 1D
  int offset_base = Fp * PCOLS + Cp;
  u16 *map_Ptr = (u16 *)bgGetMapPtr(bg3) + offset_base;

  for (int Fv = 0; Fv < VFILS; Fv++) {
    for (int Fc = 0; Fc < VCOLS; Fc++) {
      int idx_font = 0; // Grafic Buit

      // Corners
      if (Fv == 0 && Fc == 0) {
        idx_font = 103; // Superior Esquerra
      } else if (Fv == 0 && Fc == VCOLS - 1) {
        idx_font = 102; // Superior Dreta
      } else if (Fv == VFILS - 1 && Fc == 0) {
        idx_font = 100; // Inferior Esquerra
      } else if (Fv == VFILS - 1 && Fc == VCOLS - 1) {
        idx_font = 101; // Inferior Dreta
      }

      // Edges
      else if (Fv == 0) {
        idx_font = 99; // Superior
      } else if (Fv == VFILS - 1) {
        idx_font = 97; // Inferior
      } else if (Fc == 0) {
        idx_font = 96; // Esquerra
      } else if (Fc == VCOLS - 1) {
        idx_font = 98; // Dreta
      }

      // Guardar el grafic a la posicio correcta
      // Punt inicial map_Ptr + offset
      int offset_rel = Fv * PCOLS + Fc;
      map_Ptr[offset_rel] = idx_font;
    }
  }
}

/* _gg_iniGraf: inicializa el procesador gráfico A para GARLIC 1.0 */
void _gg_iniGrafA() {

  // Inicialitzar procesador A mode 5 en pantalla superior
  // Adicional: Inicialitzar el display de Sprites
  videoSetMode(MODE_5_2D | DISPLAY_BG2_ACTIVE | DISPLAY_BG3_ACTIVE | DISPLAY_SPR_1D_LAYOUT | DISPLAY_SPR_ACTIVE);
  vramSetBankA(VRAM_A_MAIN_BG_0x06000000);
  lcdMainOnTop();

  // Inicialitzacio dels fons BG2 i BG3 en ExRotation 512x512

  // MapBase: 64x64 posicions * 2 bytes/posicio = 8KB
  // Offset mapBase (2KB) = 8/2 = 4

  // TileBase: 128 baldoses * 8x8 px/baldosa * 1 byte/px = 8KB
  // Offset tileBase (16KB) = 0 -> No arriba a solapar
  bg2 = bgInit(2, BgType_ExRotation, BgSize_ER_512x512, 0, 3);
  bg3 = bgInit(3, BgType_ExRotation, BgSize_ER_512x512, 4, 3);

  // Prioritat bg3 > bg2
  bgSetPriority(bg2, 2);
  bgSetPriority(bg3, 0);

  // Descomprimir i copiar lletres/paleta
  decompress(garlic_fontTiles, bgGetGfxPtr(bg2), LZ77Vram);
  dmaCopy(garlic_fontPal, BG_PALETTE, sizeof(garlic_fontPal));

  // Generar marcos de ventana al fondo 3
  for (int i = 0; i < NVENT; i++) {
    _gg_generarMarco(i);
  }

  // Escalar fondos 2 i 3 a dimensions NDS (reduccio 50%)
  bgSetScale(bg2, 512, 512);
  bgSetScale(bg3, 512, 512);
  bgUpdate();

  // Adicionals: Sprites
  // Assignar el BankE per als Sprites
  vramSetBankE(VRAM_E_MAIN_SPRITE);

  // Descomprimir i copiar icones/paleta
  decompress(iconsTiles, SPRITE_GFX, LZ77Vram);
  dmaCopy(iconsPal, SPRITE_PALETTE, sizeof(iconsPal));

  // Inicialitzar Sprites com a ocults
  SPR_oculta_sprites(128);

  // Inicialitzar _gd_sprites
  for (int i = 0; i < 128; i++) {
      _gd_sprites[i].icon = 0xFF;
      _gd_sprites[i].n = 0xFF;
      _gd_sprites[i].px = 0;
      _gd_sprites[i].py = 0;
      _gd_sprites[i].visible = 0;
      _gd_sprites[i].zocalo = 0xFF;
  }

  // Factor de escalado 50%
  SPR_fija_escalado(0, 128, 128);
}

/* _gg_procesarFormato: copia los caracteres del string de formato sobre el string 
                        resultante, pero identifica los códigos de formato precedidos
                        por '%' e inserta la representación ASCII de los valores 
                        indicados por parámetro.
        Parámetros:
            formato	    ->	string con códigos de formato (ver descripción _gg_escribir);

            val1, val2	->	valores a transcribir, sean número de código ASCII (%c), 
                            un número natural (%d, %x) o un puntero a string (%s);

            resultado	->	mensaje resultante.

        Observación:
                Se supone que el string resultante tiene reservado espacio de
                memoria suficiente para albergar todo el mensaje, incluyendo 
                los caracteres literales del formato y la transcripción a 
                código ASCII de los valores.
*/
void _gg_procesarFormato(char *formato, unsigned int val1, unsigned int val2,
                         char *resultado) {

    int i = 0;
    int val_cmp = 0;     // Comptador de valors usats (0=cap, 1=val1, 2=val2)
    char val_tmp[11];   // Buffer temporal (11 -> 32b + \0)

    for (int j = 0; formato[j] != '\0'; j++) {

        // Copiar caracter literal
        if (formato[j] != '%') {
            resultado[i] = formato[j];
            i++;
        }
        // Evaluar codi format
        else {
            j++;
            char codi = formato[j]; // (c, d, x, s, %)

            unsigned int val_act = 0;
            // Si no es tracta de %
            if (codi != '%') {
				// Si no s'han els dos valors, determinar el valor a usar.
				if (val_cmp < 2) {
					val_act = (val_cmp == 0) ? val1 : val2;
				}
				// En cas contrari ignorar el codi de format
				else {
					codi = 0; // codi erroni
				}
			}

            switch (codi) {
                case 'c':
					resultado[i] = (char)val_act;
					i++;
					val_cmp++;
                    break;

                case 'd':
					_gs_num2str_dec(val_tmp, sizeof(val_tmp), val_act);
                    // Guardar el valor transcrit
                    for (int k = 0; val_tmp[k] != '\0'; k++) {
                        if (val_tmp[k] != ' ') { // No guardar espais en blanc
                            resultado[i] = val_tmp[k];
                            i++;
                        }
                    }
					val_cmp++;
					break;
                case 'x':
					_gs_num2str_hex(val_tmp, sizeof(val_tmp), val_act);
					int ignore0 = 1;
                    // Guardar el valor transcrit
					if (val_act == 0) {
						resultado[i] = '0';
						i++;
					} else {
						for (int k = 0; val_tmp[k] != '\0'; k++) {
							// No guardar espais en blanc fins arribar al primer numero != 0
							if (val_tmp[k] != '0' && ignore0) {
								ignore0 = 0;
							}
							if (!ignore0) {
								resultado[i] = val_tmp[k];
								i++;
							}
						}
					}
					val_cmp++;
					break;
                case 's':
					{ // scope error fix per string_ptr
						char *string_ptr = (char *)val_act;

						for (int k = 0; string_ptr[k] != '\0'; k++) {
							resultado[i] = string_ptr[k];
							i++;
						}
						val_cmp++;
					}
					break;

                case '%':
                    resultado[i] = '%';
                    i++;
                    break;

				default:
					resultado[i] = '%';
                    i++;
					resultado[i] = formato[j];
                    i++;
                    break;
            }
        }
    }
    resultado[i] = '\0';
}

/* _gg_escribir: escribe una cadena de caracteres en la ventana indicada;
        Parámetros:
                formato	->	cadena de formato, terminada con centinela '\0';
                            admite '\n' (salto de línea), '\t' (tabulador, 4 espacios) 
                            y códigos entre 32 y 159 (los 32 últimos son caracteres gráficos), 
                            además de códigos de formato %c, %d, %x y %s (max. 2 códigos por cadena)

                val1	->	valor a sustituir en primer código de formato, si existe 

                val2	->	valor a sustituir en segundo código de formato, si existe
                            - los valores pueden ser un código ASCII (%c), 
                              un valor natural de 32 bits (%d, %x)
                              o un puntero a string (%s)

                ventana ->	número de ventana (de 0 a 3)
*/
void _gg_escribir(char *formato, unsigned int val1, unsigned int val2,
                  int ventana) {
     // Maxim 3 linies de ventana
    char resultado[3 * VCOLS];

    _gg_procesarFormato(formato, val1, val2, resultado); 

    // 16 bits altos: número de línea
    int filaAct = _gd_wbfs[ventana].pControl >> 16;
    // 16 bits bajos: caracteres pendientes
    int numChars = _gd_wbfs[ventana].pControl & 0xFFFF;

    int i = 0;
    char character;

    while ((character = resultado[i]) != '\0') {

        // Tabulacio
        if (character == '\t') {
            // Escriure espais fins la proxima columna en pos % 4
            do {
                _gd_wbfs[ventana].pChars[numChars] = ' ';
                numChars++;
            } while ((numChars < VCOLS) && (numChars % 4 != 0));
        }
		// Caracter literal
        else if(character != '\n' || numChars < VCOLS) {
            _gd_wbfs[ventana].pChars[numChars] = character;
            numChars++;
        }
        // Salt de linia
        if (character == '\n' || numChars == VCOLS) {
            swiWaitForVBlank();
            // Scroll si arribem al final
            if (filaAct == VFILS - 1) {
                _gg_desplazar(ventana);
            }
            // Escriure Linia i reiniciar numChars
            _gg_escribirLinea(ventana, filaAct, numChars);
            numChars = 0;
            // Avancar fila si NO estem al final
            if (filaAct < VFILS - 1) {
                filaAct++;
            }
        }

        // Actualitzar pControl per el proxim _gg_escribir()
        // Posar num linia a 16 bits alts 
        // OR per 16 bits baixos dels caracters pendents
        _gd_wbfs[ventana].pControl = (filaAct << 16) | numChars;
		
        i++; // seguent caracter
    }
}

// Funcio que neteja la pantalla i actualitza el cursor a la primera linia
void _gg_clearScreen(unsigned char zocalo) {
	// Fila inicial de la particio
  int Fp = (zocalo / PPART) * VFILS;
  // Columna inicial de la particio
  int Cp = (zocalo % PPART) * VCOLS;

  // Punter a la base del mapa 2 en la finestra v
  u16 *map_Ptr = (u16 *)bgGetMapPtr(bg2);

  for (int Fv = 0; Fv < VFILS; Fv++) {
    for (int Fc = 0; Fc < VCOLS; Fc++) {
      // Posar caracter buit a totes les posicions
      int offset_rel = (Fp + Fv) * PCOLS + (Cp + Fc);
      map_Ptr[offset_rel] = 0;
    }
  }
  // Reiniciar cursor adalt de tot
  _gd_wbfs[zocalo].pControl = 0;
}

 void _gg_spriteSet(unsigned char n, unsigned char icon, unsigned char zocalo) {
 
    if (n >= MAX_SPRITE_PROC) {
        return;
    }
    // Index global de sprites
    int idx_global = (zocalo * MAX_SPRITE_PROC) + n;

    // Actualitzar estat del vector de sprites
    _gd_sprites[idx_global].icon = icon;
    _gd_sprites[idx_global].zocalo = zocalo;
    _gd_sprites[idx_global].n = idx_global;
}


void _gg_spriteMove(unsigned char n, short px, short py, unsigned char zocalo) {

    if (n >= MAX_SPRITE_PROC) {
        return;
    }

    // Index global de sprites
    int idx_global = (zocalo * MAX_SPRITE_PROC) + n;
	
	// Delimitar
	if (px < -32)
		px = 0;
	if (px > 256)
		px = 0;
	if (py < -32)
		py = 0;
	if (py > 192)
		py = 0;

    // Actualitzar vector de sprites
    _gd_sprites[idx_global].px = px;
    _gd_sprites[idx_global].py = py;
	_gg_actualiza_sprites();
}

void _gg_spriteShow(unsigned char n, unsigned char zocalo) {

    if (n >= MAX_SPRITE_PROC) {
        return;
    }

    // Index global de sprites
    int idx_global = (zocalo * MAX_SPRITE_PROC) + n;
	
    //Actualitzar vector de sprites
    _gd_sprites[idx_global].visible = 1;
	_gg_actualiza_sprites();
	
}


void _gg_spriteHide(unsigned char n, unsigned char zocalo) {

    if (n >= MAX_SPRITE_PROC) {
      return;
    }

    // Index global de sprites
    int idx_global = (zocalo * MAX_SPRITE_PROC) + n;
    //Actualitzar vector de sprites
	_gd_sprites[idx_global].visible = 0;
	_gg_actualiza_sprites();
}


void _gg_actualiza_sprites() {

    for (int idx_global = 0; idx_global < 128; idx_global++) {
	
        garlicSPRITE *s = &_gd_sprites[idx_global];
		
        // Sprite inicialitzat
        if (s->icon != 0xFF) {
		
            // Posicio relativa de la finestra
            short base_x = (s->zocalo % PPART) * 128;
            short base_y = (s->zocalo / PPART) * 96;
			
            // Posicio absoluta de la pantalla
            short abs_px = base_x + s->px;
            short abs_py = base_y + s->py;
			
            SPR_crea_sprite(idx_global, 0, 2, s->icon * 16);
            SPR_fija_prioridad(idx_global, 1);
            SPR_mueve_sprite(idx_global, abs_px, abs_py);
			
            if (s->visible) {
                SPR_muestra_sprite(idx_global);
            } else {
                SPR_oculta_sprite(idx_global);
            }
        }
    }            
    SPR_actualiza_sprites(OAM, 128);
} 
