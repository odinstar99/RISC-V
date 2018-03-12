#define CONFIG ((volatile unsigned int *) 0x70000000)
#define LEDS ((volatile unsigned int *) 0x70000004)
#define HEX ((volatile unsigned int *) 0x70000008)
#define SWITCH ((volatile unsigned int *) 0x70000010)
#define BGCOLOR ((volatile unsigned int *) 0x70000014)

void main() {
    *BGCOLOR = 0;
    while (1) {
        *BGCOLOR += 1;
        for (int i = 0; i < 10000000; i++) asm volatile ("nop");
    }
}