`include "types.sv"

module alu (
    input alu_operation_t operation,
    input [31:0] lhs,
    input [31:0] rhs,
    output [31:0] result
);

always_comb begin
    case (operation)
        ADD: result = lhs + rhs;
        SUB: result = lhs - rhs;
        AND: result = lhs & rhs;
         OR: result = lhs | rhs;
        XOR: result = lhs ^ rhs;
        SLL: result = lhs << rhs[4:0];
        SRL: result = lhs >> rhs[4:0];
        SRA: result = $signed(lhs) >>> rhs[4:0];
         EQ: result = (lhs == rhs) ? 1 : 0;
         NE: result = (lhs != rhs) ? 1 : 0;
         LT: result = ($signed(lhs) < $signed(rhs)) ? 1 : 0;
         GE: result = ($signed(lhs) >= $signed(rhs)) ? 1 : 0;
        LTU: result = (lhs < rhs) ? 1 : 0;
        GEU: result = (lhs >= rhs) ? 1 : 0;
        IMM: result = rhs;
        PC4: result = lhs + 4;
        default: result = 0;
    endcase
end

endmodule
