@;==============================================================================
@;
@;	"garlic_itcm_mem.s":	código de rutinas de soporte a la carga de
@;							programas en memoria (version 1.0)
@;
@;==============================================================================

.section .itcm,"ax",%progbits

	.arm
	.align 2


	.global _gm_reubicar
	@; rutina para interpretar los 'relocs' de un fichero ELF y ajustar las
	@; direcciones de memoria correspondientes a las referencias de tipo
	@; R_ARM_ABS32, restando la dirección de inicio de segmento y sumando
	@; la dirección de destino en la memoria;
	@;Parámetros:
	@; R0: dirección inicial del buffer de fichero (char *fileBuf)
	@; R1: dirección de inicio de segmento (unsigned int pAddr)
	@; R2: dirección de destino en la memoria (unsigned int *dest)
	@;Resultado:
	@; cambio de las direcciones de memoria que se tienen que ajustar
_gm_reubicar:
    push {r0-r10, lr}       

    mov r4, r0              @; r4 -> punter al buffer del fitxer
    sub r5, r2, r1          @; r5 = offset de reubicació (nova_base - base_original)

    @; buscar la taula de seccions del .elf
    ldr r7, [r4, #32]
    add r7, r4, r7
    ldrh r8, [r4, #48]
    ldrh r9, [r4, #46]

.Lbucle_seccions:
    cmp r8, #0
    beq .Lfi_reubicacio

    ldr r0, [r7, #4]
    cmp r0, #9              @; seccio de reubicació (SHT_REL) ==? 9
    bne .Lnext_seccio

    ldr r1, [r7, #16]
    add r1, r4, r1
    ldr r2, [r7, #20]
    add r2, r1, r2

.Lbucle_reubicadors:
    cmp r1, r2
    bge .Lnext_seccio

    ldr r3, [r1], #4
    ldr r0, [r1], #4

    and r0, r0, #0xFF
    cmp r0, #2              @; tipus R_ARM_ABS32 ?
    bne .Lbucle_reubicadors

    @; correcció de l'adreça
    add r10, r3, r5         @; adreça real a modificar = (r_offset + offset)
    ldr r0, [r10]
    add r0, r0, r5          @; nou valor = (valor_original + offset)
    str r0, [r10]

    b .Lbucle_reubicadors

.Lnext_seccio:
    add r7, r7, r9          @; seguent seccio
    sub r8, r8, #1
    b .Lbucle_seccions

.Lfi_reubicacio:
    pop {r0-r10, pc}


.end

