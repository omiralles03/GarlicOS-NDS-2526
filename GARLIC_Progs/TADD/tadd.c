/*------------------------------------------------------------------------------

	"tadd.c" : Programa de prova per funcionalitats addicionals progM:
						GARLIC_malloc() i GARLIC_free().

	Reserva blocs de memòria, escriu, prova els límits i allibera la memòria.

------------------------------------------------------------------------------*/

#include <GARLIC_API.h>	

void mi_delay(int segundos) {
    int frames = segundos * 60; // 60 frames por segundo
    while (frames > 0) {
        GARLIC_delay(0); // Espera 1 frame (aprox 16ms) y cede CPU
        frames--;
    }
}

int _start(int arg) {
	void *p1, *p2, *p3, *p4, *p_fail;	
	int res;
	int res2;

	GARLIC_printf("[TADD %d] TEST MEMORIA DINAMICA\n", 0, 0, 0);
	
	// -------------------------------------------------------------
    // TEST VISUAL: Bloc Gran
    // -------------------------------------------------------------
    // 320 bytes / 32 = 10 franges.
    GARLIC_printf("Reserva Gran (10 franges)\n", 0, 0, 0);
    p1 = GARLIC_malloc(320);
	
	if(p1) GARLIC_printf("- p1(64B): OK en %x\n", p1, 0, 0);
	else GARLIC_printf("- p1 (64B): ERROR\n", 0, 0, 0);
	
	//GARLIC_delay(2); DECISION TO MAKE THE "MANUAL" DELAY BECAUSE OF PROGP 
		//DEPENDENCIES
	mi_delay(2);
	
	// -------------------------------------------------------------
    // TEST LIMIT: 4 slots pel proces
    // -------------------------------------------------------------
	GARLIC_printf("Emplenant slots (max 4)\n", 0, 0, 0);
    p2 = GARLIC_malloc(32); // Slot 2
    p3 = GARLIC_malloc(32); // Slot 3
    p4 = GARLIC_malloc(32); // Slot 4
	
	if(p2 && p3 && p4) GARLIC_printf("-OK: 4 blocs reservats\n", 0, 0, 0);
	else GARLIC_printf("-ERROR: en reserva 4 slots\n", 0, 0, 0);
 
	
	mi_delay(2);
	
	//Intentar reserva 5è
	GARLIC_printf("Intent 5o bloc...\n", 0, 0, 0);
    p_fail = GARLIC_malloc(32);
	
	if(p_fail == 0) GARLIC_printf(" -> OK: Bloquejat (retorno 0)\n", 0, 0, 0);
    else GARLIC_printf(" -> FAIL: S'ha permes la 5a reserva\n", 0, 0, 0);
	
	mi_delay(2);

	// -------------------------------------------------------------
    // TEST FREE ERRONI
    // -------------------------------------------------------------
	GARLIC_printf("Test Free Invalid\n", 0, 0, 0);
    // Intent de lliberar una direcció random (ej: 0xDEADBEEF)
    res = GARLIC_free((void*)0xDEADBEEF);
	
	if(res == 0) GARLIC_printf(" -> OK: Detectado ptr invalid\n", 0, 0, 0);
    else GARLIC_printf(" -> FAIL: Free ha acceptat brossa\n", 0, 0, 0);
	
	mi_delay(2);
	
	// -------------------------------------------------------------
    // TEST FRAGMENTACION (Huecos)
    // -------------------------------------------------------------
	GARLIC_printf("Test Huecos (Llibero P2)\n", 0, 0, 0);
	
    res2 = GARLIC_free(p3); // deixar hueco entre P2 y P4
    if(res2 == 0) GARLIC_printf(" -> FAIL: No s'ha esborrat\n", 0, 0, 0);
    else if(res2 == 1) GARLIC_printf(" -> OK: Free ha acceptat correctament\n", 0, 0, 0);
	
    mi_delay(2); // per veure hueco a pantalla

    GARLIC_printf(" Emplenant hueco...\n", 0, 0, 0);
    p3 = GARLIC_malloc(32); 
    if(p3) GARLIC_printf(" -> Re-reservt en %x\n", p3, 0, 0);

    mi_delay(2);
	
	// -------------------------------------------------------------
	//						NETEJA FINAL
	// -------------------------------------------------------------
	GARLIC_printf("Neteja final...\n", 0, 0, 0);
    GARLIC_free(p1);
    GARLIC_free(p2);
    GARLIC_free(p3);
    GARLIC_free(p4);
	
	GARLIC_printf("[TADD %d] END Test\n", 0, 0, 0);    
	return 0;
}