/*------------------------------------------------------------------------------

	"tadd.c" : Programa de prova per funcionalitats addicionals progM:
						GARLIC_malloc() i GARLIC_free().

	Reserva blocs de memòria, escriu, prova els límits i allibera la memòria.

------------------------------------------------------------------------------*/

#include <GARLIC_API.h>	

int _start(int arg)
{
	int num_errors = 0;	//contador errors
	void *p[5]; // Array per guardar fins a 5 punters (l'últim ha de fallar)
	int i;
	int pid = GARLIC_pid(); // Obtenim el PID per als missatges

	GARLIC_printf("-- Programa TADD - PID (%d) --\n", pid);
	GARLIC_printf("Prova GARLIC_malloc()\n");

	//Intent de reservar 4 blocs de diferents mides
	for (i = 0; i < 4; i++) {
		int mida = (i + 1) * 10; // Reservem 10, 20, 30, 40 bytes
		p[i] = GARLIC_malloc(mida);
		if (p[i] != 0) {
			GARLIC_printf("  Bloc %d (%d bytes) reservat a: %x\n", i, mida, (unsigned int)p[i]);
			// Prova escritura
			*((char*)p[i]) = (char)('A' + i);
		} else {
			GARLIC_printf("ERROR: No s'ha pogut reservar el bloc %d (%d bytes)\n", i, mida);
			num_errors+=1;
		}
	}

	//Intent reservar un cinquè bloc (hauria de fallar)
	GARLIC_printf("Intent reservar 5è bloc\n");
	p[4] = GARLIC_malloc(50);
	if (p[4] == 0) {
		GARLIC_printf("  OK: El 5è malloc ha retornat 0 com s'esperava.\n");
	} else {
		GARLIC_printf("  ERROR: El 5è malloc ha retornat un punter (%x)! No hauria de poder.\n", (unsigned int)p[4]);
		num_errors+=1;
		// Si per error s'ha reservat, l'alliberem
		GARLIC_free(p[4]);
	}

	//Intentar alliberar un bloc
	GARLIC_printf("Prova GARLIC_free() bloc 1 (%x)\n", (unsigned int)p[1]);
	if (p[1] != 0) {
		int resultat_free = GARLIC_free(p[1]);
		if (resultat_free != 0) {
			GARLIC_printf("OK: Bloc 1 alliberat correctament.\n");
			p[1] = 0; // Marquem el punter com a alliberat
		} else {
			GARLIC_printf("ERROR: GARLIC_free() ha fallat per al bloc 1.\n");
			num_errors+=1;
		}
	} else {
		GARLIC_printf("INFO: Bloc 1 no estava reservat, no es pot alliberar.\n");
	}

	//Intent reservar un altre bloc
	GARLIC_printf("Intentant reservar un nou bloc (ara hauria de funcionar)...\n");
	p[4] = GARLIC_malloc(15); //nou bloc
	if (p[4] != 0) {
		GARLIC_printf("OK: Nou bloc reservat a: %x\n", (unsigned int)p[4]);
		*((char*)p[4]) = 'Z'; //prova escriptura
	} else {
		GARLIC_printf("ERROR: No s'ha pogut reservar el nou bloc després de free.\n");
		num_errors+=1;
	}

	//Intent alliberar un punter invàlid (adreça random)
	GARLIC_printf("Intentant alliberar punter invàlid (0x1234)...\n");
	int resultat_free_invalid = GARLIC_free((void *)0x1234);
	if (resultat_free_invalid == 0) {
		GARLIC_printf("OK: GARLIC_free() ha retornat 0 per a punter invàlid.\n");
	} else {
		GARLIC_printf("ERROR: GARLIC_free() no ha detectat un punter invàlid.\n");
		num_errors+=1;
	}

	//Alliberar la resta de blocs
	GARLIC_printf("Alliberar la resta de blocs\n");
	for (i = 0; i < 5; i++) {
		if (p[i] != 0) { // Alliberem només els que no hem alliberat abans
			if (GARLIC_free(p[i]) != 0) {
				GARLIC_printf("Bloc a %x alliberat.\n", (unsigned int)p[i]);
			} else {
				GARLIC_printf("ERROR alliberant bloc a %x.\n", (unsigned int)p[i]);
				num_errors+=1;
			}
		}
	}

	GARLIC_printf("-- Fi Programa TADD - PID (%d) --\n", pid);
	return num_errors;
}