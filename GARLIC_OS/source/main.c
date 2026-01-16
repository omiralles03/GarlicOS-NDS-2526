/*------------------------------------------------------------------------------

	"main.c" : fase 2 / progP

	Versión final de GARLIC 2.0
	(multiplexación, retardar procesos, matar procesos + TEST BÚSTIES)

------------------------------------------------------------------------------*/
#include <nds.h>
#include <stdlib.h>

#include "garlic_system.h"	// definición de funciones y variables de sistema

extern int * punixTime;		// puntero a zona de memoria con el tiempo real

const short divFreq0 = -33513982/1024;		// frecuencia de TIMER0 = 1 Hz

// --- Declaracions externes per a les bústies (progP) ---
extern int _ga_send(int n, int data);
extern int _ga_receive(int n);
// -------------------------------------------------------

/* FUNCIONS AUXILIARS PER AL TEST DE BÚSTIES */

/* CONSUMIDOR (Llegeix i es bloqueja si està buida) */
void aux_consumidor(int arg)
{
	_gg_escribir("CONSUMIDOR (Soc 1):\n", 0, 0, 1);
	_gg_escribir("Intento llegir Bustia 0...\n", 0, 0, 1);
	
	// Aquesta crida bloqueja el procés perquè la bústia 0 està buida.
	int dada = _ga_receive(0);
	
	_gg_escribir("JA TINC LA DADA!\n", 0, 0, 1);
	_gg_escribir("Valor rebut: %d \n", dada, 0, 1);
	
	while(1) _gp_WaitForVBlank(); // Es queda viu
}

/* PRODUCTOR (Espera uns segons i envia) */
void aux_productor(int arg)
{
	_gg_escribir("PRODUCTOR (Soc 2):\n", 0, 0, 2);
	_gg_escribir("Esperant 10 segons...\n", 0, 0, 2);
	
	// Fem un compte enrere visible per demostrar que l'altre procés està esperant
	int i;
	for (i=0; i<10; i++) {
		_gg_escribir(".", 0, 0, 2); 
		int tics = _gd_tickCount + 60; 
		while(_gd_tickCount < tics) _gp_WaitForVBlank();
	}
	
	_gg_escribir("ENVIANT '999' a MB0!\n", 0, 0, 2);
	
	// Enviem la dada. Això hauria de despertar al consumidor immediatament.
	_ga_send(0, 999);
	
	_gg_escribir("Dada enviada. Adeu.\n", 0, 0, 2);
	while(1) _gp_WaitForVBlank();
}


/* función para escribir los porcentajes de uso de la CPU */
void porcentajeUso()
{
	if (_gd_sincMain & 1)			// verificar sincronismo de timer0
	{
		_gd_sincMain &= 0xFFFE;			// poner bit de sincronismo a cero
		_gg_escribir("***\t%d%%  %d%%", _gd_pcbs[0].workTicks >> 24,
										_gd_pcbs[1].workTicks >> 24, 0);
		_gg_escribir("  %d%%  %d%%\n", _gd_pcbs[2].workTicks >> 24,
										_gd_pcbs[3].workTicks >> 24, 0);
	}
}


/* Inicializaciones generales del sistema Garlic */
void inicializarSistema() {
	_gg_iniGrafA();			
	_gs_iniGrafB();
	_gs_dibujarTabla();

	_gd_seed = *punixTime;	
	_gd_seed <<= 16;		
	
	_gd_pcbs[0].keyName = 0x4C524147;		// "GARL"
	
	if (!_gm_initFS()) {
		_gg_escribir("ERROR: ¡no se puede inicializar el sistema de ficheros!", 0, 0, 0);
		exit(0);
	}

	irqInitHandler(_gp_IntrMain);	
	irqSet(IRQ_VBLANK, _gp_rsiVBL);	
	irqEnable(IRQ_VBLANK);			

	irqSet(IRQ_TIMER0, _gp_rsiTIMER0);
	irqEnable(IRQ_TIMER0);				
	TIMER0_DATA = divFreq0; 
	TIMER0_CR = 0xC3;  	
	
	REG_IME = IME_ENABLE;			
}



int main(int argc, char **argv) {

	intFunc start;
	int mtics, v;

	inicializarSistema();
	
	_gg_escribir("********************************", 0, 0, 0);
	_gg_escribir("* *", 0, 0, 0);
	_gg_escribir("* Sistema Operativo GARLIC 2.0 *", 0, 0, 0);
	_gg_escribir("* *", 0, 0, 0);
	_gg_escribir("********************************", 0, 0, 0);
	_gg_escribir("*** Inicio fase 2_P\n", 0, 0, 0);
	
	
	// TEST HOLA
	
	_gg_escribir("*** Carga de programa HOLA.elf\n", 0, 0, 0);
	start = _gm_cargarPrograma("HOLA");
	if (start)
	{	
		_gp_crearProc(start, 1, "HOLA", 3);
		_gp_crearProc(start, 2, "HOLA", 3);
		_gp_crearProc(start, 3, "HOLA", 3);
		
		while (_gd_tickCount < 240)			// esperar 4 segundos
		{
			_gp_WaitForVBlank();
			porcentajeUso();
		}
		_gp_matarProc(1);					// matar proceso 1
		_gg_escribir("Proceso 1 eliminado\n", 0, 0, 0);
		_gs_dibujarTabla();
		
		while (_gd_tickCount < 480)			// esperar 4 segundos más
		{
			_gp_WaitForVBlank();
			porcentajeUso();
		}
		_gp_matarProc(3);					// matar proceso 3
		_gg_escribir("Proceso 3 eliminado\n", 0, 0, 0);
		_gs_dibujarTabla();
		
		while (_gp_numProc() > 1)			// esperar a que proceso 2 acabe
		{
			_gp_WaitForVBlank();
			porcentajeUso();
		}
		_gg_escribir("Proceso 2 terminado\n", 0, 0, 0);
	} else
		_gg_escribir("*** Programa NO cargado\n", 0, 0, 0);


	
	// TEST PONG
	
	_gg_escribir("*** Carga de programa PONG.elf\n", 0, 0, 0);
	start = _gm_cargarPrograma("PONG");
	if (start)
	{
		for (v = 1; v < 4; v++)	// inicializar buffers de ventanas 1, 2 y 3
			_gd_wbfs[v].pControl = 0;
		
		_gp_crearProc(start, 1, "PONG", 1);
		_gp_crearProc(start, 2, "PONG", 2);
		_gp_crearProc(start, 3, "PONG", 3);
		
		mtics = _gd_tickCount + 960;
		while (_gd_tickCount < mtics)		// esperar 16 segundos más
		{
			_gp_WaitForVBlank();
			porcentajeUso();
		}
		
		_gp_matarProc(1);					// matar los 3 procesos a la vez
		_gp_matarProc(2);
		_gp_matarProc(3);
		_gg_escribir("Procesos 1, 2 y 3 eliminados\n", 0, 0, 0);
		
		while (_gp_numProc() > 1)	// esperar a que todos los procesos acaben
		{
			_gp_WaitForVBlank();
			porcentajeUso();
		}
		
	} else
		_gg_escribir("*** Programa NO cargado\n", 0, 0, 0);



	// TEST BÚSTIES
	
	_gg_escribir("\n*** INICI TEST BUSTIES (Bloqueig)\n", 0, 0, 0);
	
	// Netejem finestres
	_gs_borrarVentana(1, 0);
	_gs_borrarVentana(2, 0);
	_gs_borrarVentana(3, 0);	

	// Creem el CONSUMIDOR al Sòcol 1
	_gp_crearProc((intFunc)aux_consumidor, 1, "CONS", 0);
	
	// Creem el PRODUCTOR al Sòcol 2
	_gp_crearProc((intFunc)aux_productor, 2, "PROD", 0);
	
	_gg_escribir("Processos creats. Observa el bloqueig.\n", 0, 0, 0);

	_gg_escribir("*** Final fase 2_P\n", 0, 0, 0);
	_gs_dibujarTabla();

	while(1) {
		_gp_WaitForVBlank();
		// Seguirem mostrant els percentatges mentre corre el test de bústies
		porcentajeUso();
	}
	return 0;
}