/*------------------------------------------------------------------------------

	"main.c" : fase 2 / progM

	Versión final de GARLIC 2.0
	(carga de programas con 2 segmentos, listado de programas, gestión de
	 franjas de memoria)

------------------------------------------------------------------------------*/
#include <nds.h>

#include "garlic_system.h"	// definici?n de funciones y variables de sistema

extern int * punixTime;		// puntero a zona de memoria con el tiempo real

const short divFreq1 = -33513982/(1024*7);		// frecuencia de TIMER1 = 7 Hz



/* gestionSincronismos:	funci?n para detectar cu?ndo un proceso ha terminado
						su ejecuci?n, consultando el bit i-?ssimo de la
						variable global _gd_sincMain; en caso de detecci?n,
						libera la memoria reservada para el proceso del z?calo
						i-?ssimo y pone el bit de _gd_sincMain a cero.
*/
void gestionSincronismos()
{
	int i, mask;
	
	if (_gd_sincMain & 0xFFFE)		// si hay algun sincronismo pendiente
	{
		mask = 2;
		for (i = 1; i <= 15; i++)
		{
			if (_gd_sincMain & mask)
			{						// liberar la memoria del proceso terminado
				_gm_liberarMem(i);
				_gg_escribir("* proceso %d terminado\n", i, 0, 0);
				_gs_dibujarTabla();
				_gd_sincMain &= ~mask;		// poner bit de sincronismo a cero
			}
			mask <<= 1;
		}
	}
}



/* esperaSegundos:	funci?n para esperar un cierto n?mero de segundos, usando
					la variable global _gd_tickCount.
*/
void esperaSegundos(unsigned char nsecs)
{
	unsigned int mtics;

	mtics = _gd_tickCount + (nsecs * 60);
	while (_gd_tickCount < mtics)		// esperar un cierto n?mero de segundos
	{
		_gp_WaitForVBlank();
		gestionSincronismos();
	}
}



/* eliminaProc:	funci?n para provocar la finalizaci?n de un proceso de usuario;
				si el z?calo indicado por par?metro contiene un proceso, libera
				la entrada del vector de PCBs correspondiente y busca el z?calo
				en la cola de READY, para eliminar dicha entrada de la cola
				(compact?ndola), decrementar n?mero de procesos en Ready,
				resetear la ventana asociada, y eliminar la memoria reservada
				para ese proceso.
*/
void eliminaProc(unsigned char z)
{
	unsigned char i, j;
	
	if (_gd_pcbs[z].PID != 0)
	{
		_gd_pcbs[z].PID = 0;
		i = 0; j = 0;
		while ((j == 0) && (i < _gd_nReady))
		{
			if (_gd_qReady[i] == z)		// eliminar el proceso de cola de READY
			{
				for (j = i; j < _gd_nReady; j++)	// compacta cola de READY
					_gd_qReady[j] =_gd_qReady[j+1];
				_gd_nReady--;
			}
			i++;
		}
		_gm_liberarMem(z);
		_gg_escribir("* proceso %d destruido\n", z, 0, 0);
		_gs_dibujarTabla();
	}
}




/* test 0: 	test de obtenci?n de los programas de usuario contenidos en el
			directorio "/Programas/" del disco de la NDS, llamando a la
			funci?n _gm_listaProgs(); la funci?n test0() muestra por pantalla
			(ventana 0) la lista de programas obtenida, y verifica si en la
			lista se encuentran 4 programas necesarios para realizar el resto
			de tests; en caso negativo, muestra un mensaje de error y devuelve
			cero; en caso positivo, devuelve 1.
*/
unsigned char test0()
{
	char *progs[16];	// se asume que para realizar este test nunca habr? m?s
						// de 16 programas de usuario contenidos en "/Programas/"
	char *expected[4] = {"DESC", "LABE", "PONG", "PRNT"};
	unsigned char num_progs, i, j, k;
	unsigned char result = 1;
	
	_gg_escribir("\n** TEST 0: lista de programas **\n", 0, 0, 0);
	num_progs = _gm_listaProgs(progs);
	if (num_progs == 0)
	{
		_gg_escribir("\nERROR: NO hay programas disponibles!\n", 0, 0, 0);
		result = 0;
	}
	else
	{
		k = 0;				// m?scara de bits para los programas esperados
		for (i = 0; i < num_progs; i++)
		{
			_gg_escribir((i < 10 ? "\t %d: %s\t" : "\t%d: %s\t"), i, (unsigned int) progs[i], 0);
			j = 0;
			while ((k != 15) && (j < 4))
			{
				if (((k & (1 << j)) == 0) && (strcmp(progs[i], expected[j]) == 0))
					k |= (1 << j);		// activa el bit de un programa esperado
				j++;
			}
		}
		_gg_escribir((i & 1 ? "\n\n" : "\n"), 0, 0, 0);
		if (k != 15)
		{
			_gg_escribir("\nERROR: Faltan los siguientes programas:\n", 0, 0, 0);
			for (i = 0; i < 4; i++)
			{
				if ((k & (1 << i)) == 0)
					_gg_escribir("\t%s", (unsigned int) expected[i], 0, 0);
			}
			_gg_escribir("\n", 0, 0, 0);
			result = 0;
		}
		
		esperaSegundos(2);
	}
	return result;
}




/* test 1: 	test de carga de programas de usuario de forma consecutiva (DESC,
			LABE, PRNT), sin fragmentaci?n de la memoria, comprobando que 
			funciona la carga de programas con uno o dos segmentos; esta
			funci?n de test espera a que PRNT acabe y elimina DESC, dejando
			el programa LABE en marcha para crear un principio de fragmentaci?n
			externa; la funci?n devuelve 0 si se han podido cargar los tres
			programas, o 1 si ha habido algun problema con la carga de uno de
			los programas.

unsigned char test1()
{
	char *expected[3] = {"DESC", "LABE", "PRNT"};
	intFunc start[3];
	unsigned char i;
	unsigned char result = 1;

	_gg_escribir("\n** TEST 1: carga consecutiva\n\tDESC | LABE | PRNT **\n", 0, 0, 0);
	for (i = 0; i < 3; i++)
	{
		start[i] = _gm_cargarPrograma(i+1, expected[i]);
	}
	if (start[0] && start[1] && start[2])	// verficaci?n de carga
	{
		for (i = 0; i < 3; i++)		// se asume que siempre se podr?n crear
		{							// los tres procesos asociados
			_gp_crearProc(start[i], i+1, expected[i], i);
		}
		while (_gp_numProc() > 3)	// espera finalicaci?n de PRNT
		{
			_gp_WaitForVBlank();
			gestionSincronismos();
		}
		eliminaProc(1);		// fuerza la finalizaci?n de DESC (para acelerar el test)
	}
	else
	{
		_gg_escribir("\nERROR: algun programa no se ha podido cargar!\n", 0, 0, 0);
		result = 0;
	}
	return result;
}

*/


/* test 2: 	test de carga de programas de usuario de forma NO consecutiva,
			aprovechando la fragmentaci?n externa generada en el test 1;
			se carga el programa PONG para limitar el primer espacio de memoria
			disponible, y despu?s se carga el DESC de manera que primero se
			cargar? el segmento de c?digo y despu?s el segmento de datos despu?s
			de la memoria reservada para el programa LABE (en el test anterior);
			si el DESC funciona correctamente, la reubicaci?n habr? funcionado
			para segmentos de c?digo y datos separados (no consecutivos);
			despu?s de un cierto tiempo, la funci?n eliminar? el PONG e
			intentar? cargar otro LABE, el cual cargar? el segmento de datos
			en posiciones inferiores a las del segmento de c?digo; la funci?n
			devuelve 0 si se han podido cargar los tres programas, o 1 si ha
			habido algun problema con la carga de uno de los programas.

unsigned char test2()
{
	char *expected[3] = {"PONG", "DESC", "LABE"};
	unsigned char zoc[3] = {5, 11, 9};
	intFunc start[3];
	unsigned char result = 0;

	_gg_escribir("\n** TEST 2: carga no consecutiva\n\tPONG | DESC **\n", 0, 0, 0);
	start[0] = _gm_cargarPrograma(zoc[0], expected[0]);
	start[1] = _gm_cargarPrograma(zoc[1], expected[1]);
	if (start[0] && start[1])		// verficaci?n de carga
	{
		_gp_crearProc(start[0], zoc[0], expected[0], 0);
		_gp_crearProc(start[1], zoc[1], expected[1], 3);
		esperaSegundos(6);
		eliminaProc(zoc[0]);		// elimina PONG
		_gg_escribir("\n** TEST 2: carga no consecutiva\n\tLABE **\n", 0, 0, 0);
		start[2] = _gm_cargarPrograma(zoc[2], expected[2]);
		if (start[2])
		{
			_gp_crearProc(start[2], zoc[2], expected[2], 3);
			result = 1;
		}
	}
	if (result == 0)
	{
		_gg_escribir("\nERROR: algun programa no se ha podido cargar!\n", 0, 0, 0);
	}
	return result;
}
*/


/* Inicializaciones generales del sistema Garlic */
void inicializarSistema()
{
	_gg_iniGrafA();			// inicializar procesadores gr?ficos
	_gs_iniGrafB();
	_gs_dibujarTabla();

	_gd_seed = *punixTime;	// inicializar semilla para n?meros aleatorios con
	_gd_seed <<= 16;		// el valor de tiempo real UNIX, desplazado 16 bits
	
	_gd_pcbs[0].keyName = 0x4C524147;	// "GARL"
	
	if (!_gm_initFS())
	{
		_gg_escribir("\nERROR: ?no se puede inicializar el sistema de ficheros!\n", 0, 0, 0);
		exit(0);
	}

	irqInitHandler(_gp_IntrMain);	// instalar rutina principal interrupciones
	irqSet(IRQ_VBLANK, _gp_rsiVBL);	// instalar RSI de vertical Blank
	irqEnable(IRQ_VBLANK);			// activar interrupciones de vertical Blank
	
	irqSet(IRQ_TIMER1, _gm_rsiTIMER1);
	irqEnable(IRQ_TIMER1);				// instalar la RSI para el TIMER1
	TIMER1_DATA = divFreq1; 
	TIMER1_CR = 0xC3;  	// Timer Start | IRQ Enabled | Prescaler 3 (F/1024)
	
	REG_IME = IME_ENABLE;			// activar las interrupciones en general
}

/**/
void test_TADD()
{
    intFunc start;
    _gg_escribir("\n** TEST 3: Memoria Dinámica (TADD) **\n", 0, 0, 0);
    
    start = _gm_cargarPrograma(2, "TADD"); // Carregar en zocalo lliure 
    if (start){
        _gp_crearProc(start, 2, "TADD", 0);
        
        // esperar a que tadd finalitzi
        while (_gd_pcbs[2].PID != 0)
        {
            _gp_WaitForVBlank();
            gestionSincronismos();
        }
    } else{
		_gg_escribir("ERROR: No se pudo cargar TADD\n", 0, 0, 0);
	}
}
/*
void test_DESC(){
	intFunc start = _gm_cargarPrograma(1, "DESC");
	if(start){
		_gp_crearProc(start, 1, "DESC", 1);
	} else{
		_gg_escribir("ERROR: No se pudo cargar TADD\n", 0, 0, 0);
	}
}
*/

/**
 * El programa de control mai pintará el grafic de espai ocupat
 * perque _gm_reservarMem crida a _gs_pintarFranjas, que com el
 * numero de zocalo es 0, interpreta que ha de borrar. 
*/
//------------------------------------------------------------------------------
int main(int argc, char **argv) {
//------------------------------------------------------------------------------
	inicializarSistema();
	_gg_escribir("********************************", 0, 0, 0);
	_gg_escribir("*                              *", 0, 0, 0);
	_gg_escribir("* Sistema Operativo GARLIC 2.0 *", 0, 0, 0);
	_gg_escribir("*                              *", 0, 0, 0);
	_gg_escribir("********************************", 0, 0, 0);
	_gg_escribir("*** Joc de proves fase 2 / ProgM\n", 0, 0, 0);

	if(test0()){
		//test_DESC();
		test_TADD();
	}
	//eliminaProc(2);
	
	_gg_escribir("\n*** Final joc de proves fase 2 / ProgM\n", 0, 0, 0);
	while (1){
		_gp_WaitForVBlank();
		gestionSincronismos();	//per borrar grafics al acabar...
	}
	return 0;
}