/*------------------------------------------------------------------------------
    "colz.c": Programa d'usuari per a GarlicOS v1.0
    Comprova la conjectura de Collatz per a un número aleatori n
    en el rang [0, 10^(arg+5) - 1].

    Programador P: anthonyjohn.cardenas@estudiants.urv.cat
------------------------------------------------------------------------------*/

#include <GARLIC_API.h>

// Funció per calcular potències de 10.
// Paràmetres: El valor del exponent a calcular.
// Retorn: 10^exp.
unsigned int power_of_10(int exp)
{
	unsigned int result = 1;
	for (int i = 0; i<exp; i++)
	{	
		if (result > 0xFFFFFFFF / 10)			// Mirem si hi ha overflow. En cas de que n'hi hagi, retornem el valor màxim de 32 bits. (0xFFFFFFFF);
		{
			return 0xFFFFFFFF;
		}
		result *= 10;
	}
	return result;
}

// Funció principal del programa d'usuari
// 
int _start(int arg)
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
		GARLIC_printf("Avís: El límit 10^%d desborda 32 bits!\n", exponent);
	}
	GARLIC_printf("Límit superior: %d (10^%d)\n", limit, exponent);
	
	
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
	
	GARLIC_printf("Número aleatori generat n = %d\n", n);
	
	// Comprovem la conjuctura de Collatz per n
	num_actual = n;
	
	if (num_actual == 0)
	{
		GARLIC_printf("n = 0, no s'aplica la seqüència.\n");
	}
	else
	{
		GARLIC_printf("Iniciant Collatz per %d...\n", num_actual);
		unsigned int max_passos = 100000;								// Límit de passos per evitar bucles infinits.
		
		while (num_actual > 1 && passos < max_passos)
		{
			GARLIC_divmod(num_actual, 2, &quocient, &residu);			// Comprovem si és parell.
				
			if(residu == 0)												// És parell.
			{
				num_actual = quocient;
			}
			else														// És senar.
			{
				// Calculem 3* + 1 amb compte del overflow
				unsigned long long temp = (unsigned long long)3 * num_actual + 1;
				if (temp > 0xFFFFFFFF)
				{
					GARLIC_printf("ATENCIÓ: Desbordament calculant 3n+1!\n");
					passos = max_passos;
					break;
				}
				num_actual = (unsigned int)temp;
			}
			passos++;
		}
		
		if (num_actual == 1)
		{
			GARLIC_printf("Seqüència finaliztada en %d passos.\n", passos);
		}
		else if (passos >= max_passos)
		{
			GARLIC_printf("Aturat després de %d passos (límit assolit).\n", max_passos);
		}
		else
		{
			GARLIC_printf("Error inesperat, no s'ha arribat a 1.\n");
		}
	}
	
	GARLIC_printf("--- FI PROGRAMA COLZ (PID %d) ---\n", GARLIC_pid());

	return 0;
}



