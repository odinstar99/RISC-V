#include <cstdio>
#include <cstdlib>
#include <ctime>

#include "../obj_dir/Valu.h"

typedef enum {
    ADD,
    SUB,
    AND,
    OR,
    XOR,
    SLL,
    SRL,
    SRA,
    EQ,
    NE,
    LT,
    GE,
    LTU,
    GEU,
    IMM,
    PC4
} alu_operation_t;
static const char *alu_operation_name[] = {
    "ADD", "SUB", "AND", "OR", "XOR", "SLL", "SRL", "SRA",
    "EQ", "NE", "LT", "GE", "LTU", "GEU", "IMM", "PC4"
};

typedef bool (*test_func_t)(Valu*);
typedef struct {
    test_func_t function;
    alu_operation_t operation;
} test_t;

unsigned int rand_input(Valu *top) {
    top->lhs = rand();
    top->rhs = rand();
    top->eval();
    return top->result;
}

bool test_add(Valu *top) {
    top->operation = alu_operation_t::ADD;
    return (rand_input(top) == (top->lhs + top->rhs));
}

bool test_sub(Valu *top) {
    top->operation = alu_operation_t::SUB;
    return (rand_input(top) == (top->lhs - top->rhs));
}

bool test_and(Valu *top) {
    top->operation = alu_operation_t::AND;
    return (rand_input(top) == (top->lhs & top->rhs));
}

bool test_or(Valu *top) {
    top->operation = alu_operation_t::OR;
    return (rand_input(top) == (top->lhs | top->rhs));
}

bool test_xor(Valu *top) {
    top->operation = alu_operation_t::XOR;
    return (rand_input(top) == (top->lhs ^ top->rhs));
}

bool test_sll(Valu *top) {
    top->operation = alu_operation_t::SLL;
    return (rand_input(top) == (top->lhs << (top->rhs & 0x1f)));
}

bool test_srl(Valu *top) {
    top->operation = alu_operation_t::SRL;
    return (rand_input(top) == (top->lhs >> (top->rhs & 0x1f)));
}

bool test_sra(Valu *top) {
    top->operation = alu_operation_t::SRA;
    return (rand_input(top) == (((signed int) top->lhs) >> (top->rhs & 0x1f)));
}

bool test_eq(Valu *top) {
    top->operation = alu_operation_t::EQ;
    return (rand_input(top) == ((top->lhs == top->rhs) ? 1 : 0));
}

bool test_ne(Valu *top) {
    top->operation = alu_operation_t::NE;
    return (rand_input(top) == ((top->lhs != top->rhs) ? 1 : 0));
}

bool test_lt(Valu *top) {
    top->operation = alu_operation_t::LT;
    return (rand_input(top) == (((signed int) top->lhs < (signed int) top->rhs) ? 1 : 0));
}

bool test_ge(Valu *top) {
    top->operation = alu_operation_t::GE;
    return (rand_input(top) == (((signed int) top->lhs >= (signed int) top->rhs) ? 1 : 0));
}

bool test_ltu(Valu *top) {
    top->operation = alu_operation_t::LTU;
    return (rand_input(top) == ((top->lhs < top->rhs) ? 1 : 0));
}

bool test_geu(Valu *top) {
    top->operation = alu_operation_t::GEU;
    return (rand_input(top) == ((top->lhs >= top->rhs) ? 1 : 0));
}

bool test_imm(Valu *top) {
    top->operation = alu_operation_t::IMM;
    return (rand_input(top) == top->rhs);
}

bool test_pc4(Valu *top) {
    top->operation = alu_operation_t::PC4;
    return (rand_input(top) == (top->lhs + 4));
}

int main(int argc, char const *argv[]) {
    srand(time(NULL));
    Valu *top = new Valu;

    test_t tests[] = {
        test_add, alu_operation_t::ADD,
        test_sub, alu_operation_t::SUB,
        test_and, alu_operation_t::AND,
        test_or, alu_operation_t::OR,
        test_xor, alu_operation_t::XOR,
        test_sll, alu_operation_t::SLL,
        test_srl, alu_operation_t::SRL,
        test_sra, alu_operation_t::SRA,
        test_eq, alu_operation_t::EQ,
        test_ne, alu_operation_t::NE,
        test_lt, alu_operation_t::LT,
        test_ge, alu_operation_t::GE,
        test_ltu, alu_operation_t::LTU,
        test_geu, alu_operation_t::GEU,
        test_imm, alu_operation_t::IMM,
        test_pc4, alu_operation_t::PC4,
    };

    int test_count = sizeof(tests) / sizeof(test_t);
    int failed_tests = 0;
    for (int i = 0; i < test_count; i++) {
        test_func_t test_func = tests[i].function;
        const char *op_str = alu_operation_name[tests[i].operation];

        if (!test_func(top)) {
            printf("\x1b[1;31mFailed\x1b[0m: %s\n", op_str);
            printf("  LHS: 0x%.8x, RHS: 0x%.8x\n", top->lhs, top->rhs);
            printf("  Result: 0x%.8x\n", top->result);
            failed_tests++;
        }
    }
    if (failed_tests == 0) {
        printf("\x1b[1;32mSuccess\x1b[0m: Correctly ran %d/%d tests\n", test_count - failed_tests, test_count);
    } else {
        printf("\x1b[1;31Failedm\x1b[0m: Correctly ran %d/%d tests\n", test_count - failed_tests, test_count);
    }

    delete top;
    return 0;
}