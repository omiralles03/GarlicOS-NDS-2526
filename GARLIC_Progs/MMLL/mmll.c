/*------------------------------------------------------------------------------

	"mmll.c" : Programa per trobar el mínim i màxim en una llista
	           de números aleatoris de 64 bits. Programa usuari progM

	Genera 100^(arg+1) números aleatoris llargs (long long), on arg
	és l'argument rebut [0..3]. Troba i mostra el mínim i el màxim.

------------------------------------------------------------------------------*/

#include <GARLIC_API.h>

// Funcio per calcular potencies de 100
unsigned long long _power100(int exp) {
	unsigned long long res = 1;
	int i;
	for (i = 0; i < exp; i++) {
		res *= 100;
	}
	return res;
}

// Funció per generar un random de 64 bits combinant dos de 32 bits
long long _GARLIC_random64() {
	//dues parts de 32 bits
	unsigned int part_alta = (unsigned int)GARLIC_random();
	unsigned int part_baixa = (unsigned int)GARLIC_random();

	//combinació 32+32 en (64 bits)
	long long resultat = ((long long)part_alta << 32) | part_baixa;
	return resultat;
}

int _start(int arg)				/* funció d'inicio: no se usa 'main' */
{
	unsigned long long num_elements;
	long long min_val, max_val;
	long long current_val;
	unsigned long long i;
	int pid = GARLIC_pid();

	//validació argument
	if (arg < 0) arg = 0;
	else if (arg > 3) arg = 3;
	num_elements = _power100(arg + 1); //mida llista

	GARLIC_printf("-- Programa MMLL - PID (%d) --\n", pid, 0, 0);
	//Mostrar mida.
	GARLIC_printf("Generant 100^%d elements...\n", arg + 1, 0, 0);

	//Generació primer num i min/max
	if (num_elements > 0) {
		min_val = max_val = _GARLIC_random64();
	} else {
        GARLIC_printf("Nombre d'elements 0. No es pot calcular min/max.\n", 0, 0, 0);
        return 0; // No hi ha res a fer si la llista és buida
    }


	//anar generant numeros i actualització min i max
	for (i = 1; i < num_elements; i++) {
		current_val = _GARLIC_random64();
		if (current_val < min_val) {
			min_val = current_val;
		}
		if (current_val > max_val) {
			max_val = current_val;
		}
	}

	//Print dels resultats (part alta i baixa en hexadecimal)
	//separo 64 bits dos parts de 32 per poder imprimir-los amb %x
	unsigned int min_alta = (unsigned int)(min_val >> 32);
	unsigned int min_baixa = (unsigned int)(min_val & 0xFFFFFFFF);
	unsigned int max_alta = (unsigned int)(max_val >> 32);
	unsigned int max_baixa = (unsigned int)(max_val & 0xFFFFFFFF);

	GARLIC_printf("Calcul finalitzat.\n", 0, 0, 0);
	GARLIC_printf("Minim: %x%x (Hex Alta, Baixa)\n", min_alta, min_baixa, 0);
	GARLIC_printf("Maxim: %x%x (Hex Alta, Baixa)\n", max_alta, max_baixa, 0);

	GARLIC_printf("-- Fi Programa MMLL - PID (%d) --\n", pid, 0, 0);
	return 0;
}