/*------------------------------------------------------------------------------

	"main.c" : fase 1 / programador M

	Programa de prueba de carga de un fichero ejecutable en formato ELF,
	pero sin multiplexación de procesos ni utilizar llamadas a _gg_escribir().
------------------------------------------------------------------------------*/
#include <nds.h>
#include <stdio.h>

#include <garlic_system.h>	// definición de funciones y variables de sistema

extern int * punixTime;		// puntero a zona de memoria con el tiempo real


/* Inicializaciones generales del sistema Garlic */
//------------------------------------------------------------------------------
void inicializarSistema() {
//------------------------------------------------------------------------------
	
	consoleDemoInit();		// inicializar console, sólo para esta simulación
	
	_gd_seed = *punixTime;	// inicializar semilla para números aleatorios con
	_gd_seed <<= 16;		// el valor de tiempo real UNIX, desplazado 16 bits

	if (!_gm_initFS())
	{
		printf("ERROR: ¡no se puede inicializar el sistema de ficheros!");
		exit(0);
	}
}


//------------------------------------------------------------------------------
int main(int argc, char **argv) {
//------------------------------------------------------------------------------
	intFunc start;
	inicializarSistema();

	printf("********************************");
	printf("*                              *");
	printf("* Sistema Operativo GARLIC 1.0 *");
	printf("*                              *");
	printf("********************************");
	printf("*** Inicio fase 1_M\n");
	
	printf("*** Carga de programa HOLA.elf\n");
	start = _gm_cargarPrograma("HOLA");
	if (start)
	{
		printf("*** Direccion de arranque :\n\t\t%p\n", start);
		printf("*** Pusle tecla \'START\' ::\n\n");
		do
		{	swiWaitForVBlank();
			scanKeys();
		} while ((keysDown() & KEY_START) == 0);
		
		start(1);		// llamada al proceso HOLA con argumento 1
	}
	else
		printf("*** Programa \"HOLA\" NO cargado\n");

	printf("\n\n\n*** Carga de programa PRNT.elf\n");
	start = _gm_cargarPrograma("PRNT");
	if (start)
	{
		printf("*** Direccion de arranque :\n\t\t%p\n", start);
		printf("*** Pusle tecla \'START\' ::\n\n");
		do
		{	swiWaitForVBlank();
			scanKeys();
		} while ((keysDown() & KEY_START) == 0);
		
		start(0);		// llamada al proceso PRNT con argumento 0
	}
	else
		printf("*** Programa \"PRNT\" NO cargado\n");

	printf("\n\n\n*** Carga de programa TADD.elf\n");
	printf("Prueba func. adicionales malloc y free\n");
	start = _gm_cargarPrograma("TADD");
	if (start)
	{
		printf("*** Direccion de arranque :\n\t\t%p\n", start);
		printf("*** Pusle tecla \'START\' ::\n\n");
		do
		{
			swiWaitForVBlank();
			scanKeys();
		} while ((keysDown() & KEY_START) == 0);

		int num_errors = start(0);
		printf("num. errors: %d\n", num_errors);
	}
	else
		printf("*** Programa \"TADD\" NO cargado\n");

	//**** Proves per a MMLL ****
	printf("\n*** Proves MMLL ***\n");
	intFunc start_mmll;
	//LA VERIFICACIÓ DE QUE EL MIN < MAX HA DE SER FETA VISUALMENT
	
	//execució única amb arg=1
	int arg_mmll = 1;
	printf("\n*** Carregant MMLL amb arg=%d (100^%d elements) ***\n", arg_mmll, arg_mmll + 1);
	start_mmll = _gm_cargarPrograma("MMLL");
	if (start_mmll) {
		printf("Direccio arranque: %p\n", start_mmll);
		printf("*** Pusle tecla \'START\' ::\n\n");
		do {
			swiWaitForVBlank();
			scanKeys();
		} while ((keysDown() & KEY_START) == 0);

		start_mmll(arg_mmll); //exec. amb arg=1 (llista de 100^2 pos.)
		printf("--- MMLL(arg=%d) finalitzat ---\n", arg_mmll);
	} else {
		printf("!!! ERROR carregant MMLL !!!\n");
	}

	//Execucions multiples amb arg=0
	arg_mmll = 0;
	int num_execucions_arg0 = 3; //3 exec. amb arg 0 (llista de 100^1 pos.)
	printf("\n--- Executant MMLL %d cops amb arg=%d (100^%d elements) ---\n",
			num_execucions_arg0, arg_mmll, arg_mmll + 1);

	for (int i = 0; i < num_execucions_arg0; i++) {
		printf("\n*** Carregant MMLL (Execució %d/%d amb arg=%d) ***\n", i + 1, num_execucions_arg0, arg_mmll);
		start_mmll = _gm_cargarPrograma("MMLL");
		if (start_mmll) {
					printf("Direccio arranque: %p\n", start_mmll);
					printf("*** Pusle tecla \'START\' ::\n\n");
			do {
				swiWaitForVBlank();
				scanKeys();
			} while ((keysDown() & KEY_START) == 0);

			start_mmll(arg_mmll); // Executem amb arg=0
			printf("MMLL(arg=%d, Exec. %d/%d) acabada ---\n", arg_mmll, i + 1, num_execucions_arg0);
		} else {
			printf("ERROR carregant MMLL (Execució %d/%d)\n", i + 1, num_execucions_arg0);
			//si falla carregar, sortir bucle
			break;
		}
	}

	printf("*** Final fase 1_M\n");	
	while (1)
	{
		swiWaitForVBlank();
	}							// parar el procesador en un bucle infinito
	return 0;
}

