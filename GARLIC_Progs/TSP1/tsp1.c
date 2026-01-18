#include <GARLIC_API.h>			/* definiciï¿½n de las funciones API de GARLIC */

//------------------------------------------------------------------------------
int _start(int arg)
//------------------------------------------------------------------------------
{ 
	unsigned char n, icon;
	short px, py;
	GARLIC_printf("\n\n\n\n\n");
	n = 0; icon =0; px = 112; py = 80; // centre
	GARLIC_spriteSet(n, icon);
	GARLIC_spriteMove(n, px, py);
	GARLIC_spriteShow(n);
	GARLIC_printf("\n%0Sprite[%d]: ", n);
	GARLIC_printf("%0[%d, %d]\n", px, py);

	n = 1; icon =9; px = -16; py = -16; // superior esquerra
	GARLIC_spriteSet(n, icon);
	GARLIC_spriteMove(n, px, py);
	GARLIC_spriteShow(n);
	GARLIC_printf("\n%0Sprite[%d]: ", n);
	GARLIC_printf("%0[%d, %d]\n", px, py);
	
	n = 2; icon =15; px = 50; py = 80; // centre
	GARLIC_spriteSet(n, icon);
	GARLIC_spriteMove(n, px, py);
	GARLIC_spriteShow(n);
	GARLIC_printf("\n%0Sprite[%d]: ", n);
	GARLIC_printf("%0[%d, %d]\n", px, py);
			
	switch(arg) {
		case 0:
			n = 3; icon =3; px = 150; py = 150; // superior esquerra
			GARLIC_spriteSet(n, icon);
			GARLIC_spriteMove(n, px, py);
			GARLIC_spriteShow(n);
			GARLIC_printf("\n%0Sprite[%d]: ", n);
			GARLIC_printf("%0[%d, %d]\n", px, py);
			
			n = 4; icon =24; px = 220; py = 113; // centre
			GARLIC_spriteSet(n, icon);
			GARLIC_spriteMove(n, px, py);
			GARLIC_spriteShow(n);
			GARLIC_printf("\n%0Sprite[%d]: ", n);
			GARLIC_printf("%0[%d, %d]\n", px, py);
			break;
		case 1:
			n = 0;// centre
			GARLIC_spriteHide(n);
			n = 1; // superior esquerra
			GARLIC_spriteHide(n);
			n = 2; // superior esquerra
			GARLIC_spriteHide(n);
			break;
		case 2:
			n = 3;// centre
			GARLIC_spriteHide(n);
			n = 4; // superior esquerra
			GARLIC_spriteHide(n);
			break;
		case 3:
			n = 3;// centre
			GARLIC_spriteHide(n);
			n = 4; // superior esquerra
			GARLIC_spriteHide(n);
			break;
	}
	
	return 0;
}