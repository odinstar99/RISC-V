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
logic [4:0] counter;
logic [4:0] counter_next;
logic [31:0] divisor;
logic [31:0] divisor_next;
logic [63:0] remainder_quotient;
logic [63:0] remainder_quotient_next;
logic [31:0] quotient_output_next;
logic [31:0] remainder_output_next;
logic sign_divisor;
logic sign_divisor_next;
logic sign_divident;
logic sign_divident_next;
logic [31:0] last_divisor;
logic [31:0] last_divisor_next;
logic [31:0] last_divident;
logic [31:0] last_divident_next;
logic last_sign;
logic last_sign_next;

always_comb begin
    divisor_next = divisor;
    remainder_quotient_next = remainder_quotient;
    state_next = state;
    counter_next = counter;
    quotient_output_next = quotient_output;
    remainder_output_next = remainder_output;
    sign_divisor_next = sign_divisor;
    sign_divident_next = sign_divident;
    last_divisor_next = last_divisor;
    last_divident_next = last_divident;
    last_sign_next = last_sign;

    busy = (state == DIV_STEP);

    case (state)
        DIV_IDLE: begin
            if (start) begin
                if (last_divisor == divisor_input && last_divident == divident_input && last_sign == sign) begin
                    state_next = DIV_IDLE;
                end else begin
                    if (!sign) begin
                        divisor_next = divisor_input;
                        remainder_quotient_next = {32'b0, divident_input};
                        sign_divisor_next = 0;
                        sign_divident_next = 0;
                    end else begin
                        sign_divisor_next = $signed(divisor_input) < 0;
                        sign_divident_next = $signed(divident_input) < 0;
                        divisor_next = (sign_divisor_next ? -divisor_input : divisor_input);
                        remainder_quotient_next = {32'b0, (sign_divident_next ? -divident_input : divident_input)};
                    end
                    state_next = DIV_STEP;
                    counter_next = 31;
                    last_divisor_next = divisor_input;
                    last_divident_next = divident_input;
                    last_sign_next = sign;
                end
            end
        end
        DIV_STEP: begin
            logic [32:0] diff;
            diff = remainder_quotient[63:31] - {1'b0, divisor};

            if ($signed(diff) < 0) begin
                remainder_quotient_next = {remainder_quotient[62:0], 1'b0};
            end else begin
                remainder_quotient_next = {diff[31:0], remainder_quotient[30:0], 1'b1};
            end

            if (counter == 0) begin
                state_next = DIV_IDLE;

                if (sign_divisor ^ sign_divident) begin
                    quotient_output_next = -remainder_quotient_next[31:0];
                end else begin
                    quotient_output_next = remainder_quotient_next[31:0];
                end
                if (sign_divident) begin
                    remainder_output_next = -remainder_quotient_next[63:32];
                end else begin
                    remainder_output_next = remainder_quotient_next[63:32];
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
        remainder_quotient <= 0;
        quotient_output <= 0;
        remainder_output <= 0;
        sign_divisor <= 0;
        sign_divident <= 0;
        last_divisor <= 1;
        last_divident <= 0;
        last_sign <= 0;
    end else begin
        state <= state_next;
        counter <= counter_next;
        divisor <= divisor_next;
        remainder_quotient <= remainder_quotient_next;
        quotient_output <= quotient_output_next;
        remainder_output <= remainder_output_next;
        sign_divisor <= sign_divisor_next;
        sign_divident <= sign_divident_next;
        last_divisor <= last_divisor_next;
        last_divident <= last_divident_next;
        last_sign <= last_sign_next;
    end
end

endmodule
