/*------------------------------------------------------------------------------

	"main.c" : fase 2 / progM

	Versión final de GARLIC 2.0
	(carga de programas con 2 segmentos, listado de programas, gestión de
	 franjas de memoria)

------------------------------------------------------------------------------*/
#include <nds.h>

#include "garlic_system.h"	// definición de funciones y variables de sistema

extern int * punixTime;		// puntero a zona de memoria con el tiempo real

const short divFreq1 = -33513982/(1024*7);		// frecuencia de TIMER1 = 7 Hz



/* gestionSincronismos:	función para detectar cuándo un proceso ha terminado
						su ejecución, consultando el bit i-éssimo de la
						variable global _gd_sincMain; en caso de detección,
						libera la memoria reservada para el proceso del zócalo
						i-éssimo y pone el bit de _gd_sincMain a cero.
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



/* esperaSegundos:	función para esperar un cierto número de segundos, usando
					la variable global _gd_tickCount.
*/
void esperaSegundos(unsigned char nsecs)
{
	unsigned int mtics;

	mtics = _gd_tickCount + (nsecs * 60);
	while (_gd_tickCount < mtics)		// esperar un cierto número de segundos
	{
		_gp_WaitForVBlank();
		gestionSincronismos();
	}
}



/* eliminaProc:	función para provocar la finalización de un proceso de usuario;
				si el zócalo indicado por parámetro contiene un proceso, libera
				la entrada del vector de PCBs correspondiente y busca el zócalo
				en la cola de READY, para eliminar dicha entrada de la cola
				(compactándola), decrementar número de procesos en Ready,
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




/* test 0: 	test de obtención de los programas de usuario contenidos en el
			directorio "/Programas/" del disco de la NDS, llamando a la
			función _gm_listaProgs(); la función test0() muestra por pantalla
			(ventana 0) la lista de programas obtenida, y verifica si en la
			lista se encuentran 4 programas necesarios para realizar el resto
			de tests; en caso negativo, muestra un mensaje de error y devuelve
			cero; en caso positivo, devuelve 1.
*/
unsigned char test0()
{
	char *progs[16];	// se asume que para realizar este test nunca habrá más
						// de 16 programas de usuario contenidos en "/Programas/"
	char *expected[6] = {"DESC", "LABE", "PONG", "PRNT", "TADD", "MMLL"};
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
		k = 0;				// máscara de bits para los programas esperados
		for (i = 0; i < num_progs; i++)
		{
			_gg_escribir((i < 10 ? "\t %d: %s\t" : "\t%d: %s\t"), i, (unsigned int) progs[i], 0);
			j = 0;
			while ((k != 63) && (j < 6))
			{
				if (((k & (1 << j)) == 0) && (strcmp(progs[i], expected[j]) == 0))
					k |= (1 << j);		// activa el bit de un programa esperado
				j++;
			}
		}
		_gg_escribir((i & 1 ? "\n\n" : "\n"), 0, 0, 0);
		if (k != 63)
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
	}
	return result;
}




/* test 1: 	test de carga de programas de usuario de forma consecutiva (DESC,
			LABE, PRNT), sin fragmentación de la memoria, comprobando que 
			funciona la carga de programas con uno o dos segmentos; esta
			función de test espera a que PRNT acabe y elimina DESC, dejando
			el programa LABE en marcha para crear un principio de fragmentación
			externa; la función devuelve 0 si se han podido cargar los tres
			programas, o 1 si ha habido algun problema con la carga de uno de
			los programas.
*/
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
	if (start[0] && start[1] && start[2])	// verficación de carga
	{
		for (i = 0; i < 3; i++)		// se asume que siempre se podrán crear
		{							// los tres procesos asociados
			_gp_crearProc(start[i], i+1, expected[i], i);
		}
		while (_gp_numProc() > 3)	// espera finalicación de PRNT
		{
			_gp_WaitForVBlank();
			gestionSincronismos();
		}
		eliminaProc(1);		// fuerza la finalización de DESC (para acelerar el test)
	}
	else
	{
		_gg_escribir("\nERROR: algun programa no se ha podido cargar!\n", 0, 0, 0);
		result = 0;
	}
	return result;
}




/* test 2: 	test de carga de programas de usuario de forma NO consecutiva,
			aprovechando la fragmentación externa generada en el test 1;
			se carga el programa PONG para limitar el primer espacio de memoria
			disponible, y después se carga el DESC de manera que primero se
			cargará el segmento de código y después el segmento de datos después
			de la memoria reservada para el programa LABE (en el test anterior);
			si el DESC funciona correctamente, la reubicación habrá funcionado
			para segmentos de código y datos separados (no consecutivos);
			después de un cierto tiempo, la función eliminará el PONG e
			intentará cargar otro LABE, el cual cargará el segmento de datos
			en posiciones inferiores a las del segmento de código; la función
			devuelve 0 si se han podido cargar los tres programas, o 1 si ha
			habido algun problema con la carga de uno de los programas.
*/
unsigned char test2()
{
	char *expected[3] = {"PONG", "DESC", "LABE"};
	unsigned char zoc[3] = {5, 11, 9};
	intFunc start[3];
	unsigned char result = 0;

	_gg_escribir("\n** TEST 2: carga no consecutiva\n\tPONG | DESC **\n", 0, 0, 0);
	start[0] = _gm_cargarPrograma(zoc[0], expected[0]);
	start[1] = _gm_cargarPrograma(zoc[1], expected[1]);
	if (start[0] && start[1])		// verficación de carga
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



/* Inicializaciones generales del sistema Garlic */
void inicializarSistema()
{
	_gg_iniGrafA();			// inicializar procesadores gráficos
	_gs_iniGrafB();
	_gs_dibujarTabla();

	_gd_seed = *punixTime;	// inicializar semilla para números aleatorios con
	_gd_seed <<= 16;		// el valor de tiempo real UNIX, desplazado 16 bits
	
	_gd_pcbs[0].keyName = 0x4C524147;	// "GARL"
	
	if (!_gm_initFS())
	{
		_gg_escribir("\nERROR: ¡no se puede inicializar el sistema de ficheros!\n", 0, 0, 0);
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
	
	// Color Gris en format BGR555 (R=15, G=15, B=15) -> 
		//Hex aproximat: 0x3DEF. Escriure en index 96 (cada color son 2B)
			//BG_PALETTE_SUB definit a nds.h
	BG_PALETTE_SUB[1] = 0x3DEF;
}

/* test 3:  Funcionalidades Adicionales (TADD)
            Prueba malloc, free y visualización de franjas
*/
unsigned char test3()
{
	char *progName = "TADD";
	unsigned char zocalo = 3;
	intFunc start_tadd;
	unsigned char result = 0;

	_gg_escribir("\n** TEST 3: Funciones Adicionales\n\tTADD (Malloc/Free) **\n", 0, 0, 0);
	
	start_tadd = _gm_cargarPrograma(zocalo, progName);
	
	if (start_tadd)
	{
		_gp_crearProc(start_tadd, zocalo, progName, 0);
		
		_gg_escribir("Ejecutando TADD... (Mira la memoria)\n", 0, 0, 0);
		
		// Bucle espera
		while (_gd_pcbs[zocalo].PID != 0)
		{
			_gp_WaitForVBlank();
			gestionSincronismos();
		}
		
		_gg_escribir("TADD finalizado correctamente.\n", 0, 0, 0);
		result = 1;
	}
	else
	{
		_gg_escribir("\nERROR: No se pudo cargar TADD.elf\n", 0, 0, 0);
	}
	return result;
}

void eliminaProcs(){
	for (int i = 1; i <= 15; i++){
		eliminaProc(i);
	}
}

void test4_MMLL(){
	char *progName = "MMLL";
	unsigned char zocalo = 1; // Reutilitzo zocalo 1 (pq es visible)
	int args[3] = {0, 1, 2};              // Argument: 100^2 el.
	intFunc start_mmll;
	int i;

	_gg_escribir("\n** TEST 4: Programa MMLL (Calculo) **\n", 0, 0, 0);
	
	for (i = 0; i < 3; i++){
		_gg_escribir("-> Ejecutando MMLL con arg=%d...\n", args[i], 0, 0);
		start_mmll = _gm_cargarPrograma(zocalo, progName);
		
		if (start_mmll){
			_gp_crearProc(start_mmll, zocalo, progName, args[i]);
			while (_gd_pcbs[zocalo].PID != 0)	//esperar a que acabi
			{
				_gp_WaitForVBlank();
				gestionSincronismos();
			}
		} else {
			_gg_escribir("ERROR: En carrega MMLL (Iter %d)\n", i, 0, 0);
		}
		esperaSegundos(3); //visual
	}
	_gg_escribir("MMLL Test COMPLETED.\n", 0, 0, 0);

}

/* Saturació memòria*/
void test5_MemoriaFull()
{
	//PONG
	char *relleno = "DESC";  
	char *grande = "LABE";   // Programa amb 2 segments (Code+Data)
	intFunc start;
	int i;
	int cargados = 0;

	_gg_escribir("\n** TEST 5: ESTRES DE MEMORIA **\n", 0, 0, 0);
	_gg_escribir("(Emplenant memòria fins al max...)\n", 0, 0, 0);

	// Llenamos los zócalos 1 al 4 con DESC
	// Nota: Nomès _gm_cargarPrograma, NO creo proces
	for (i = 1; i <= 4; i++) {
		start = _gm_cargarPrograma(i, relleno);
		if (start) {
			cargados++;
		} else {
			_gg_escribir("Memoria llena en zocalo %d.\n", i, 0, 0);
			break; // Memoria llena antes de lo previsto
		}
	}
	_gg_escribir("S'han carregat %d copias de DESC.\n", cargados, 0, 0);

	esperaSegundos(2);
	
	// cargar LABE en zocal 13
	// Hauria de fallar
	_gg_escribir("Intentant cargar LABE (ha de fallar)...\n", 0, 0, 0);
	start = _gm_cargarPrograma(13, grande);
	
	esperaSegundos(2);

	if (start == 0) {
		_gg_escribir("OK: Carrega denegada (Full)\n", 0, 0, 0);
	} else {
		_gg_escribir("ERROR: S'ha carregat LABE\n", 0, 0, 0);
		// Si se carga, lo marcamos para borrarlo luego
		_gd_pcbs[13].PID = 0; 
		_gm_liberarMem(13); 
	}

	// lliberar manualment perque no he creat els processos
	_gg_escribir("Netejant...\n", 0, 0, 0);
	for (i = 1; i <= 12; i++) {
		_gm_liberarMem(i);
	}
	_gs_dibujarTabla(); // forçar resfrecada del grafic
}


//------------------------------------------------------------------------------
int main(int argc, char **argv) {
//------------------------------------------------------------------------------
	inicializarSistema();
	_gg_escribir("********************************", 0, 0, 0);
	_gg_escribir("*                              *", 0, 0, 0);
	_gg_escribir("* Sistema Operativo GARLIC 2.0 *", 0, 0, 0);
	_gg_escribir("*                              *", 0, 0, 0);
	_gg_escribir("********************************", 0, 0, 0);
	_gg_escribir("*** Inicio fase 2 / ProgM\n", 0, 0, 0);

	if (test0())
	{
		if (test1()){
			if(test2()){
				esperaSegundos(2);
				
				
				test3(); //Execució TADD per provar les addicionals
				_gg_escribir("\nNetejant pel TADD...\n", 0, 0, 0);
				esperaSegundos(1);
				eliminaProcs(); // Borrar LABE/DESC/PONG
				
				esperaSegundos(1);
				_gg_escribir("Preparant execució MMLL\n", 0, 0, 0);
				test4_MMLL();   // Execució MMLL per provar prog. usuari fase 1
				
				esperaSegundos(1);
				_gg_escribir("\nNetejant per STRESS test...\n", 0, 0, 0);
				esperaSegundos(1);
				//eliminaProcs();	
				test5_MemoriaFull();
				
				//Neteja final
				eliminaProcs();
			}
		}
			
	}
	_gg_escribir("\n*** Final fase 2 / ProgM\n", 0, 0, 0);
	while (1){
		_gp_WaitForVBlank();
		gestionSincronismos(); //per netejar
	} 
	return 0;
}