`include "types.sv"

module hazard (
    input control_t id_control,
    input [4:0] rs1,
    input [4:0] rs2,
    input control_t ex_control,
    input should_branch,
    input control_t mem_control,
    input control_t wb_control,
    input imem_wait,
    input dmem_wait,
    output hazard,
    output if_pc_write_enable,
    output ifid_instruction_write_enable,
    output pipe_enable,
    output forward_t forward_rs1,
    output forward_t forward_rs2
);

always_comb begin
    hazard = 0;
    if_pc_write_enable = 1;
    ifid_instruction_write_enable = 1;
    pipe_enable = 1;
    forward_rs1 = DECODE;
    forward_rs2 = DECODE;

    if (imem_wait || dmem_wait) begin
        pipe_enable = 0;
    end

    // Forwarding logic
    if ((ex_control.wb_select != REG && ex_control.write_reg && (ex_control.rd == rs1 || ex_control.rd == rs2) && ex_control.rd != 0) ||
        (mem_control.wb_select != REG && mem_control.write_reg && (mem_control.rd == rs1 || mem_control.rd == rs2) && mem_control.rd != 0))
    begin
        hazard = 1;
        if_pc_write_enable = 0;
        ifid_instruction_write_enable = 0;
    end else begin
        if (rs1 != 0) begin
            if (ex_control.write_reg && ex_control.rd == rs1) begin
                forward_rs1 = EXECUTE;
            end else if (mem_control.write_reg && mem_control.rd == rs1) begin
                forward_rs1 = MEMORY;
            end else if (wb_control.write_reg && wb_control.rd == rs1) begin
                forward_rs1 = WRITEBACK;
            end
        end
        if (rs2 != 0) begin
            if (ex_control.write_reg && ex_control.rd == rs2) begin
                forward_rs2 = EXECUTE;
            end else if (mem_control.write_reg && mem_control.rd == rs2) begin
                forward_rs2 = MEMORY;
            end else if (wb_control.write_reg && wb_control.rd == rs2) begin
                forward_rs2 = WRITEBACK;
            end
        end
    end

    // Data hazards without forwarding
    // if ((ex_control.write_reg && ((ex_control.rd == rs1 && rs1 != 0)|| (ex_control.rd == rs2 && rs2 != 0))) ||
    //     (mem_control.write_reg && ((mem_control.rd == rs1 && rs1 != 0) || (mem_control.rd == rs2 && rs2 != 0))) ||
    //     (wb_control.write_reg && ((wb_control.rd == rs1 && rs1 != 0) || (wb_control.rd == rs2 && rs2 != 0))))
    // begin
    //     hazard = 1;
    //     if_pc_write_enable = 0;
    //     ifid_instruction_write_enable = 0;
    // end

    // Branching hazards
    if (mem_control.branch_mode != NEVER) begin
        hazard = 1;
        if_pc_write_enable = 1;
        ifid_instruction_write_enable = 1;
    end else if (ex_control.branch_mode != NEVER) begin
        hazard = 1;
        if_pc_write_enable = should_branch;
        ifid_instruction_write_enable = 0;
    end else if (id_control.branch_mode != NEVER && hazard == 0) begin
        hazard = 0;
        if_pc_write_enable = 0;
        ifid_instruction_write_enable = 0;
    end
end

endmodule
