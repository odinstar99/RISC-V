typedef enum bit [0:0] {
    DIV_IDLE,
    DIV_STEP
} divider_state_t;

module divider (
    input clk,
    input reset_n,
    input start,
    input sign,
    input [31:0] divisor_input,
    input [31:0] divident_input,
    output [31:0] quotient_output,
    output [31:0] remainder_output,
    output busy
);

divider_state_t state;
divider_state_t state_next;
logic [5:0] counter;
logic [5:0] counter_next;
logic [63:0] divisor;
logic [63:0] divisor_next;
logic [31:0] quotient;
logic [31:0] quotient_next;
logic [63:0] remainder;
logic [63:0] remainder_next;
logic [31:0] quotient_output_next;
logic [31:0] remainder_output_next;
logic sign_divisor;
logic sign_divisor_next;
logic sign_divident;
logic sign_divident_next;

always_comb begin
    divisor_next = divisor;
    quotient_next = quotient;
    remainder_next = remainder;
    state_next = state;
    counter_next = counter;
    quotient_output_next = quotient_output;
    remainder_output_next = remainder_output;
    sign_divisor_next = sign_divisor;
    sign_divident_next = sign_divident;

    busy = (state == DIV_STEP);

    case (state)
        DIV_IDLE: begin
            if (start) begin
                if (!sign) begin
                    divisor_next = {divisor_input, 32'b0};
                    remainder_next = {32'b0, divident_input};
                    sign_divisor_next = 0;
                    sign_divident_next = 0;
                end else begin
                    sign_divisor_next = $signed(divisor_input) < 0;
                    sign_divident_next = $signed(divident_input) < 0;
                    divisor_next = {(sign_divisor_next ? -divisor_input : divisor_input), 32'b0};
                    remainder_next = {32'b0, (sign_divident_next ? -divident_input : divident_input)};
                end
                quotient_next = 0;
                state_next = DIV_STEP;
                counter_next = 32;
            end
        end
        DIV_STEP: begin
            logic [63:0] diff;
            diff = remainder - divisor;
            if ($signed(diff) < 0) begin
                quotient_next = {quotient[30:0], 1'b0};
                remainder_next = remainder;
            end else begin
                quotient_next = {quotient[30:0], 1'b1};
                remainder_next = diff;
            end
            divisor_next = divisor >> 1;
            if (counter == 0) begin
                state_next = DIV_IDLE;

                if (sign_divisor ^ sign_divident) begin
                    quotient_output_next = -quotient_next;
                end else begin
                    quotient_output_next = quotient_next;
                end
                if (sign_divident) begin
                    remainder_output_next = -remainder_next[31:0];
                end else begin
                    remainder_output_next = remainder_next[31:0];
                end
            end else begin
                state_next = DIV_STEP;
                counter_next = counter - 1;
            end
        end
    endcase
end

always_ff @(posedge clk) begin
    if (!reset_n) begin
        state <= DIV_IDLE;
        counter <= 0;
        divisor <= 0;
        quotient <= 0;
        remainder <= 0;
        quotient_output <= 0;
        remainder_output <= 0;
        sign_divisor <= 0;
        sign_divident <= 0;
    end else begin
        state <= state_next;
        counter <= counter_next;
        divisor <= divisor_next;
        quotient <= quotient_next;
        remainder <= remainder_next;
        quotient_output <= quotient_output_next;
        remainder_output <= remainder_output_next;
        sign_divisor <= sign_divisor_next;
        sign_divident <= sign_divident_next;
    end
end

endmodule
