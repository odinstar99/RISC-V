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
            } else {
                assert(false);
            }
        }
        // Write to RAM
        if (dmem_write_enable) {
            // printf("RAM write @ %.8x : %.8x (%d)\n", dmem_address, dmem_write_data, dmem_write_mode);
            if (dmem_address == 0x70000000) {
                printf("LED UPDATE: %d\n", dmem_write_data);
            } else {
                assert(dmem_address >= 0x80000000 && dmem_address <= 0x8000ffff);

                if ((dmem_write_mode & 0b11) == 0) {
                    ((unsigned char *) ram)[dmem_address & 0xffff] = (dmem_write_data & 0xff);
                } else if ((dmem_write_mode & 0b11) == 1) {
                    ((unsigned short *) ram)[(dmem_address & 0xffff) >> 1] = (dmem_write_data & 0xffff);
                } else if ((dmem_write_mode & 0b11) == 2) {
                    ram[(dmem_address & 0xffff) >> 2] = dmem_write_data;
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

    unsigned char *buf_o = ((unsigned char *) ram + 0x410);
    for (int y = 0; y < 32; y++) {
        for (int x = 0; x < 32; x++) {
            printf("%.2x", buf_o[x + y * 32]);
        }
        printf("\n");
    }

    if (trace) {
        tfp->close();
        delete tfp;
    }
    delete core;
    return 0;
}
