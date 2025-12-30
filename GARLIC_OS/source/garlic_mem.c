/*------------------------------------------------------------------------------

	"garlic_mem.c" : fase 1 / programador M

	Funciones de carga de un fichero ejecutable en formato ELF, para GARLIC 1.0

------------------------------------------------------------------------------*/
#include <nds.h>
#include <filesystem.h>
#include <dirent.h>			// para struct dirent, etc.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>	//estan definides el tipus de param. headers del .elf

#include <garlic_system.h>	// definición de funciones y variables de sistema

#define INI_MEM 0x01002000		// dirección inicial de memoria para programas

//valor p_flags:
//Código (RE) = 5
//Datos (RW) = 6
//Diferencia en el bit 1 (101 i 110)
#define PF_W 2 


#define EI_NIDENT 16
#define PT_LOAD 1	//tipus de segment -> CARREGABLE a memòria
						//(ELF) = 1 (entero).

unsigned int ini_prog = INI_MEM;	// dirección inicial para nuevo programa (afegit en fase 2)

unsigned int dMem_lliure = INI_MEM;	//pos. mem. lliure dinàmicament ( suposem total segments < 24KB)
										//inicialment valor carrega primer seg.

//Array per guardar punters reservats per cada proces
void *blocs_reservats[16][4] = { {NULL} };
//Comptador de blocs reservats per a cada proces
int num_blocs_reservats[16] = {0};

//tipus de variables en .elf 
typedef uint32_t Elf32_Addr;   // 4 bytes (direcció de mem.)
typedef uint16_t Elf32_Half;   // 2 bytes (half int unsigned)
typedef uint32_t Elf32_Off;    // 4 bytes (desp. dins del fit.)
typedef uint32_t Elf32_Word;   // 4 bytes (unsigned int)

//.elf header
typedef struct{ 
	unsigned char e_ident[EI_NIDENT];
	Elf32_Half e_type;
	Elf32_Half e_machine;
	Elf32_Word e_version;
	Elf32_Addr e_entry;
	Elf32_Off e_phoff;
	Elf32_Off e_shoff;
	Elf32_Word e_flags;
	Elf32_Half e_ehsize;
	Elf32_Half e_phentsize;
	Elf32_Half e_phnum;
	Elf32_Half e_shentsize;
	Elf32_Half e_shnum;
	Elf32_Half e_shstrndx;
} Elf32_Ehdr;


//program header (T. segments)
typedef struct {
Elf32_Word p_type;
Elf32_Off p_offset;
Elf32_Addr p_vaddr;
Elf32_Addr p_paddr;
Elf32_Word p_filesz;
Elf32_Word p_memsz;
Elf32_Word p_flags;
Elf32_Word p_align;
} Elf32_Phdr;

/* _gm_initFS: inicializa el sistema de ficheros, devolviendo un valor booleano
					para indiciar si dicha inicialización ha tenido éxito; */
int _gm_initFS()
{
	return nitroFSInit(NULL); 	//ini. sis. fit. NITRO
}

/* _gm_listaProgs: devuelve una lista con los nombres en clave de todos
			los programas que se encuentran en el directorio "Programas".
			 Se considera que un fichero es un programa si su nombre tiene
			8 caracteres y termina con ".elf"; se devuelven s?lo los
			4 primeros caracteres de los programas (nombre en clave).
			 El resultado es un vector de strings (paso por referencia) y
			el n?mero de programas detectados */
int _gm_listaProgs(char* progs[])
{

}

/* _gm_cargarPrograma: busca un fichero de nombre "(keyName).elf" dentro del
					directorio "/Programas/" del sistema de ficheros y carga
					los segmentos de programa a partir de una posici?n de
					memoria libre, efectuando la reubicaci?n de las referencias
					a los s?mbolos del programa seg?n el desplazamiento del
					c?digo y los datos en la memoria destino;
	Par?metros:
		zocalo	->	?ndice del z?calo que indexar? el proceso del programa
		keyName ->	string de 4 car?cteres con el nombre en clave del programa
	Resultado:
		!= 0	->	direcci?n de inicio del programa (intFunc)
		== 0	->	no se ha podido cargar el programa
*/
intFunc _gm_cargarPrograma(int zocalo, char *keyName)
{
	//cargar la ruta del .elf del programa
	char ruta[32];
	sprintf(ruta, "/Programas/%s.elf", keyName);
	
	FILE *fit = fopen(ruta, "rb");
	if (fit == NULL){
		printf("ERROR: intent obrir fitxer %s \n", ruta);
		return (intFunc)0;
	} 
	
	fseek(fit, 0, SEEK_END);
	long fsize = ftell(fit); //fsize = mida .elf del programa
	fseek(fit, 0, SEEK_SET);
	
	char *fitBuffer = (char *)malloc(fsize);  
	if (fitBuffer == NULL){
		printf("ERROR: reserva espai buffer fitxer \n");
		fclose(fit);
		return (intFunc)0;
	}
	
	size_t freadsize = fread(fitBuffer, 1, fsize, fit);
	if (freadsize != fsize){
		printf("ERROR: copia contingut fitxer to buffer \n");
		fclose(fit);
		free(fitBuffer);
		return (intFunc)0;
	}
	fclose(fit);
	
	Elf32_Ehdr *elfHeader = (Elf32_Ehdr *)fitBuffer;
	Elf32_Phdr *progHeader = (Elf32_Phdr *)(fitBuffer + elfHeader->e_phoff);
	
	unsigned int pAddr_code = 0, pAddr_data = 0;
    unsigned int *dest_code = NULL, *dest_data = NULL;
	
	for(int i = 0; i < elfHeader->e_phnum; i++) {
        if (progHeader[i].p_type != PT_LOAD) continue;
        
        unsigned char tipo = (progHeader[i].p_flags & PF_W) ? 1 : 0; // 0: Code (RE), 1: Data (RW)
        unsigned int *memDest = _gm_reservarMem(zocalo, progHeader[i].p_memsz, tipo); 
        
		//0, NULL y false es tracten igual en punters
        if (memDest == NULL) {
            _gm_liberarMem(zocalo);
            free(fitBuffer);
            return (intFunc)0;
        }

        if (tipo == 0) {
            pAddr_code = progHeader[i].p_paddr;
            dest_code = memDest;
        } else {
            pAddr_data = progHeader[i].p_paddr;
            dest_data = memDest;
        }

        //si (p_memsz > p_filesz), existeix part segment en memoria que no 
			//esta en el arxiu (cas zones .bss), posar-la a valor 0.
        _gs_copiaMem(fitBuffer + progHeader[i].p_offset, memDest, progHeader[i].p_filesz);
        if (progHeader[i].p_memsz > progHeader[i].p_filesz) {
            memset((char *)memDest + progHeader[i].p_filesz, 0, progHeader[i].p_memsz - progHeader[i].p_filesz);
        }
    }
	
	//calcul entrypoint relatiu al segment de codi
	unsigned int offset_code = (unsigned int)dest_code - pAddr_code;
    unsigned int *entryPoint = (unsigned int *)(elfHeader->e_entry + offset_code);
	
	_gm_reubicar(fitBuffer, pAddr_code, dest_code, pAddr_data, dest_data);
	
	free(fitBuffer);
	return (intFunc)entryPoint;
}


void *_gm_do_malloc(unsigned int size, int zocalo) {
    if (zocalo < 0 || zocalo > 15 || num_blocs_reservats[zocalo] >= 4) {
        return NULL; //límit superat o zócalo invàlid
    }

    void *ptr = malloc(size);
    if (ptr == NULL) {
        return NULL;
    }

    //marcar punter guardat
    for (int i = 0; i < 4; i++) {
        if (blocs_reservats[zocalo][i] == NULL) {
            blocs_reservats[zocalo][i] = ptr;
            num_blocs_reservats[zocalo]++;
            return ptr; // Retornem el punter reservat
        }
    }
	//per si de cas
    free(ptr);
    return NULL;
}

int _gm_do_free(void *ptr, int zocalo) {
    if (zocalo < 0 || zocalo > 15 || ptr == NULL) {
        return 0;
    }

    //buscar punter per "eliminar-lo"
    for (int i = 0; i < 4; i++) {
        if (blocs_reservats[zocalo][i] == ptr) {
            free(ptr);
            blocs_reservats[zocalo][i] = NULL;
            num_blocs_reservats[zocalo]--;
            return 1; // retorn positiu
        }
    }

    return 0; // retorn error: el punter no pertanyia a aquest procés
}
