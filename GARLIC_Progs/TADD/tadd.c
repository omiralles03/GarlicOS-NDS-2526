/*------------------------------------------------------------------------------

	"tadd.c" : Programa de prova per funcionalitats addicionals progM:
						GARLIC_malloc() i GARLIC_free().

	Reserva blocs de memòria, escriu, prova els límits i allibera la memòria.

------------------------------------------------------------------------------*/

#include <GARLIC_API.h>	

int _start(int arg) {
	void *p1, *p2;	
	GARLIC_printf("TEST INICIO PROVANT MEMORIA DINAMICA\n", 0, 0, 2);
	
	p1 = GARLIC_malloc(64);	//2 franges
	
	if(p1) GARLIC_printf("- P1 en %x\n", p1, 0, 2);
	
	GARLIC_delay(2);
	
	p2 = GARLIC_malloc(32); // 1 franja
    if (p2) GARLIC_printf("- P2 en %x\n", p2);
	
	GARLIC_delay(4);
	
	GARLIC_free(p1);
    GARLIC_free(p2);
	
	GARLIC_printf("TEST FIN\n", 0, 0, 2);
    return 0;
}