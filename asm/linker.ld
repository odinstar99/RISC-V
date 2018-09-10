OUTPUT_ARCH("riscv")

MEMORY
{
    ROM (rx) : ORIGIN = 0x00000000, LENGTH = 64K
    RAM (rw) : ORIGIN = 0x80000000, LENGTH = 64K
}

__text_va = ORIGIN(ROM);
__data_va = ORIGIN(RAM);
__stack_va = ORIGIN(RAM) + LENGTH(RAM);

SECTIONS
{
    .text __text_va : {
        *(.entry*)
        *(.text*)
    } >ROM

    .rodata : {
        *(.rodata*)
        *(.srodata*)
    } >ROM

    __data_start = .;
    .data __data_va : AT(__data_start) {
        *(.data*)
    } >RAM

    .sdata : {
        __global_pointer$ = . + 0x800;
        *(.sdata*)
    } >RAM
    __data_end = __data_start + SIZEOF(.data) + SIZEOF(.sdata);

    __bss_start = .;
    .sbss (NOLOAD): {
        *(.sbss*)
        *(.scommon*)
    } >RAM

    .bss (NOLOAD): {
        *(.bss*)
        *(COMMON)
    } >RAM
    __bss_end = .;

    /DISCARD/ :
    {
        *(.eh_frame)
    }
}

