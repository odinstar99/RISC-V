#include <cstdio>
#include <cstdlib>
#include <ctime>

#include "verilated.h"
#include "verilated_vcd_c.h"
#include "../obj_dir/Vdivider.h"

int main(int argc, char const *argv[]) {
    srand(time(NULL));
    Verilated::traceEverOn(true);

    Vdivider *top = new Vdivider;
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("trace_div.vcd");

    int divisor = (rand() % 2 ? -(rand() % 65536) : (rand() % 65536));
    int divident = (rand() % 2 ? -rand() : rand());

    unsigned int start = 1;

    top->divisor_input = divisor;
    top->divident_input = divident;
    top->sign = 1;
    top->reset_n = 0;
    top->clk = 1;
    top->eval();
    top->reset_n = 1;
    top->clk = 0;
    top->eval();

    int i = 0;
    while (top->busy || start) {
        top->start = start;
        top->eval();
        top->clk = 1;
        top->eval();
        tfp->dump(i++*50);
        top->clk = 0;
        top->eval();
        tfp->dump(i++*50);
        start = 0;
    }

    int quotient = top->quotient_output;
    int remainder = top->remainder_output;
    printf("Divident: %d\n", divident);
    printf("Divisor: %d\n", divisor);
    printf("Quotient: %d\n", quotient);
    if (quotient == (divident / divisor)) {
        printf("\x1b[1;32mCorrect quotient\x1b[0m\n");
    }
    printf("Remainder: %d\n", remainder);
    if (remainder == (divident % divisor)) {
        printf("\x1b[1;32mCorrect remainder\x1b[0m\n");
    }

    tfp->close();
    delete tfp;
    delete top;
    return 0;
}