`include "types.sv"

module decode (
    input [31:0] instruction,

    output [4:0] rs1,
    output [4:0] rs2,
    output [31:0] immediate,

    output illegal_op,
    output control_t control
);

always_comb begin
    logic [6:0] opcode;
    logic [2:0] funct3;
    opcode = instruction[6:0];
    funct3 = instruction[14:12];
    // Basic register assignment
    rs1 = instruction[19:15];
    rs2 = instruction[24:20];
    control.rd = instruction[11:7];

    // Calculate the immediate
    case (opcode)
        // Type I
        7'b0000011, 7'b0010011, 7'b1100111, 7'b1110011: // LOAD, ALUIMM, JALR, SYSTEM
            immediate = {{20{instruction[31]}}, instruction[31:20]};
        // Type S
        7'b0100011: // STORE
            immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        // Type B
        7'b1100011: // BRANCH
            immediate = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
        // Type U
        7'b0110111, 7'b0010111: // LUI, AUIPC
            immediate = {instruction[31:12], 12'b0};
        // Type J
        7'b1101111: // JAL
            immediate = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:25], instruction[24:21], 1'b0};
        // Any other instruction
        default:
            immediate = 0;
    endcase

    illegal_op = 0;
    control.instruction_valid = 1;
    control.branch_taken = 0;
    // Decode instruction to correct control signals
    case (opcode)
        7'b0110111: begin // LUI
            control.write_reg = 1;
            control.wb_select = ALU;
            control.alu_op = IMM;
            control.alu_select1 = REG1;
            control.alu_select2 = IMMEDIATE;
            control.branch_mode = NEVER;
            control.branch_target = PC_REL;
            control.mem_write_enable = 0;
            control.mem_write = 0;
            control.mem_read = 0;
        end
        7'b0010111: begin // AUIPC
            control.write_reg = 1;
            control.wb_select = ALU;
            control.alu_op = ADD;
            control.alu_select1 = PC;
            control.alu_select2 = IMMEDIATE;
            control.branch_mode = NEVER;
            control.branch_target = PC_REL;
            control.mem_write_enable = 0;
            control.mem_write = 0;
            control.mem_read = 0;
        end
        7'b1101111: begin // JAL
            control.write_reg = 1;
            control.wb_select = ALU;
            control.alu_op = PC4;
            control.alu_select1 = PC;
            control.alu_select2 = REG2;
            control.branch_mode = ALWAYS;
            control.branch_target = PC_REL;
            control.mem_write_enable = 0;
            control.mem_write = 0;
            control.mem_read = 0;
        end
        7'b1100111: begin // JALR
            control.write_reg = 1;
            control.wb_select = ALU;
            control.alu_op = PC4;
            control.alu_select1 = PC;
            control.alu_select2 = REG2;
            control.branch_mode = ALWAYS;
            control.branch_target = REG_REL;
            control.mem_write_enable = 0;
            control.mem_write = 0;
            control.mem_read = 0;
        end
        7'b1100011: begin // BRANCH
            control.write_reg = 0;
            control.wb_select = ALU;
            control.alu_select1 = REG1;
            control.alu_select2 = REG2;
            control.branch_mode = CONDITIONAL;
            control.branch_target = PC_REL;
            control.mem_write_enable = 0;
            control.mem_write = 0;
            control.mem_read = 0;
            case (funct3)
                3'b000: control.alu_op = EQ;
                3'b001: control.alu_op = NE;
                3'b100: control.alu_op = LT;
                3'b101: control.alu_op = GE;
                3'b110: control.alu_op = LTU;
                3'b111: control.alu_op = GEU;
                default: begin
                    illegal_op = 1;
                    control = 0;
                end
            endcase
        end
        7'b0000011: begin // LOAD
            control.write_reg = 1;
            control.wb_select = MEM;
            control.alu_op = ADD;
            control.alu_select1 = REG1;
            control.alu_select2 = IMMEDIATE;
            control.branch_mode = NEVER;
            control.branch_target = PC_REL;
            control.mem_write_enable = 0;
            control.mem_write = 0;
            control.mem_read = funct3;
        end
        7'b0100011: begin // STORE
            control.write_reg = 0;
            control.wb_select = ALU;
            control.alu_op = ADD;
            control.alu_select1 = REG1;
            control.alu_select2 = IMMEDIATE;
            control.branch_mode = NEVER;
            control.branch_target = PC_REL;
            control.mem_write_enable = 1;
            control.mem_write = funct3;
            control.mem_read = 0;
        end
        7'b0010011, 7'b0110011: begin // ALUIMM, ALUREG
            control.write_reg = 1;
            control.wb_select = ALU;
            control.alu_select1 = REG1;
            if (opcode == 7'b0010011)
                control.alu_select2 = IMMEDIATE;
            else
                control.alu_select2 = REG2;
            control.branch_mode = NEVER;
            control.branch_target = PC_REL;
            control.mem_write_enable = 0;
            control.mem_write = 0;
            control.mem_read = 0;

            if (opcode == 7'b0010011 || instruction[31:25] == 7'b0 || instruction[31:25] == 7'h20) begin
                case (funct3)
                    3'b000: control.alu_op = (instruction[30] && opcode == 7'b0110011) ? SUB : ADD;
                    3'b001: control.alu_op = SLL;
                    3'b010: control.alu_op = LT;
                    3'b011: control.alu_op = LTU;
                    3'b100: control.alu_op = XOR;
                    3'b101: control.alu_op = (instruction[30]) ? SRA : SRL;
                    3'b110: control.alu_op = OR;
                    3'b111: control.alu_op = AND;
                endcase
            end else begin
                illegal_op = 1;
                control = 0;
            end
        end
        7'b1110011: begin // SYSTEM
            if (funct3 == 3'b010 && rs1 == 0) begin
                control.write_reg = 1;
                control.wb_select = CSR;
                control.alu_op = IMM;
                control.alu_select1 = REG1;
                control.alu_select2 = IMMEDIATE;
                control.branch_mode = NEVER;
                control.branch_target = PC_REL;
                control.mem_write_enable = 0;
                control.mem_write = 0;
                control.mem_read = 0;
            end else begin
                illegal_op = 1;
                control = 0;
            end
        end
        default: begin // Unknown operation
            illegal_op = 1;
            control = 0;
        end
    endcase
end

endmodule
