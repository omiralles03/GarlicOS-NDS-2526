/*------------------------------------------------------------------------------

	"main.c" : fase 1 / programador P

	Programa de prueba de creación y multiplexación de procesos en GARLIC 1.0,
	pero sin cargar procesos en memoria ni utilizar llamadas a _gg_escribir().

------------------------------------------------------------------------------*/
#include <nds.h>
#include <stdio.h>

#include <garlic_system.h>	// definición de funciones y variables de sistema

#include <GARLIC_API.h>		// inclusión del API para simular un proceso
int hola(int);				// función que simula la ejecución del proceso
int colz(int);				// funció que simula l'execució del procés collatz
unsigned int power_of_10(int exp); // funció auxiliar per a colz
int proc_sender_bustia0(int arg);
int proc_receiver_bustia0(int arg);
int proc_filler_bustia1(int arg);
int proc_drainer_bustia1(int arg);


extern int * punixTime;		// puntero a zona de memoria con el tiempo real


/* Inicializaciones generales del sistema Garlic */
//------------------------------------------------------------------------------
void inicializarSistema() {
//------------------------------------------------------------------------------
	int i;

	consoleDemoInit();		// inicializar consola, sólo para esta simulación
	
	_gd_seed = *punixTime;	// inicializar semilla para números aleatorios con
	_gd_seed <<= 16;		// el valor de tiempo real UNIX, desplazado 16 bits
	
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
	int tics_espera, i;
	
	inicializarSistema();
	
	printf("********************************");
	printf("* *");
	printf("* Sistema Operativo GARLIC 1.0 *");
	printf("* *");
	printf("********************************");
	printf("*** Inicio fase 1_P\n");
	
	// -----------------------------------------------------------------
	// JOC DE PROVES ORIGINAL
	// -----------------------------------------------------------------
	_gp_crearProc(hola, 7, "HOLA", 1);
	_gp_crearProc(hola, 14, "HOLA", 2);

	while (_gp_numProc() > 1)
	{
		_gp_WaitForVBlank();
		printf("*** Test HOLA (PID 0) %d:%d\n", _gd_tickCount, _gp_numProc());
		
	}																		// esperar a que terminen los procesos de usuario

	printf("*** Final fase 1_P (Test HOLA acabat)\n");
	printf("\n*** JOC DE PROVES ADDICIONAL ***\n\n");
	
	// -----------------------------------------------------------------
	// TEST 1: Programa d'usuari 'colz'
	// -----------------------------------------------------------------
	printf("--- TEST 1: Creant 2 proc. 'colz' ---\n");
	_gp_crearProc(colz, 6, "COLZ", 1); // arg=1 -> limit 10^6
	_gp_crearProc(colz, 9, "COLZ", 2); // arg=2 -> limit 10^7

	// Esperem que acabin els 2 processos 'colz'
	
	printf("Esperant que acabin els proc. 'colz'...\n"); 
	while (_gp_numProc() > 1) {
		_gp_WaitForVBlank(); 

		
		if ((_gd_tickCount % 60) == 0) {
			printf("*** Test COLZ (PID 0) %d:%d\n", _gd_tickCount, _gp_numProc());
		}
		
		for (i = 0; i < 100; i++) {											// Ralentim l'execució.
			_gp_WaitForVBlank();
		}
		
	}
	printf("--- TEST 1: 'colz' finalitzat ---\n\n");

	// -----------------------------------------------------------------
	// TEST 2: Bústies (Test de Bloqueig i Desbloqueig)
	// -----------------------------------------------------------------
	printf("--- TEST 2: Creant RECEPTOR a BUSTIA0 (es bloquejara)...\n");
	_gp_crearProc(proc_receiver_bustia0, 7, "RECV0", 0); // Zócalo 7

	// Deixem 1 segon (aprox 60 tics) perquè el receptor s'executi i es bloquegi
	tics_espera = _gd_tickCount + 60;
	while (_gd_tickCount < tics_espera && _gp_numProc() > 1) {
		 _gp_WaitForVBlank();
		 printf("*** Test BÚSTIA 2 (PID 0) %d:%d\n", _gd_tickCount, _gp_numProc());
		 
		 for (i = 0; i < 100; i++) {											// Ralentim l'execució.
			_gp_WaitForVBlank();
		}
	}
	
	printf("--- TEST 2: Creant EMISSOR a BUSTIA0 (desbloquejara RECEPTOR)...\n");
	_gp_crearProc(proc_sender_bustia0, 14, "SEND0", 0);

	// Esperem que acabin els dos
	while (_gp_numProc() > 1) {
		_gp_WaitForVBlank();
		printf("*** Test BÚSTIA 2 (PID 0) %d:%d\n", _gd_tickCount, _gp_numProc());
		
		for (i = 0; i < 100; i++) {											// Ralentim l'execució.
			_gp_WaitForVBlank();
		}
	}
	printf("--- TEST 2: Send/Receive finalitzat ---\n\n");

	// -----------------------------------------------------------------
	// TEST 3: Bústies (Test de Bústia Plena i Buidat)
	// -----------------------------------------------------------------
	printf("--- TEST 3: Creant FILLER per omplir BUSTIA1...\n");
	_gp_crearProc(proc_filler_bustia1, 5, "FILL1", 0);
	
	// Esperem que el FILLER acabi
	while (_gp_numProc() > 1) {
		_gp_WaitForVBlank();
		printf("*** Test BUSTIA 3 (PID 0) %d:%d\n", _gd_tickCount, _gp_numProc());
		
		for (i = 0; i < 100; i++) {											// Ralentim l'execució.
			_gp_WaitForVBlank();
		}
	}
	printf("--- TEST 3: FILLER ha acabat. BUSTIA1 hauria d'estar plena.\n");

	printf("--- TEST 3: Creant DRAINER per buidar BUSTIA1...\n");
	_gp_crearProc(proc_drainer_bustia1, 6, "DRAIN1", 0);

	// Esperem que el DRAINER acabi
	while (_gp_numProc() > 1) {
		_gp_WaitForVBlank();
		printf("*** Test BUSTIA 3 (PID 0) %d:%d\n", _gd_tickCount, _gp_numProc());
		
		for (i = 0; i < 100; i++) {											// Ralentim l'execució.
			_gp_WaitForVBlank();
		}
	}
	printf("--- TEST 3: DRAINER ha acabat.\nBUSTIA1 hauria d'estar buida.\n\n");
	printf("*** TOTS ELS JOCS DE PROVA FINALITZATS ***\n");

	while (1)
	{
		_gp_WaitForVBlank();
	}							// parar el procesador en un bucle infinito
	return 0;
}


/* Proceso de prueba, con llamadas a las funciones del API del sistema Garlic */
//------------------------------------------------------------------------------
int hola(int arg) {
//------------------------------------------------------------------------------
	unsigned int i, j, iter;
	
	if (arg < 0) arg = 0;			// limitar valor máximo y 
	else if (arg > 3) arg = 3;		// valor mínimo del argumento
	
									// escribir mensaje inicial
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

// --------------------------FUNCIONALITATS ADDICIONALS-------------------------

/* Procés Emissor (Bústia 0): Envia 2 valors i acaba */
int proc_sender_bustia0(int arg) {
	int ret;
	int i; 
	GARLIC_printf("SENDER_bustia0(PID %d): Iniciant...\n\n", GARLIC_pid());
	
	// Enviar una dada
	GARLIC_printf("SENDER_bustia0(PID %d):\n123 a BUSTIA0...\n\n", GARLIC_pid());
	ret = GARLIC_send(0, 123); // Envia 123 a bústia 0
	GARLIC_printf("SENDER_bustia0(PID %d):\nHa retornat %d (esperat 1)\n\n", GARLIC_pid(), ret);

	// Esperar una mica (per provar el buffer)
	for(i = 0; i < 30; i++) _gp_WaitForVBlank(); 

	// Enviar una altra dada
	GARLIC_printf("SENDER_bustia0(PID %d):\n456 a BUSTIA0...\n\n", GARLIC_pid());
	ret = GARLIC_send(0, 456); // Envia 456 a bústia 0
	GARLIC_printf("SENDER_bustia0(PID %d):\nHa retornat %d (esperat 1)\n\n", GARLIC_pid(), ret);

	GARLIC_printf("SENDER_bustia0(PID %d):\nFinalitzant.\n\n", GARLIC_pid());
	return 0;
}

/* Procés Receptor (Bústia 0): Rep 2 valors (el primer bloquejant) i acaba */
int proc_receiver_bustia0(int arg) {
	int data;
	GARLIC_printf("RECEIVER_bustia0(PID %d):\nIniciant...\n\n", GARLIC_pid());

	// Rebre la primera dada (hauria de bloquejar)
	GARLIC_printf("RECEIVER_bustia0(PID %d):\nEsperant dada de BUSTIA0 (bloquejant)\n\n", GARLIC_pid());
	data = GARLIC_receive(0); // Rep de bústia 0
	GARLIC_printf("RECEIVER_bustia0(PID %d):\nRebuda dada: %d (esperat 123)\n\n", GARLIC_pid(), data);

	// Rebre la segona dada (hauria d'estar al buffer)
	GARLIC_printf("RECEIVER_bustia0(PID %d):\nEsperant 2a dada de BUSTIA0 (no hauria de bloquejar)\n\n", GARLIC_pid());
	data = GARLIC_receive(0); // Rep de bústia 0
	GARLIC_printf("RECEIVER_bustia0(PID %d):\nRebuda 2a dada: %d (esperat 456)\n\n", GARLIC_pid(), data);

	GARLIC_printf("RECEIVER_bustia0(PID %d):\nFinalitzant.\n\n", GARLIC_pid());
	return 0;
}

/* Procés "Filler" (Bústia 1): Omple la bústia i prova l'error de "ple" */
int proc_filler_bustia1(int arg) {
	int i, ret;
	GARLIC_printf("FILLER_bustia1(PID %d):\nOmplint bustia 1\n\n", GARLIC_pid());
	
	// Omplim les 16 posicions
	for (i = 0; i < 16; i++) {
		ret = GARLIC_send(1, i + 1000); // Envia 1000, 1001, ..., 1015
		if (ret == 0) {
			GARLIC_printf("FILLER_bustia1(PID %d): ERROR\nEnviament %d ha fallat!\n\n", GARLIC_pid(), i);
		}
	}
	GARLIC_printf("FILLER_bustia1(PID %d):\nBustia 1 plena (16 elements).\n\n", GARLIC_pid());

	// Intentem enviar el 17è (hauria de fallar)
	ret = GARLIC_send(1, 9999);
	GARLIC_printf("FILLER_bustia1(PID %d):\nIntentant enviar a bustia plena...\nRetorn: %d (esperat 0)\n\n", GARLIC_pid(), ret);

	GARLIC_printf("FILLER_bustia1(PID %d):\nFinalitzant.\n\n", GARLIC_pid());
	return 0;
}

/* Procés "Drainer" (Bústia 1): Buidar la bústia */
int proc_drainer_bustia1(int arg) {
	int y = 0;
	int data = 0;
	int z = 0;
	GARLIC_printf("DRAINER_bustia1(PID %d):\nBuidant bustia 1\n\n", GARLIC_pid());

	// Buidem les 16 posicions
	for (y = 0; y < 16; y++) {
		data = GARLIC_receive(1); // Rep de bústia 1
		GARLIC_printf("DRAINER_bustia1(PID %d):Rebuda dada %d\n\n", GARLIC_pid(), data);
		
		for (z = 0; z < 50; z++) {											// Ralentim l'execució.
			_gp_WaitForVBlank();
		}
		
	}
	GARLIC_printf("DRAINER_bustia1(PID %d):\nBustia 1 buida.\n\n", GARLIC_pid());

	GARLIC_printf("DRAINER_bustia1(PID %d):\nFinalitzant.\n\n", GARLIC_pid());
	return 0;
}


// ---------------------------PROGRAMA D'USUARI --------------------------------

// Funcio per calcular potències de 10.
// Parametres: El valor del exponent a calcular.
// Retorn: 10^exp.
unsigned int power_of_10(int exp)
{
	unsigned int result = 1;
	int i;
	for (i = 0; i<exp; i++)
	{	
		if (result > 0xFFFFFFFF / 10)			// Mirem si hi ha overflow. En cas de que n'hi hagi, retornem el valor maxim de 32 bits. (0xFFFFFFFF);
		{
			return 0xFFFFFFFF;
		}
		result *= 10;
	}
	return result;
}


int colz(int arg)
{
	unsigned int limit, random_num, n, num_actual, passos = 0, quocient, residu;
	int exponent;
	
	if (arg < 0) arg = 0;												// Validem i ajustem l'argument.
	else if (arg > 3) arg = 3;
	
	GARLIC_printf("--- Programa COLZ (PID %d) ---\n", GARLIC_pid());	// Mostrem per pantalla quin procès està executant el programa.
	GARLIC_printf("Argument rebut: %d\n", arg);							// Mostrem per pantalla quin argument ha rebut el programa.
	
	
	// Calculem el  límit = 10^(arg+5)
	exponent = arg+5;
	limit = power_of_10(exponent);
	if (limit == 0xFFFFFFFF && exponent > 0)							// Mirem si hi ha overflow al calcular el límit.
	{
		GARLIC_printf("Avís: El limit 10^%d desborda 32 bits!\n\n", exponent);
	}
	GARLIC_printf("Limit superior: %d (10^%d)\n\n", limit, exponent);
	
	
	// Generem número aleatori n = GARLIC_random() % limit
	if (limit == 0)
	{
		n = 0;
	}
	else
	{
		// Calculem random_num % limit.
		random_num = GARLIC_random();
		GARLIC_divmod(random_num, limit, &quocient, &n);
	}
	
	GARLIC_printf("Numero aleatori generat n = %d\n\n", n);
	
	// Comprovem la conjuctura de Collatz per n
	num_actual = n;
	
	if (num_actual == 0)
	{
		GARLIC_printf("n = 0, no s'aplica la sequencia.\n\n");
	}
	else
	{
		GARLIC_printf("Iniciant Collatz per %d...\n\n", num_actual);
		unsigned int max_passos = 100000;								// Límit de passos per evitar bucles infinits.
		
		while (num_actual > 1 && passos < max_passos)
		{
			GARLIC_divmod(num_actual, 2, &quocient, &residu);			// Comprovem si és parell.
				
			if(residu == 0)												// És parell.
			{
				num_actual = quocient;
			}
			else														// És senar
			{
				// Comprovem el desbordament ABANS de multiplicar (només 32 bits)
				// Si num_actual > (MAX_INT - 1) / 3, llavors 3*n+1 desbordarà
				if (num_actual > 1431655765) // 1431655765 és (0xFFFFFFFF - 1) / 3
				{
					GARLIC_printf("ATENCIO: Desbordament calculant 3n+1!\n\n");
					passos = max_passos;
					break;
				}

				// Ara sabem que és segur multiplicar amb 32 bits
				num_actual = 3 * num_actual + 1;
			}
			passos++;
		}
		
		if (num_actual == 1)
		{
			GARLIC_printf("Sequencia feta en %d passos.\n\n", passos);
		}
		else if (passos >= max_passos)
		{
			GARLIC_printf("Aturat despres de %d passos (limit assolit).\n\n", max_passos);
		}
		else
		{
			GARLIC_printf("Error inesperat, no s'ha arribat a 1.\n\n");
		}
	}
	
	GARLIC_printf("--- FI PROGRAMA COLZ (PID %d) ---\n", GARLIC_pid());

	return 0;
}