/*------------------------------------------------------------------------------

	"main.c" : fase 1 + programador G
	"main.c" : fase 1 + programador P
	"main.c" : fase 1 / programador M

	Programa principal de GARLIC 1.0.
------------------------------------------------------------------------------*/
#include <nds.h>
#include <stdio.h>

#include <garlic_system.h>	// definición de funciones y variables de sistema

#include <GARLIC_API.h>		// inclusión del API para simular un proceso
#include <Sprites_sopo.h>

extern int * punixTime;		// puntero a zona de memoria con el tiempo real
void pruevas_progG();
void check_params(int zocalo, unsigned char n, unsigned char icon, 
	short px, short py, unsigned visible);

/* Inicializaciones generales del sistema Garlic */
//------------------------------------------------------------------------------
void inicializarSistema() {
//------------------------------------------------------------------------------
	
	_gd_seed = *punixTime;	// inicializar semilla para números aleatorios con
	_gd_seed <<= 16;		// el valor de tiempo real UNIX, desplazado 16 bits
	
	// ------- Inicializaciones progG -------
	int v;

	_gg_iniGrafA();			// inicializar procesador gráfico A
	for (v = 0; v < 4; v++)	// para todas las ventanas
		_gd_wbfs[v].pControl = 0;		// inicializar los buffers de ventana
	
	// ------- Inicializaciones progP -------
	int i;

	irqInitHandler(_gp_IntrMain);	// instalar rutina principal interrupciones
	irqSet(IRQ_VBLANK, _gp_rsiVBL);	// instalar RSI de vertical Blank
	irqEnable(IRQ_VBLANK);			// activar interrupciones de vertical Blank
	REG_IME = IME_ENABLE;			// activar las interrupciones en general
	
	for (i = 0; i<8; i++)		// Inicialitzacions de les bústies
	{
	_gd_mailboxes[i].head = 0;
	_gd_mailboxes[i].tail = 0;
	_gd_mailboxes[i].count = 0;
	}
	
	_gd_pcbs[0].keyName = 0x4C524147;	// "GARL"

	// ------- Inicializaciones progM -------
	if (!_gm_initFS())
	{
		printf("ERROR: ¡no se puede inicializar el sistema de ficheros!");
		exit(0);
	}
}

/**
 * Función que carga un programa a partir de su nombre (4 carácteres)
 * con el argumento especificado, muestra la dirección de arranque y espera
 * a que el usuario presione 'START' para iniciar el programa.
 * Parametros
 *	prog: nombre del programa (4 carácteres)
 *	arg: argumento con el que cargar el programa
 *  ventana: número [0..3] de la ventana a la que dirigir la salida
 * Retorna:
 *	Dirección en la que se ha cargado el programa
 */
intFunc cargarPrograma(char prog[4], int arg, int zocalo) 
{
	intFunc start = _gm_cargarPrograma(prog);
	if (start) 
	{	
		_gg_escribir("\n ** Programa: %s\n\n", (unsigned int)prog, 0, zocalo % 4);
		_gp_crearProc(start, zocalo, prog, arg);
	} 
	else
	{ 
		_gg_escribir("\n* ERROR al cargar %s(%d)\n", (unsigned int)prog, (unsigned int)arg, zocalo % 4);
	}
	return start;
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
	_gg_escribir("*** Inicio fase GARLIC\n", 0, 0, 0);

	pruevas_progG();
	cargarPrograma("PRNT", 5, 1);
	cargarPrograma("DNIF", 0, 2);
	cargarPrograma("COLZ", 0, 3);
	cargarPrograma("MMLL", 1, 4);
	cargarPrograma("HOLA", 2, 6);

	while (1)
	{
		_gp_WaitForVBlank();
	}
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
	_gg_escribir("\n\n> Zocalo: %d - %d", zocalo, _gd_sprites[idx_global].zocalo, zocalo);
	_gg_escribir("\n> Sprite idx: %d - %d", n, _gd_sprites[idx_global].n, zocalo);
	_gg_escribir("\n> Icon: %d - %d", icon, _gd_sprites[idx_global].icon, zocalo);
	_gg_escribir("\n> Pos. : [%d,%d] - ", px, py, zocalo);
	_gg_escribir("[%d,%d]", _gd_sprites[idx_global].px, _gd_sprites[idx_global].py, zocalo);
	_gg_escribir("\n> Visib. %d - %d", visible, _gd_sprites[idx_global].visible, zocalo);
}

void pruevas_progG()
{
	unsigned char n, icon, visible;
	short px, py;
	int zocalo;
	
	// ------- Prueba 1: Posiciones -------
	zocalo = 0;
	_gg_escribir("\n\n*** Prueba 1\n", 0, 0, zocalo);
	_gg_escribir("\n\n* Valor Esperado - Vector *\n", 0, 0, zocalo);
	for (int i = 0; i < 50; i++)
		_gp_WaitForVBlank();
		
	n = 0; icon = 0; px = 48; py = 32; visible = 1;
	_gg_spriteSet(n, icon, zocalo);
	_gg_spriteMove(n, px, py, zocalo);
	_gg_spriteShow(n, zocalo);
	check_params(zocalo, n, icon, px, py, visible);
	for (int i = 0; i < 75; i++)
		_gp_WaitForVBlank();
		
	n = 1; icon = 1; px = 176; py = 32; visible = 1;
	_gg_spriteSet(n, icon, zocalo);
	_gg_spriteMove(n, px, py, zocalo);
	_gg_spriteShow(n, zocalo);
	check_params(zocalo, n, icon, px, py, visible);
	for (int i = 0; i < 75; i++)
		_gp_WaitForVBlank();
		
	n = 2; icon = 2; px = 48; py = 80; visible = 1;
	_gg_spriteSet(n, icon, zocalo);
	_gg_spriteMove(n, px, py, zocalo);
	_gg_spriteShow(n, zocalo);
	check_params(zocalo, n, icon, px, py, visible);
	for (int i = 0; i < 75; i++)
		_gp_WaitForVBlank();
		
	n = 3; icon = 3; px = -300; py = 300; visible = 1;
	_gg_spriteSet(n, icon, zocalo);
	_gg_spriteMove(n, px, py, zocalo);
	_gg_spriteShow(n, zocalo);
	check_params(zocalo, n, icon, px, py, visible);
	for (int i = 0; i < 75; i++)
		_gp_WaitForVBlank();
		
	// Mover sprite 0 a la pos 0,0
	n = 0; px = 0; py = 0; visible = 1;
	_gg_spriteMove(n, px, py, zocalo);
	check_params(zocalo, n, icon, px, py, visible);
	_gg_escribir("\n\n*** Fin Prueba 1\n", 0, 0, zocalo);
	
	for (int i = 0; i < 75; i++)
		_gp_WaitForVBlank();
		
	_gg_spriteHide(0, zocalo);
	_gg_spriteHide(1, zocalo);
	_gg_spriteHide(2, zocalo);
	_gg_spriteHide(3, zocalo);
	
	// ------- Prueba 2: Movimiento -------
	zocalo = 1;
	_gg_escribir("\n\n*** Prueba 2\n", 0, 0, zocalo);
	_gg_escribir("\n\n* Valor Esperado - Vector *\n", 0, 0, zocalo);
	for (int i = 0; i < 50; i++)
		_gp_WaitForVBlank();
	
	n = 4; icon = 10; px = 48; py = 32; visible = 1;
	int idx_global = (zocalo * 8) + n;
	_gg_spriteSet(n, icon, zocalo);
	_gg_spriteMove(n, px, py, zocalo);
	_gg_spriteShow(n, zocalo);
	check_params(zocalo, n, icon, px, py, visible);
	for (int i = 0; i < 50; i++)
		_gp_WaitForVBlank();
	
	short dir = 2;
	for (int i = 0; i < 60; i++) {
		if (i%10 == 0) {
			dir = -dir;
		}
		py += dir;
		_gg_spriteMove(n, px, py, zocalo);
		_gg_escribir("\n> Pos. : [%d,%d] - ", px, py, zocalo);
		_gg_escribir("[%d,%d]", _gd_sprites[idx_global].px, _gd_sprites[idx_global].py, zocalo);
	}
	
	_gg_escribir("\n\n*** Fin Prueba 2\n", 0, 0, zocalo);
	for (int i = 0; i < 50; i++)
		_gp_WaitForVBlank();
	_gg_spriteHide(n, zocalo);	
	
	// ------- Prueba 3: Cambio de indice -------
	zocalo = 2;
	_gg_escribir("\n\n*** Prueba 3\n", 0, 0, zocalo);	
	_gg_escribir("\n\n* Valor Esperado - Vector *\n", 0, 0, zocalo);
	for (int i = 0; i < 50; i++)
		_gp_WaitForVBlank();
		
	n = 5; icon = 12; px = 48; py = 32; visible = 1;
	idx_global = (zocalo * 8) + n;
	_gg_spriteSet(n, icon, zocalo);
	_gg_spriteMove(n, px, py, zocalo);
	_gg_spriteShow(n, zocalo);
	check_params(zocalo, n, icon, px, py, visible);
	for (int i = 0; i < 50; i++)
		_gp_WaitForVBlank();
	
	for (int i = 0; i < 300; i++) {
		if (i%60 == 0 && i != 0) {
			icon++;
			_gg_spriteSet(n, icon, zocalo);
			_gg_spriteShow(n, zocalo);
			_gg_escribir("\n> Icon: %d - %d\n", icon, _gd_sprites[idx_global].icon, zocalo);
			for (int i = 0; i < 50; i++)
				_gp_WaitForVBlank();
			
		}
	}
	
	_gg_escribir("\n\n*** Fin Prueba 3\n", 0, 0, zocalo);
	
	for (int i = 0; i < 50; i++)
		_gp_WaitForVBlank();
		
	_gg_spriteHide(n, zocalo);

	// ------- Prueba 4: Movimiento en region -------
	zocalo = 3;
	_gg_escribir("\n\n*** Prueba 4\n", 0, 0, zocalo);
	_gg_escribir("\n\n* Valor Esperado - Vector *\n", 0, 0, zocalo);
	for (int i = 0; i < 50; i++)
		_gp_WaitForVBlank();
	
	// Ventana
	short maxX = 128 - 32;
	short maxY = 96 - 32;
	short minX = 0;
	short minY = 0;
	short dirX = 2;
	short dirY = 1;
	
	n = 6; icon = 3; px = minX; py = minY; visible = 1;
	idx_global = (zocalo * 8) + n;
	_gg_spriteSet(n, icon, zocalo);
	_gg_spriteMove(n, px, py, zocalo);
	_gg_spriteShow(n, zocalo);
	check_params(zocalo, n, icon, px, py, visible);
	for (int i = 0; i < 50; i++)
		_gp_WaitForVBlank();
	
	for (int i = 0; i < 200; i++) {
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
		_gg_spriteMove(n, px, py, zocalo);
		_gg_escribir("\n> Pos. : [%d,%d] - ", px, py, zocalo);
		_gg_escribir("[%d,%d]\n", _gd_sprites[idx_global].px, _gd_sprites[idx_global].py, zocalo);
	}
	
	_gg_escribir("\n\n*** Fin Prueba 4\n", 0, 0, zocalo);
	
	for (int i = 0; i < 50; i++)
		_gp_WaitForVBlank();
		
	_gg_spriteHide(n, zocalo);
		
	for (int i = 0; i < 4; i++) {
		_gg_clearScreen(i);
	}
	for (int i = 0; i < 25; i++)
		_gp_WaitForVBlank();
}