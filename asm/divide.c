#define CONFIG ((volatile unsigned int *) 0x70000000)
#define LEDS ((volatile unsigned int *) 0x70000004)
#define UART_STATUS ((volatile unsigned int *) 0x70000040)
#define UART_TX ((volatile unsigned int *) 0x70000044)

extern unsigned long long riscv_cycles();
extern unsigned long long riscv_instret();

void uart_putc(char c) {
    while (*UART_STATUS & 1);
    *UART_TX = c;
    *LEDS += 1;
}

char lookup[16] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};
void uart_puthex(char c) {
    uart_putc(lookup[(c >> 4) & 0xf]);
    uart_putc(lookup[c & 0xf]);
}

void uart_puthex_64(unsigned long long x) {
    uart_puthex((x & 0xff00000000000000) >> 56);
    uart_puthex((x & 0x00ff000000000000) >> 48);
    uart_puthex((x & 0x0000ff0000000000) >> 40);
    uart_puthex((x & 0x000000ff00000000) >> 32);
    uart_puthex((x & 0x00000000ff000000) >> 24);
    uart_puthex((x & 0x0000000000ff0000) >> 16);
    uart_puthex((x & 0x000000000000ff00) >>  8);
    uart_puthex((x & 0x00000000000000ff) >>  0);
}

void main() {
    unsigned long long cycles_before = riscv_cycles();
    unsigned long long instret_before = riscv_instret();

    volatile int x = 343242;
    volatile int y = (x / 13) + (x % 13);

    unsigned long long cycles = riscv_cycles();
    unsigned long long instret = riscv_instret();
    uart_puthex_64(cycles);
    uart_putc('\r');
    uart_putc('\n');
    uart_puthex_64(cycles - cycles_before);
    uart_putc('\r');
    uart_putc('\n');
    uart_puthex_64(instret);
    uart_putc('\r');
    uart_putc('\n');
    uart_puthex_64(instret - instret_before);
    uart_putc('\r');
    uart_putc('\n');
    uart_puthex_64(y);
    uart_putc('\r');
    uart_putc('\n');
}
