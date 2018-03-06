`include "types.sv"

module core (
    input clk,
    input reset_n,
    output illegal_op,

    output [31:0] imem_address,
    output imem_enable,
    input [31:0] imem_data,
    input imem_wait,

    output [31:0] dmem_address,
    output dmem_enable,
    output [31:0] dmem_write_data,
    input [31:0] dmem_read_data,
    output dmem_write_enable,
    output [2:0] dmem_write_mode,
    output dmem_read_enable,
    output [2:0] dmem_read_mode,
    input dmem_wait
);

logic pipe_enable;

// -----
// Instruction fetch stage
// -----
logic [31:0] if_pc;
logic [31:0] if_new_pc;
logic if_pc_write_enable;

always_ff @(posedge clk) begin
    if (!reset_n) begin
        if_pc <= 0;
    end else if (if_pc_write_enable && pipe_enable) begin
        if_pc <= if_new_pc;
    end
end

always_comb begin
    // Select the new PC based on if we are branching
    if (ex_should_branch) begin
        if_new_pc = ex_branch;
    end else begin
        if_new_pc = if_pc + 4;
    end

    // The requested ROM address is the new PC, the ROM has a buffered input
    imem_address = if_new_pc;
    imem_enable = if_pc_write_enable && pipe_enable;
end

// -----
// Instruction fetch / Instruction decode boundary
// -----
logic ifid_instruction_write_enable;

always_ff @(posedge clk) begin
    if (!reset_n) begin
        id_instruction <= 0;
        id_pc <= 0;
    end else if (ifid_instruction_write_enable && pipe_enable) begin
        id_instruction <= imem_data;
        id_pc <= if_pc;
    end
end

// -----
// Instruction decode stage
// -----
logic [31:0] id_pc;

logic [31:0] id_instruction;
logic [4:0] id_rs1;
logic [31:0] id_rs1_val;
logic [4:0] id_rs2;
logic [31:0] id_rs2_val;
logic [31:0] id_immediate;

forward_t id_rs1_forward;
forward_t id_rs2_forward;
logic [31:0] id_rs1_forward_val;
logic [31:0] id_rs2_forward_val;

control_t id_control_prelim;
control_t id_control;
// WB Control is defined up here because it is used for writeback
control_t wb_control;
logic id_hazard;

decode id_decode (
    .instruction(id_instruction),
    .rs1(id_rs1),
    .rs2(id_rs2),
    .immediate(id_immediate),
    .illegal_op(illegal_op),
    .control(id_control_prelim)
);

hazard id_hazard_unit (
    .id_control(id_control_prelim),
    .rs1(id_rs1),
    .rs2(id_rs2),
    .ex_control(ex_control),
    .should_branch(ex_should_branch),
    .mem_control(mem_control),
    .wb_control(wb_control),
    .imem_wait(imem_wait),
    .dmem_wait(dmem_wait),
    .hazard(id_hazard),
    .if_pc_write_enable(if_pc_write_enable),
    .ifid_instruction_write_enable(ifid_instruction_write_enable),
    .pipe_enable(pipe_enable),
    .forward_rs1(id_rs1_forward),
    .forward_rs2(id_rs2_forward)
);

regfile id_regfile (
    .clk(clk),
    .reset_n(reset_n),
    .address_reg1(id_rs1),
    .address_reg2(id_rs2),
    .output_reg1(id_rs1_val),
    .output_reg2(id_rs2_val),
    .address_dest(wb_control.rd),
    .data_dest(wb_result),
    .write_dest(wb_control.write_reg)
);

always_comb begin
    if (id_hazard) begin
        id_control = 0;
    end else begin
        id_control = id_control_prelim;
    end

    // Select the forwarding mode for rs1
    case (id_rs1_forward)
        DECODE: id_rs1_forward_val = id_rs1_val;
        EXECUTE: id_rs1_forward_val = ex_alu_result;
        MEMORY: id_rs1_forward_val = mem_alu_result;
        WRITEBACK: id_rs1_forward_val = wb_result;
    endcase

    // Select the forwarding mode for rs2
    case (id_rs2_forward)
        DECODE: id_rs2_forward_val = id_rs2_val;
        EXECUTE: id_rs2_forward_val = ex_alu_result;
        MEMORY: id_rs2_forward_val = mem_alu_result;
        WRITEBACK: id_rs2_forward_val = wb_result;
    endcase
end

// -----
// Instruction decode / Execute boundary
// -----
always_ff @(posedge clk) begin
    if (!reset_n) begin
        ex_control <= 0;
        ex_pc <= 0;
        ex_rs1 <= 0;
        ex_rs2 <= 0;
        ex_immediate <= 0;
    end else if (pipe_enable) begin
        ex_control <= id_control;
        ex_pc <= id_pc;
        ex_rs1 <= id_rs1_forward_val;
        ex_rs2 <= id_rs2_forward_val;
        ex_immediate <= id_immediate;
    end
end

// -----
// Execute stage
// -----
logic [31:0] ex_rs1;
logic [31:0] ex_rs2;
logic [31:0] ex_pc;
logic [31:0] ex_immediate;

logic [31:0] ex_alu_lhs;
logic [31:0] ex_alu_rhs;
logic [31:0] ex_alu_result;

logic [31:0] ex_branch_partial;
logic [31:0] ex_branch;
logic ex_should_branch;

control_t ex_control;

alu ex_alu (
    .operation(ex_control.alu_op),
    .lhs(ex_alu_lhs),
    .rhs(ex_alu_rhs),
    .result(ex_alu_result)
);

always_comb begin
    // Select the ALU lhs
    case (ex_control.alu_select1)
        REG1: ex_alu_lhs = ex_rs1;
        PC: ex_alu_lhs = ex_pc;
    endcase
    // Select the ALU rhs
    case (ex_control.alu_select2)
        REG2: ex_alu_rhs = ex_rs2;
        IMMEDIATE: ex_alu_rhs = ex_immediate;
    endcase

    // Select the branching mode
    case (ex_control.branch_target)
        PC_REL: ex_branch_partial = ex_pc;
        REG_REL: ex_branch_partial = ex_rs1;
    endcase

    // Calculate the correct branch target
    ex_branch = ex_branch_partial + ex_immediate;

    // Check if we should branch
    if (ex_control.branch_mode == ALWAYS) begin
        ex_should_branch = 1;
    end else if (ex_control.branch_mode == CONDITIONAL) begin
        ex_should_branch = (ex_alu_result[0] == 1);
    end else begin
        ex_should_branch = 0;
    end
end

// -----
// Execute / Memory boundary
// -----
always_ff @(posedge clk) begin
    if (!reset_n) begin
        mem_control <= 0;
        mem_alu_result <= 0;
    end else if (pipe_enable) begin
        mem_control <= ex_control;
        mem_alu_result <= ex_alu_result;
    end
end

always_comb begin
    // RAM inputs are buffered in the RAM module
    dmem_address = ex_alu_result;
    dmem_enable = pipe_enable;
    dmem_write_data = ex_rs2;
    dmem_read_mode = ex_control.mem_read;
    dmem_read_enable = (ex_control.wb_select == MEM);
    dmem_write_mode = ex_control.mem_write;
    dmem_write_enable = ex_control.mem_write_enable;
end

// -----
// Memory stage
// -----
logic [31:0] mem_alu_result;

control_t mem_control;

// -----
// Memory / Writeback boundary
// -----
always_ff @(posedge clk) begin
    if (!reset_n) begin
        wb_control <= 0;
        wb_alu_result <= 0;
        wb_read_data <= 0;
    end else if (pipe_enable) begin
        wb_control <= mem_control;
        wb_alu_result <= mem_alu_result;
        wb_read_data <= dmem_read_data;
    end
end

// -----
// Writeback stage
// -----
logic [31:0] wb_alu_result;
logic [31:0] wb_read_data;
logic [31:0] wb_read_data_extended;
logic [31:0] wb_result;

always_comb begin
    // Sign extend the read memory value
    case (wb_control.mem_read)
        3'b000: wb_read_data_extended = {{24{wb_read_data[7]}}, wb_read_data[7:0]};
        3'b001: wb_read_data_extended = {{16{wb_read_data[15]}}, wb_read_data[15:0]};
        3'b010: wb_read_data_extended = wb_read_data;
        3'b100: wb_read_data_extended = {24'b0, wb_read_data[7:0]};
        3'b101: wb_read_data_extended = {16'b0, wb_read_data[15:0]};
        default: wb_read_data_extended = 0;
    endcase

    // Select the result to be written into the register
    case (wb_control.wb_select)
        REG: wb_result = wb_alu_result;
        MEM: wb_result = wb_read_data_extended;
    endcase
end

endmodule
