/*------------------------------------------------------------------------------

	"main.c" : fase 1 + programador G
	"main.c" : fase 1 + programador P

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
	
	// Inicializaciones progG
	int v;

	_gg_iniGrafA();			// inicializar procesador gráfico A
	for (v = 0; v < 4; v++)	// para todas las ventanas
		_gd_wbfs[v].pControl = 0;		// inicializar los buffers de ventana
	
	// Inicializaciones progP
	int i;
	consoleDemoInit();		// inicializar consola, sólo para esta simulación

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
	
	_gg_escribir("*** Final fase 1_G\n", 0, 0, 0);

	while (1)
	{
		_gp_WaitForVBlank();
	}
	return 0;
}
