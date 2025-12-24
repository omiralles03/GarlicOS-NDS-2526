/*------------------------------------------------------------------------------

	"DNIF.c" : programa de usuario del progP para el sistema operativo GARLIC 1.0;
	
	Calcula la letra del DNI en funcion del numero del DNI (aleatorio) 
	y su tipo de DNI (segun el arg)
------------------------------------------------------------------------------*/

#include <GARLIC_API.h>			/* definiciï¿½n de las funciones API de GARLIC */

// Devuelve un numero aleatorio dentro del rango especificado por los parametros,
// usando la funcion GARLIC_random que genera numeros de 32 bits
// y la funcion GARLIC_divmod para obtener el modulo de la division
unsigned int random_inRange(unsigned int range, unsigned int min)
{
	unsigned int mod, quo;
	GARLIC_divmod(GARLIC_random(), range, &quo, &mod); // GARLIC_random() % range
	return (mod + min);
}

/* Proceso dnif, con llamadas a las funciones del API del sistema Garlic */
//------------------------------------------------------------------------------
int _start(int tipoDNI)
//------------------------------------------------------------------------------
{
	GARLIC_printf("-- Programa DNIF  -  PID (%d) --\n", GARLIC_pid());
	
	// tipoDNI = 0 -> DNI, tipoDNI = 1 -> NIE
	if(tipoDNI > 1 || tipoDNI < 0)
	{
		tipoDNI = 0;		// Asumir tipo como DNI si el argumento es incorrecto
	}
	
	unsigned int numDNI;	// Numero asignado al DNI
	char letraDNI;			// Letra asignada al DNI
	unsigned int residuo; 	// Residuo del DNI para saber su letra
	unsigned int quo;		// quociente para GARLIC_divmod
	char* letras = "TRWAGMYFPDXBNJZSQVHLCKE";
		// Letras que pueden ser asignadas al DNI
		
	short digitoNIE;
	
	if (tipoDNI) // NIE
	{		
		digitoNIE = random_inRange(3, 0); 			// Obtener num. aleatorio de 1 cifra
		unsigned int numNIE = random_inRange(9000000, 1000000); // Obtener num. aleatorio de 7 cifras
		numDNI = digitoNIE * 10000000 + numNIE; 		// Obtener numDNI (concatenar digitoNIE con numNIE)
	}
	else	// DNI
	{
		numDNI = random_inRange(90000000, 10000000); 	// Obtener num. aleatorio de 8 cifras
	}
	
	GARLIC_divmod(numDNI, 23, &quo, &residuo);	// Obtener el residuo del DNI para saber su letra
	letraDNI = letras[residuo];					// Obtener letra del DNI
	
	if (tipoDNI) // NIE
	{
		short letraInicial; 
		if(digitoNIE == 0) letraInicial = 'X';
		if(digitoNIE == 1) letraInicial = 'Y';
		else letraInicial = 'Z';
		
		GARLIC_printf("\nNIE: %c-%d", letraInicial, numDNI);
		GARLIC_printf("%c\n\n", letraDNI);
	}
	else	// DNI
	{
		GARLIC_printf("\nDNI: %d-%c\n\n", numDNI, letraDNI);
	}
	return (int)letraDNI;
}
