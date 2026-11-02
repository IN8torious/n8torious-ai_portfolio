/* BUBO Kernel linker script — QEMU virt, load at 0x40080000 */

ENTRY(_start)

SECTIONS
{
    . = 0x40080000;

    .text.boot : {
        KEEP(*(.text.boot))
    }

    .text : {
        *(.text*)
    }

    .rodata : {
        *(.rodata*)
    }

    .data : {
        *(.data*)
    }

    . = ALIGN(16);
    _bss_start = .;
    .bss : {
        *(.bss*)
        *(COMMON)
    }
    _bss_end = .;

    /* 16KB stack */
    . = ALIGN(16);
    _stack_bottom = .;
    . += 0x4000;
    _stack_top = .;
}
