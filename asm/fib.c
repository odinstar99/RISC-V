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

unsigned int global_array[16];
int global_data = 1234;
char *some_string = "Hello world!";

void main() {
    unsigned int n = 5;
    unsigned int recursive_result = fib(n);
    unsigned int iterative_result = fib_it(n);

    if (recursive_result != iterative_result) {
        asm volatile ("ebreak");
    }

    for (int i = 0; i < 16; i++) {
        global_array[i] = fib_it(i);
    }
    if (global_data != 1234) {
        asm volatile ("ebreak");
    }
    global_data = 4321;
}