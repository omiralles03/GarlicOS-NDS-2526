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