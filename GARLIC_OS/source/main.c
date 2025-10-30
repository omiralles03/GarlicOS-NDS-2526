/*------------------------------------------------------------------------------

	"main.c" : fase 1 / programador G

	Programa de prueba de llamada de funciones gráficas de GARLIC 1.0,
	pero sin cargar procesos en memoria ni multiplexación.

------------------------------------------------------------------------------*/
#include <nds.h>

#include <garlic_system.h>	// definición de funciones y variables de sistema

#include <GARLIC_API.h>		// inclusión del API para simular un proceso
#include <Sprites_sopo.h>

int hola(int);				// función que simula la ejecución del proceso
extern int prnt(int);		// otra función (externa) de test correspondiente
							// a un proceso de usuario
extern int dnif(int);

extern int * punixTime;		// puntero a zona de memoria con el tiempo real

void spriteMove2(unsigned char n, short px, short py, unsigned char zocalo);
void clear_screen();
void prova_estatica();
void prova_dinamica();
void prova_canvis();
void prova_dvd();
void check_params(int zocalo, unsigned char n, unsigned char icon, 
	short px, short py, unsigned visible);


/* Inicializaciones generales del sistema Garlic */
//------------------------------------------------------------------------------
void inicializarSistema() {
//------------------------------------------------------------------------------
	int v;

	_gg_iniGrafA();			// inicializar procesador gráfico A
	for (v = 0; v < 4; v++)	// para todas las ventanas
		_gd_wbfs[v].pControl = 0;		// inicializar los buffers de ventana
	
	_gd_seed = *punixTime;	// inicializar semilla para números aleatorios con
	_gd_seed <<= 16;		// el valor de tiempo real UNIX, desplazado 16 bits
}


//------------------------------------------------------------------------------
int main(int argc, char **argv) {
//------------------------------------------------------------------------------
	
	inicializarSistema();
	
	_gg_escribir("********************************", 0, 0, 0);
	_gg_escribir("*                              *", 0, 0, 0);
	_gg_escribir("* Sistema Operativo GARLIC 1.0 *", 0, 0, 0);
	_gg_escribir("*                              *", 0, 0, 0);
	_gg_escribir("********************************", 0, 0, 0);
	_gg_escribir("*** Inicio fase 1_G\n", 0, 0, 0);

	// Programes usuari hola / prnt
	_gd_pidz = 6;	// simular zócalo 6
	hola(0);
	_gd_pidz = 7;	// simular zócalo 7
	hola(2);
	_gd_pidz = 5;	// simular zócalo 5
	prnt(1);
	
	clear_screen();

	// Proves Sprites
	_gd_pidz = 0;
	prova_estatica();
	_gd_pidz = 1;
	prova_dinamica();
	_gd_pidz = 2;
	prova_canvis();
	_gd_pidz = 3;
	prova_dvd();
	
	clear_screen();
	// Proves DNIF
	_gd_pidz = 0;
	dnif(0);
	dnif(1);
	_gd_pidz = 1;
	dnif(1);
	dnif(0);
	_gd_pidz = 2;
	dnif(3);
	dnif(5);

	_gg_escribir("*** Final fase 1_G\n", 0, 0, 0);

	while (1)
	{
		swiWaitForVBlank();
	}							// parar el procesador en un bucle infinito
	return 0;
}


/* Proceso de prueba */
//------------------------------------------------------------------------------
int hola(int arg) {
//------------------------------------------------------------------------------
	unsigned int i, j, iter;
	
	if (arg < 0) arg = 0;			// limitar valor máximo y 
	else if (arg > 3) arg = 3;		// valor mínimo del argumento
	
									// esccribir mensaje inicial
	GARLIC_printf("-- Programa HOLA  -  PID (%d) --\n", GARLIC_pid());
	
	j = 1;							// j = cálculo de 10 elevado a arg
	for (i = 0; i < arg; i++)
		j *= 10;
						// cálculo aleatorio del número de iteraciones 'iter'
	GARLIC_divmod(GARLIC_random(), j, &i, &iter);
	iter++;							// asegurar que hay al menos una iteración
	
	for (i = 0; i < iter; i++)		// escribir mensajes
		GARLIC_printf("(%d)\t%d: Hello world!\n", GARLIC_pid(), i);

	return 0;
}

//------------------------------------------------------------------------------
// JOC DE PROVES PROG G - SPRITES
//------------------------------------------------------------------------------
// Rutina per veure els parametres dels sprites
void check_params(int zocalo, unsigned char n, unsigned char icon, 
	short px, short py, unsigned visible)
{
	int idx_global = (zocalo * MAX_SPRITE_PROC) + n;
	GARLIC_printf("\n* Valor Esperado - Vector *\n");
	GARLIC_printf("\n> Zocalo: %d - %d\n", zocalo, _gd_sprites[idx_global].zocalo);
	GARLIC_printf("\n> Sprite idx: %d - %d\n", idx_global, _gd_sprites[idx_global].n);
	GARLIC_printf("\n> Icon: %d - %d\n", icon, _gd_sprites[idx_global].icon);
	GARLIC_printf("\n> Pos. : [%d,%d] - ", px, py);
	GARLIC_printf("[%d,%d]\n", _gd_sprites[idx_global].px, _gd_sprites[idx_global].py);
	GARLIC_printf("\n> Visib. %d - %d\n", visible, _gd_sprites[idx_global].visible);
}

// Crea un Sprite a unes coordenades x,y
void prova_estatica()
 {
	unsigned char n, icon, visible;
	short px, py;
	int zocalo;
	
	zocalo = _gd_pidz;
	GARLIC_printf("\n*** Prueba Estatica ***\n");
	
	n = 0; icon =0; px = 48; py = 32; visible = 1;
	GARLIC_spriteSet(n, icon);
	GARLIC_spriteMove(n, px, py);
	GARLIC_spriteShow(n);
	_gg_actualiza_sprites(); swiWaitForVBlank();
	check_params(zocalo, n, icon, px, py, visible);
	
	n = 1; icon =9; px = 176; py = 32; visible = 1;
	GARLIC_spriteSet(n, icon);
	GARLIC_spriteMove(n, px, py);
	GARLIC_spriteShow(n);
	_gg_actualiza_sprites(); swiWaitForVBlank();
	check_params(zocalo, n, icon, px, py, visible);
	
	n = 2; icon =8; px = 48; py = 80; visible = 1;
	GARLIC_spriteSet(n, icon);
	GARLIC_spriteMove(n, px, py);
	GARLIC_spriteShow(n);
	_gg_actualiza_sprites(); swiWaitForVBlank();
	check_params(zocalo, n, icon, px, py, visible);
	
	GARLIC_spriteHide(0);
	GARLIC_spriteHide(1);
	GARLIC_spriteHide(2);
	_gg_actualiza_sprites(); swiWaitForVBlank();
	GARLIC_printf("\n*** Final Prueba Estatica ***\n");
 }
 
 // Desplaca un Sprite durant 60 iteracions
 void prova_dinamica()
 {
	unsigned char n, icon, visible;
	short px, py;
	int zocalo;
	
	zocalo = _gd_pidz;
	GARLIC_printf("\n*** Prueba Dinamica ***\n");
	
	n = 3; icon = 10; px = 48; py = 32; visible = 1;
	int idx_global = (zocalo * MAX_SPRITE_PROC) + n;
	GARLIC_spriteSet(n, icon);
	GARLIC_spriteMove(n, px, py);
	GARLIC_spriteShow(n);
	_gg_actualiza_sprites(); swiWaitForVBlank();
	check_params(zocalo, n, icon, px, py, visible);
	
	short dir = 2;
	for (int i = 0; i < 60; i++) {
		if (i%10 == 0) {
			dir = -dir;
		}
		py += dir;
		GARLIC_spriteMove(n, px, py);
		_gg_actualiza_sprites(); swiWaitForVBlank();
		GARLIC_printf("\n> Pos. : [%d,%d] - ", px, py);
		GARLIC_printf("[%d,%d]\n", _gd_sprites[idx_global].px, _gd_sprites[idx_global].py);
	}
	GARLIC_spriteHide(n);
	_gg_actualiza_sprites(); swiWaitForVBlank();
	GARLIC_printf("\n*** Final Prueba Dinamica ***\n");
}

// Canvia la icona de un sprite n cada 60 iteracions 5 cops
 void prova_canvis()
 {
	unsigned char n, icon, visible;
	short px, py;
	int zocalo;
	
	zocalo = _gd_pidz;
	GARLIC_printf("\n**** Prueba Canvis ***\n");
	
	n = 4; icon = 7; px = 48; py = 32; visible = 1;
	int idx_global = (zocalo * MAX_SPRITE_PROC) + n;
	GARLIC_spriteSet(n, icon);
	GARLIC_spriteMove(n, px, py);
	GARLIC_spriteShow(n);
	_gg_actualiza_sprites(); swiWaitForVBlank();
	check_params(zocalo, n, icon, px, py, visible);
	
	for (int i = 0; i < 300; i++) {
		if (i%60 == 0 && i != 0) {
			icon++;
			
			GARLIC_spriteSet(n, icon);
			GARLIC_printf("\n> Icon: %d - %d\n", icon, _gd_sprites[idx_global].icon);
		}
		_gg_actualiza_sprites(); swiWaitForVBlank();
	}
	GARLIC_spriteHide(n);
	_gg_actualiza_sprites(); swiWaitForVBlank();
	GARLIC_printf("\n*** Final Prueba Canvis ***\n");
}

// DVD SCREENSAVER, mou el sprite i el rebota en la finestra
// El sprite global no podria fer aixo amb la funcio _gg_mueveSprite
 void prova_dvd()
{
	unsigned char n, icon, visible;
	short px, py;
	unsigned char n2, icon2;
	short px2, py2;
	int zocalo;
	
	_gd_pidz = 3;
	zocalo = _gd_pidz;
	GARLIC_printf("\n**** Prueba DVD ***\n");

	// Ventana
	short maxX = 128 - 32;
	short maxY = 96 - 32;
	short minX = 0;
	short minY = 0;
	short dirX = 2;
	short dirY = 1;
	// Global
	short maxXG = 128 - 32;
	short maxYG = 96 - 32;
	short minXG = -128;
	short minYG = -96;
	short dirXG = -6;
	short dirYG = -3;
	
	n = 5; icon = 3; px = minX; py = minY; visible = 1;
	int idx_global = (zocalo * MAX_SPRITE_PROC) + n;
	GARLIC_spriteSet(n, icon);
	GARLIC_spriteMove(n, px, py);
	GARLIC_spriteShow(n);
	_gg_actualiza_sprites(); swiWaitForVBlank();
	check_params(zocalo, n, icon, px, py, visible);
	
	n2 = 6; icon2 = 8; px2 = -16; py2 = -16;
	GARLIC_spriteSet(n2, icon2);
	GARLIC_spriteMove(n2, px2, py2);
	GARLIC_spriteShow(n2);
	_gg_actualiza_sprites(); swiWaitForVBlank();
	
	for (int i = 0; i < 150; i++) {
		// VENTANA
		px += dirX;
		py += dirY;
		
		if (px >= maxX) {
			px = maxX;
			dirX = -dirX;
		} else if (px <= minX) {
			px = minX;
			dirX = -dirX;
		}
		
		if (py >= maxY) {
			py = maxY;
			dirY = -dirY;
		} else if (py <= minY) {
			py = minY;
			dirY = -dirY;
		}
		
		// GLOBAL
		px2 += dirXG;
		py2 += dirYG;
		
		if (px2 >= maxXG) {
			px2 = maxXG;
			dirXG = -dirXG;
		} else if (px2 <= minXG) {
			px2 = minXG;
			dirXG = -dirXG;
		}
		
		if (py2 >= maxYG) {
			py2 = maxYG;
			dirYG = -dirYG;
		} else if (py2 <= minYG) {
			py2 = minYG;
			dirYG = -dirYG;
		}
		spriteMove2(n2, px2, py2, zocalo);
				
		// VENTANA
		GARLIC_spriteMove(n, px, py);
		GARLIC_printf("\n> Pos. : [%d,%d] - ", px, py);
		GARLIC_printf("[%d,%d]\n", _gd_sprites[idx_global].px, _gd_sprites[idx_global].py);
		_gg_actualiza_sprites(); swiWaitForVBlank();
		
	}
	GARLIC_spriteHide(n);
	GARLIC_spriteHide(n2);
	_gg_actualiza_sprites(); swiWaitForVBlank();
	GARLIC_printf("\n*** Final Prueba Canvis ***\n");
}

void spriteMove2(unsigned char n, short px, short py, unsigned char zocalo) {

    if (n >= MAX_SPRITE_PROC) {
        return;
    }

    // Index global de sprites
    int idx_global = (zocalo * MAX_SPRITE_PROC) + n;
	
    // Actualitzar vector de sprites
    _gd_sprites[idx_global].px = px;
    _gd_sprites[idx_global].py = py;
    //SPR_mueve_sprite(idx_global, abs_px, abs_py);
}

// Neteja les 4 finestres posant caracter buit
void clear_screen() {
	for (int i = 0; i < 4; i++) {
		_gd_pidz = i;
		GARLIC_clearScreen();
	}
}