/*------------------------------------------------------------------------------

	"garlic_mem.c" : fase 1 / programador M

	Funciones de carga de un fichero ejecutable en formato ELF, para GARLIC 1.0

------------------------------------------------------------------------------*/
#include <nds.h>
#include <filesystem.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>	//estan definides el tipus de param. headers del .elf

#include <garlic_system.h>	// definición de funciones y variables de sistema

#define INI_MEM 0x01002000		// dirección inicial de memoria para programas

#define EI_NIDENT 16
#define PT_LOAD 1	//tipus de segment -> CARREGABLE a memòria
						//(ELF) = 1 (entero).

unsigned int dMem_lliure = INI_MEM;	//pos. mem. lliure dinàmicament ( suposem total segments < 24KB)
										//inicialment valor carrega primer seg.

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



/* _gm_cargarPrograma: busca un fichero de nombre "(keyName).elf" dentro del
					directorio "/Programas/" del sistema de ficheros, y
					carga los segmentos de programa a partir de una posición de
					memoria libre, efectuando la reubicación de las referencias
					a los símbolos del programa, según el desplazamiento del
					código en la memoria destino;
	Parámetros:
		keyName ->	vector de 4 caracteres con el nombre en clave del programa
	Resultado:
		!= 0	->	dirección de inicio del programa (intFunc)
		== 0	->	no se ha podido cargar el programa
*/
intFunc _gm_cargarPrograma(char *keyName)
{
	//cargar la ruta del .elf del programa
	char ruta[32];
	sprintf(ruta, "/Programas/%s.elf", keyName);
	
	FILE *fit = fopen(ruta, "rb");
	if (fit == NULL){
		printf("ERROR: intent obrir fitxer %s \n", ruta);
		return (intFunc)0;
	} 	
	//printf("S'ha obert el fitxer \n");

	fseek(fit, 0, SEEK_END);
	long fsize = ftell(fit); //fsize = mida .elf del programa
	fseek(fit, 0, SEEK_SET);
	
	//TODO: crear el propi malloc
	//carga fitxer a memoria 
	char *fitBuffer = (char *)malloc(fsize);  
	if (fitBuffer == NULL){
		printf("ERROR: reserva espai buffer fitxer \n");
		fclose(fit);
		return (intFunc)0;
	}
	//printf("S'ha reservat mem. pel fitxer \n");
	
	size_t freadsize = fread(fitBuffer, 1, fsize, fit);
	if (freadsize != fsize){
		printf("ERROR: copia contingut fitxer to buffer \n");
		fclose(fit);
		//TODO: crear propi free
		free(fitBuffer);
		return (intFunc)0;
	}
	fclose(fit);
	//printf("S'ha copiat el contingut del fitxer a memoria amb mida %u bytes\n", freadsize);
	
	Elf32_Ehdr *elfHeader = (Elf32_Ehdr *)fitBuffer;
	Elf32_Phdr *progHeader = (Elf32_Phdr *)(fitBuffer + elfHeader->e_phoff);
	
	unsigned int offset = dMem_lliure - progHeader[0].p_paddr;
	unsigned int *entryPoint = (unsigned int *)(elfHeader->e_entry + offset);
	
	for(int i = 0; i < elfHeader->e_phnum; i++){
		if (progHeader[i].p_type != PT_LOAD) continue;
		
		//direccio inicial programa
		unsigned int *memDest = (unsigned int *)(offset + progHeader[i].p_paddr);
		//printf("El seg. %d es carrega a %p \n", i, memDest);
		//printf("El start() estara a %p \n", entryPoint);
		
		_gs_copiaMem(fitBuffer + progHeader[i].p_offset, memDest, progHeader[i].p_filesz);
		
		//si (p_memsz > p_filesz), existeix part segment en memoria que no 
			//esta en el arxiu (cas zones .bss), posar-la a valor 0.
		if (progHeader[i].p_memsz > progHeader[i].p_filesz){
			void *bss_start = (char *)memDest + progHeader[i].p_filesz;
            unsigned int bss_size = progHeader[i].p_memsz - progHeader[i].p_filesz;
            memset(bss_start, 0, bss_size);
		}
		//reubicacions de memoria
		_gm_reubicar(fitBuffer, (unsigned int)memDest, memDest);
		dMem_lliure += progHeader[i].p_memsz;	
	}
	free(fitBuffer);
	
	return (intFunc)entryPoint;
	//return ((intFunc) INI_MEM);
}

