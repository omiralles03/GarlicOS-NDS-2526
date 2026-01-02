/*------------------------------------------------------------------------------

	"tadd.c" : Programa de prova per funcionalitats addicionals progM:
						GARLIC_malloc() i GARLIC_free().

	Reserva blocs de memòria, escriu, prova els límits i allibera la memòria.

------------------------------------------------------------------------------*/

#include <GARLIC_API.h>	

int _start(int arg)
{
	void *p1, *p2, *p3;
	int num_errors = 0;
	
	GARLIC_printf("%1TADD:%0 Probando memoria dinamica...\n");/*
    // Reserva 1: Un bloc petit (3 franges)
    p1 = GARLIC_malloc(80); 
    if (p1) GARLIC_printf("P1 reservado en %x\n", p1);
    GARLIC_delay(2);

    // Reserva 2: (aprox 10 franjas)
    p2 = GARLIC_malloc(300);
    if (p2) GARLIC_printf("P2 reservado en %x\n", p2);
    GARLIC_delay(2);
*/
    // Reserva 3: Bloc consecutiu per veure patro franja inicial
    p3 = GARLIC_malloc(1000); 
/*    
	if (p3) GARLIC_printf("P3 (consecutivo) en %x\n", p3);
    GARLIC_delay(4);

    // Liberació 
    GARLIC_free(p2);
    GARLIC_printf("P2 liberado.\n");
    GARLIC_delay(2);
	GARLIC_free(p1);
*/
   
    GARLIC_free(p3);
    GARLIC_printf("Fin del test TADD.\n");

	GARLIC_delay(5);
	
	num_errors = 0;
    return num_errors;
}