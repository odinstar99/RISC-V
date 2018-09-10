unsigned int fib(unsigned int n) {
    if(n == 0)
        return 0;
    if(n == 1)
        return 1;

    return fib(n - 1) + fib(n - 2);
}

unsigned int fib_it(unsigned int n) {
    if(n == 0)
        return 0;
    if(n == 1)
        return 1;

    unsigned int f1 = 0;
    unsigned int f2 = 1;
    unsigned int fi;
    for(int i = 2; i <= n; i++) {
        fi = f1 + f2;
        f1 = f2;
        f2 = fi;
    }
    return fi;
}

static unsigned int global_array[16];
static int global_data = 1234;
static char *some_string = "Hello world!";

#define CONFIG ((volatile unsigned int *) 0x70000000)
#define LEDS ((volatile unsigned int *) 0x70000004)
#define HEX ((volatile unsigned int *) 0x70000008)
#define SWITCH ((volatile unsigned int *) 0x70000010)

void main() {
    *CONFIG |= 3; // Enable leds and hex

    unsigned int n = 5;
    unsigned int recursive_result = fib(n);
    unsigned int iterative_result = fib_it(n);

    if (recursive_result != iterative_result) {
        *LEDS = 0x3ff;
        while (1);
    }

    for (int i = 0; i < 16; i++) {
        global_array[i] = fib_it(i);
    }
    if (global_data != 1234) {
        *LEDS = 0x3fe;
        while (1);
    }
    global_data = 4321;

    *HEX = 0xdefec7;
    for (int i = 0; i < 12; i++) {
        *LEDS = some_string[i];
        for (int j = 0; j < 10000000; j++) asm volatile ("nop");
    }

    *LEDS = 0;
    *HEX = 0;
    while (1) {
        *LEDS = *SWITCH;
        *HEX += *SWITCH;
        for (int j = 0; j < 1000000; j++) asm volatile ("nop");
    }
}