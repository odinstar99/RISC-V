#include <cstdio>

#include "verilated.h"
#include "verilated_vcd_c.h"
#include "../obj_dir/Vcore.h"

unsigned int rom[0x4000] = {0};
unsigned int ram[0x4000] = {0};

int main(int argc, char const *argv[]) {
    assert(argc == 2);

    Verilated::traceEverOn(true);

    FILE * rom_file = fopen(argv[1], "rb");
    assert(rom_file != NULL);
    fread(rom, sizeof(unsigned int), 0x4000, rom_file);
    fclose(rom_file);

    Vcore *core = new Vcore;

    VerilatedVcdC* tfp = new VerilatedVcdC;
    core->trace(tfp, 99);
    tfp->open("trace.vcd");

    unsigned int rom_address = 0;
    unsigned int ram_address = 0;
    unsigned int ram_write_data = 0;
    unsigned int ram_write_mode = 0;
    unsigned int ram_write_enable = 0;
    unsigned int ram_read_mode = 0;
    unsigned int ram_read_enable = 0;

    core->reset_n = 0;
    core->clk = 1;
    core->eval();
    core->reset_n = 1;
    core->clk = 0;
    core->eval();

    for (int i = 0; i < 1000000; i++) {
        // Load the ROM data
        assert(rom_address >= 0x00000000 && rom_address <= 0x0000ffff);
        core->rom_data = rom[(rom_address & 0xffff) >> 2];
        // Load the RAM data
        if (ram_read_enable) {
            if (ram_address >= 0x80000000 && ram_address <= 0x8000ffff) {
                if ((ram_read_mode & 0b11) == 0) {
                    core->ram_read_data = ((unsigned char *) ram)[ram_address & 0xffff];
                } else if ((ram_read_mode & 0b11) == 1) {
                    core->ram_read_data = ((unsigned short *) ram)[(ram_address & 0xffff) >> 1];
                } else if ((ram_read_mode & 0b11) == 2) {
                    core->ram_read_data = ram[(ram_address & 0xffff) >> 2];
                }
                // printf("RAM read @ %.8x : %.8x (%d)\n", ram_address, core->ram_read_data, ram_read_mode);
            } else if (ram_address <= 0x0000ffff) {
                if ((ram_read_mode & 0b11) == 0) {
                    core->ram_read_data = ((unsigned char *) rom)[ram_address & 0xffff];
                } else if ((ram_read_mode & 0b11) == 1) {
                    core->ram_read_data = ((unsigned short *) rom)[(ram_address & 0xffff) >> 1];
                } else if ((ram_read_mode & 0b11) == 2) {
                    core->ram_read_data = rom[(ram_address & 0xffff) >> 2];
                }
                // printf("ROM read @ %.8x : %.8x (%d)\n", ram_address, core->ram_read_data, ram_read_mode);
            } else {
                assert(false);
            }
        }
        // Write to RAM
        if (ram_write_enable) {
            // printf("RAM write @ %.8x : %.8x (%d)\n", ram_address, ram_write_data, ram_write_mode);
            assert(ram_address >= 0x80000000 && ram_address <= 0x8000ffff);

            if ((ram_write_mode & 0b11) == 0) {
                ((unsigned char *) ram)[ram_address & 0xffff] = (ram_write_data & 0xff);
            } else if ((ram_write_mode & 0b11) == 1) {
                ((unsigned short *) ram)[(ram_address & 0xffff) >> 1] = (ram_write_data & 0xffff);
            } else if ((ram_write_mode & 0b11) == 2) {
                ram[(ram_address & 0xffff) >> 2] = ram_write_data;
            }
        }

        // Clock in new ROM and RAM inputs
        if (core->rom_enable) {
            rom_address = core->rom_address;
        }
        if (core->ram_enable) {
            ram_address = core->ram_address;
            ram_write_data = core->ram_write_data;
            ram_write_mode = core->ram_write_mode;
            ram_write_enable = core->ram_write_enable;
            ram_read_mode = core->ram_read_mode;
            ram_read_enable = core->ram_read_enable;
        }

        // Toggle the clock
        core->clk = 1;
        core->eval();
        tfp->dump(i*100);

        core->clk = 0;
        core->eval();
        tfp->dump(i*100+50);

        if (core->illegal_op) {
            printf("ILLEGAL OP! %d\n", i);
            break;
        }
    }

    unsigned char *buf_o = ((unsigned char *) ram + 0x400);
    for (int y = 0; y < 32; y++) {
        for (int x = 0; x < 32; x++) {
            printf("%.2x", buf_o[x + y * 32]);
        }
        printf("\n");
    }

    tfp->close();
    delete tfp;
    delete core;
    return 0;
}