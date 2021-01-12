`ifndef TYPES_SV
`define TYPES_SV
package TYPES;
typedef enum bit [3:0] {
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

typedef enum bit [0:0] {
    REG1,
    PC
} alu_select1_t;

typedef enum bit [0:0] {
    REG2,
    IMMEDIATE
} alu_select2_t;

typedef enum bit [1:0] {
    NEVER,
    CONDITIONAL,
    ALWAYS
} branch_mode_t;

typedef enum bit [0:0] {
    PC_REL,
    REG_REL
} branch_target_t;

typedef enum bit [2:0] {
    ALU,
    MEM,
    CSR,
    MUL,
    MULH,
    DIV,
    REM
} writeback_t;

typedef enum bit [1:0] {
    DECODE,
    EXECUTE,
    MEMORY,
    WRITEBACK
} forward_t;

typedef struct packed {
    logic write_reg;
    writeback_t wb_select;
    logic [4:0] rd;
    alu_operation_t alu_op;
    alu_select1_t alu_select1;
    alu_select2_t alu_select2;
    branch_mode_t branch_mode;
    branch_target_t branch_target;
    logic mem_write_enable;
    logic [2:0] mem_write;
    logic [2:0] mem_read;
    logic instruction_valid;
    logic branch_taken;
    logic mul_signa;
    logic mul_signb;
    logic div_sign;
} control_t;

endpackage : TYPES
`endif
