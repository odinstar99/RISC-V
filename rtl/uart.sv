typedef enum bit [1:0] {
    IDLE,
    START,
    DATA,
    STOP
} uart_state_t;

module uart (
    input clk,
    input reset_n,

    input uart_rx,
    output uart_tx,

    input [7:0] tx_data,
    input tx_enable,
    output tx_busy
);

uart_state_t current_state;
uart_state_t next_state;
logic next_uart_tx;
logic [7:0] data;
logic [7:0] next_data;
logic [2:0] bitpos;
logic [2:0] next_bitpos;

always_comb begin
    tx_busy = (current_state != IDLE);
    next_state = current_state;
    next_data = data;
    next_bitpos = bitpos;
    next_baud_clk_reset = 0;
    next_uart_tx = uart_tx;

    case (current_state)
        IDLE: begin
            if (tx_enable) begin
                next_state = START;
                next_data = tx_data;
                next_baud_clk_reset = 1;
            end
        end
        START: begin
            next_uart_tx = 0;

            if (baud_clk_edge) begin
                next_state = DATA;
                next_bitpos = 3'h0;
            end
        end
        DATA: begin
            next_uart_tx = data[bitpos];

            if (baud_clk_edge) begin
                if (bitpos == 3'h7) begin
                    next_state = STOP;
                end
                else begin
                    next_bitpos = bitpos + 3'h1;
                end
            end
        end
        STOP: begin
            next_uart_tx = 1;

            if (baud_clk_edge) begin
                next_state = IDLE;
            end
        end
    endcase
end

always_ff @(posedge clk) begin
    if (!reset_n) begin
        current_state <= IDLE;
        uart_tx <= 1'b1;
        baud_clk_reset <= 1'b0;
        data <= 8'h0;
        bitpos <= 3'b0;
    end else begin
        current_state <= next_state;
        uart_tx <= next_uart_tx;
        baud_clk_reset <= next_baud_clk_reset;
        data <= next_data;
        bitpos <= next_bitpos;
    end
end

/* Baudrate generator */
parameter CLK_FREQ = 65000000;
parameter BAUD_RATE = 230400;
parameter BAUD_CLK_ACC_WIDTH = 16;
localparam BAUD_CLK_ACC_INC = ((BAUD_RATE << (BAUD_CLK_ACC_WIDTH - 4)) + (CLK_FREQ >> 5)) / (CLK_FREQ >> 4);

logic [BAUD_CLK_ACC_WIDTH:0] acc;
logic [BAUD_CLK_ACC_WIDTH:0] acc_next;

logic baud_clk_edge;
logic baud_clk_reset;
logic next_baud_clk_reset;

always_comb begin
    baud_clk_edge = acc[BAUD_CLK_ACC_WIDTH];
    acc_next = acc[BAUD_CLK_ACC_WIDTH - 1:0] + BAUD_CLK_ACC_INC;
end

always_ff @(posedge clk) begin
    if (!reset_n || baud_clk_reset) begin
        acc <= 0;
    end else begin
        acc <= acc_next;
    end
end

endmodule
