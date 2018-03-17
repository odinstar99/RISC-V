#include <cstdio>

#include "verilated.h"
#include "verilated_vcd_c.h"
#include "../obj_dir/Vcore.h"

unsigned int rom[0x4000] = {0};
unsigned int ram[0x4000] = {0};

int main(int argc, char const *argv[]) {
    assert(argc == 2 || (argc == 3 && !strcmp(argv[2], "--trace")));
    bool trace = (argc == 3);

    Verilated::traceEverOn(true);

    FILE * rom_file = fopen(argv[1], "rb");
    assert(rom_file != NULL);
    fread(rom, sizeof(unsigned int), 0x4000, rom_file);
    fclose(rom_file);

    Vcore *core = new Vcore;

    VerilatedVcdC* tfp;
    if (trace) {
        tfp = new VerilatedVcdC;
        core->trace(tfp, 99);
        tfp->open("trace.vcd");
    }

    unsigned int imem_address = 0;
    unsigned int dmem_address = 0;
    unsigned int dmem_write_data = 0;
    unsigned int dmem_write_mode = 0;
    unsigned int dmem_write_enable = 0;
    unsigned int dmem_read_mode = 0;
    unsigned int dmem_read_enable = 0;

    unsigned int mmio_config = 0;
    unsigned int mmio_leds = 0;
    unsigned int mmio_hex = 0;
    unsigned int mmio_hex_upper = 0;
    unsigned int mmio_switch = 0;
    unsigned int mmio_bg_color = 0;
    unsigned int mmio_uart_data = 0;

    core->reset_n = 0;
    core->clk = 1;
    core->eval();
    core->reset_n = 1;
    core->clk = 0;
    core->eval();

    for (int i = 0; i < 1000000; i++) {
        // Load the ROM data
        assert(imem_address >= 0x00000000 && imem_address <= 0x0000ffff);
        core->imem_data = rom[(imem_address & 0xffff) >> 2];
        // Load the RAM data
        if (dmem_read_enable) {
            if (dmem_address >= 0x80000000 && dmem_address <= 0x8000ffff) {
                if ((dmem_read_mode & 0b11) == 0) {
                    core->dmem_read_data = ((unsigned char *) ram)[dmem_address & 0xffff];
                } else if ((dmem_read_mode & 0b11) == 1) {
                    core->dmem_read_data = ((unsigned short *) ram)[(dmem_address & 0xffff) >> 1];
                } else if ((dmem_read_mode & 0b11) == 2) {
                    core->dmem_read_data = ram[(dmem_address & 0xffff) >> 2];
                }
                // printf("RAM read @ %.8x : %.8x (%d)\n", dmem_address, core->dmem_read_data, dmem_read_mode);
            } else if (dmem_address <= 0x0000ffff) {
                if ((dmem_read_mode & 0b11) == 0) {
                    core->dmem_read_data = ((unsigned char *) rom)[dmem_address & 0xffff];
                } else if ((dmem_read_mode & 0b11) == 1) {
                    core->dmem_read_data = ((unsigned short *) rom)[(dmem_address & 0xffff) >> 1];
                } else if ((dmem_read_mode & 0b11) == 2) {
                    core->dmem_read_data = rom[(dmem_address & 0xffff) >> 2];
                }
                // printf("ROM read @ %.8x : %.8x (%d)\n", dmem_address, core->dmem_read_data, dmem_read_mode);
            } else if (dmem_address >= 0x70000000 && dmem_address <= 0x70000044) {
                switch (dmem_address) {
                    case 0x70000000: // config
                        core->dmem_read_data = mmio_config & 0x01;
                        break;
                    case 0x70000004: // leds
                        core->dmem_read_data = mmio_leds & 0x3ff;
                        break;
                    case 0x70000008: // hex 0-3
                        core->dmem_read_data = mmio_hex;
                        break;
                    case 0x7000000c: // hex 4-5
                        core->dmem_read_data = mmio_hex_upper & 0xffff;
                        break;
                    case 0x70000010: // switch state
                        core->dmem_read_data = mmio_switch & 0x3ff;
                        break;
                    case 0x70000014: // bg color
                        core->dmem_read_data = mmio_bg_color & 0xfff;
                        break;
                    case 0x70000040: // uart status
                        core->dmem_read_data = 0; // uart not busy
                        break;
                    case 0x70000044: // uart data
                        core->dmem_read_data = mmio_uart_data & 0xff;
                        break;
                }
            } else {
                assert(false);
            }
        }
        // Write to RAM
        if (dmem_write_enable) {
            // printf("RAM write @ %.8x : %.8x (%d)\n", dmem_address, dmem_write_data, dmem_write_mode);
            if (dmem_address >= 0x80000000 && dmem_address <= 0x8000ffff) {
                if ((dmem_write_mode & 0b11) == 0) {
                    ((unsigned char *) ram)[dmem_address & 0xffff] = (dmem_write_data & 0xff);
                } else if ((dmem_write_mode & 0b11) == 1) {
                    ((unsigned short *) ram)[(dmem_address & 0xffff) >> 1] = (dmem_write_data & 0xffff);
                } else if ((dmem_write_mode & 0b11) == 2) {
                    ram[(dmem_address & 0xffff) >> 2] = dmem_write_data;
                }
            } else if (dmem_address >= 0x70000000 && dmem_address <= 0x70000044) {
                switch (dmem_address) {
                    case 0x70000000: // config
                        mmio_config = dmem_write_data & 0x01;
                        break;
                    case 0x70000004: // leds
                        mmio_leds = dmem_write_data & 0x3ff;
                        break;
                    case 0x70000008: // hex 0-3
                        mmio_leds = dmem_write_data;
                        break;
                    case 0x7000000c: // hex 4-5
                        mmio_hex_upper = dmem_write_data & 0xffff;
                        break;
                    case 0x70000010: // switch state
                        break;
                    case 0x70000014: // bg color
                        mmio_bg_color = dmem_write_data & 0xfff;
                        break;
                    case 0x70000040: // uart status
                        break;
                    case 0x70000044: // uart data
                        mmio_uart_data = dmem_write_data & 0xff;
                        printf("%c", mmio_uart_data);
                        break;
                }
            }
        }

        // Clock in new ROM and RAM inputs
        if (core->imem_enable) {
            imem_address = core->imem_address;
        }
        if (core->dmem_enable) {
            dmem_address = core->dmem_address;
            dmem_write_data = core->dmem_write_data;
            dmem_write_mode = core->dmem_write_mode;
            dmem_write_enable = core->dmem_write_enable;
            dmem_read_mode = core->dmem_read_mode;
            dmem_read_enable = core->dmem_read_enable;
        }

        // Toggle the clock
        core->clk = 1;
        core->eval();
        if (trace) tfp->dump(i*100);

        core->clk = 0;
        core->eval();
        if (trace) tfp->dump(i*100+50);

        if (core->illegal_op) {
            printf("ILLEGAL OP! %d\n", i);
            break;
        }
    }

    if (trace) {
        tfp->close();
        delete tfp;
    }
    delete core;
    return 0;
}
