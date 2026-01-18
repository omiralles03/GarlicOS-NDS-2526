#include <GARLIC_API.h>			/* definiciï¿½n de las funciones API de GARLIC */

//------------------------------------------------------------------------------
int _start(int arg)
//------------------------------------------------------------------------------
{ 
 	short maxX = 256 - 32;
	short maxY = 192 - 32;
	short minX = 0;
	short minY = 0;
	short dirX = (2+arg)*8;
	short dirY = (2+arg)*4;
	
	unsigned char n, icon;
	short px, py;
	
	n = (GARLIC_pid()*arg)%16; icon = (3*arg+7)%32; px = minX; py = minY;
	GARLIC_spriteSet(n, icon);
	GARLIC_spriteMove(n, px, py);
	GARLIC_spriteShow(n);
	
 	for (int i = 0; i < 500; i++) {
		GARLIC_delay(0);
		// VENTANA
		px += dirX;
		py += dirY;
		
		if (px >= maxX) {
			px = maxX;
			dirX = -dirX;
		} else if (px <= minX) {
			px = minX;
			dirX = -dirX;
		}
		
		if (py >= maxY) {
			py = maxY;
			dirY = -dirY;
		} else if (py <= minY) {
			py = minY;
			dirY = -dirY;
		}		
		GARLIC_spriteMove(n, px, py);
	}
	GARLIC_spriteHide(n);
	return 0;
}
