module mmio (
    input reset_n,

    input [13:0] address,
    input [3:0] byteena,
    input clken,
    input clock,
    input [31:0] data,
    input wren,
    output [31:0] q,

    output [9:0] led,
    output [47:0] hex,
    input [9:0] switch,
    output [11:0] bg_color
);

logic [13:0] internal_address;
logic [3:0] internal_byteena;
logic [31:0] internal_data;
logic internal_wren;

/*
 * Config register:
 * 0: Enable leds
 * 1: Enable 7-segment displays
 * 1: Hex mode (0: number, 1: segments)
 */
logic [2:0] config_state;
logic [2:0] next_config_state;

logic [9:0] led_state;
logic [9:0] next_led_state;

logic [47:0] hex_state;
logic [47:0] next_hex_state;
logic [47:0] hex_decoded;
allsegments allsegments0 (
    .in(hex_state[23:0]),
    .segments(hex_decoded)
);

logic [9:0] switch_state;

logic [11:0] bg_color_state;
logic [11:0] next_bg_color_state;

always_comb begin
    if (config_state[0]) begin
        led = led_state;
    end else begin
        led = 0;
    end
    if (config_state[1]) begin
        hex = (config_state[2] ? ~hex_state : hex_decoded);
    end else begin
        hex = 48'hffffffffffff;
    end
    bg_color = bg_color_state;

    next_config_state = config_state;
    next_led_state = led_state;
    next_hex_state = hex_state;
    next_bg_color_state = bg_color_state;

    case (internal_address)
        14'h0000: q = {29'b0, config_state};
        14'h0001: q = {22'b0, led_state};
        14'h0002: q = hex_state[31:0];
        14'h0003: q = {16'b0, hex_state[47:32]};
        14'h0004: q = {22'b0, switch_state};
        14'h0005: q = {20'b0, bg_color_state};
        default: q = 0;
    endcase

    if (internal_wren) begin
        case (internal_address)
            14'h0000: begin
                if (internal_byteena[0])
                    next_config_state[2:0] = internal_data[2:0];
            end
            14'h0001: begin
                if (internal_byteena[0])
                    next_led_state[7:0] = internal_data[7:0];
                if (internal_byteena[1])
                    next_led_state[9:8] = internal_data[9:8];
            end
            14'h0002: begin
                if (internal_byteena[0])
                    next_hex_state[7:0] = internal_data[7:0];
                if (internal_byteena[1])
                    next_hex_state[15:8] = internal_data[15:8];
                if (internal_byteena[2])
                    next_hex_state[23:16] = internal_data[23:16];
                if (internal_byteena[3])
                    next_hex_state[31:24] = internal_data[31:24];
            end
            14'h0003: begin
                if (internal_byteena[0])
                    next_hex_state[39:32] = internal_data[7:0];
                if (internal_byteena[1])
                    next_hex_state[47:40] = internal_data[15:8];
            end
            14'h0005: begin
                if (internal_byteena[0])
                    next_bg_color_state[7:0] = internal_data[7:0];
                if (internal_byteena[1])
                    next_bg_color_state[11:8] = internal_data[11:8];
            end
        endcase
    end
end

always_ff @(posedge clock) begin
    if (!reset_n) begin
        internal_address <= 0;
        internal_byteena <= 0;
        internal_data <= 0;
        internal_wren <= 0;
    end else if (clken) begin
        internal_address <= address;
        internal_byteena <= byteena;
        internal_data <= data;
        internal_wren <= wren;
    end else begin
        // Reset the write enable after a single cycle
        internal_wren <= 0;
    end

    if (!reset_n) begin
        led_state <= 0;
        hex_state <= 0;
        config_state <= 0;
        bg_color_state <= 0;
    end else begin
        led_state <= next_led_state;
        hex_state <= next_hex_state;
        config_state <= next_config_state;
        bg_color_state <= next_bg_color_state;
    end
    switch_state <= switch;
end

endmodule
