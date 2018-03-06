module riscv (
    input clk,
    input reset_n,

    output [9:0] led,
    output [7:0] hex0,
    output [7:0] hex1,
    output [7:0] hex2,
    output [7:0] hex3,
    output [7:0] hex4,
    output [7:0] hex5,
    input [9:0] switch,
    input uart_rx,
    output uart_tx
);

// Instruction memory signals
logic [31:0] imem_address;
logic imem_enable;
logic [31:0] imem_data;
logic imem_wait;

// Data memory signals
logic [31:0] dmem_address;
logic dmem_enable;
logic [31:0] dmem_write_data;
logic [31:0] dmem_read_data;
logic dmem_write_enable;
logic [2:0] dmem_write_mode;
logic dmem_read_enable;
logic [2:0] dmem_read_mode;
logic dmem_wait;

logic illegal_op;
logic [47:0] hex;

always_comb begin
    hex0 = hex[7:0];
    hex1 = hex[15:8];
    hex2 = hex[23:16];
    hex3 = hex[31:24];
    hex4 = hex[39:32];
    hex5 = hex[47:40];
end

core core0 (
    .clk(clk),
    .reset_n(reset_n),
    .illegal_op(illegal_op),

    .imem_address(imem_address),
    .imem_enable(imem_enable),
    .imem_data(imem_data),
    .imem_wait(imem_wait),

    .dmem_address(dmem_address),
    .dmem_enable(dmem_enable),
    .dmem_write_data(dmem_write_data),
    .dmem_read_data(dmem_read_data),
    .dmem_write_enable(dmem_write_enable),
    .dmem_write_mode(dmem_write_mode),
    .dmem_read_enable(dmem_read_enable),
    .dmem_read_mode(dmem_read_mode),
    .dmem_wait(dmem_wait)
);

memory memory0 (
    .clk(clk),
    .reset_n(reset_n),

    .led(led),
    .hex(hex),
    .switch(switch),

    .imem_address(imem_address),
    .imem_enable(imem_enable),
    .imem_data(imem_data),
    .imem_wait(imem_wait),

    .dmem_address(dmem_address),
    .dmem_enable(dmem_enable),
    .dmem_write_data(dmem_write_data),
    .dmem_read_data(dmem_read_data),
    .dmem_write_enable(dmem_write_enable),
    .dmem_write_mode(dmem_write_mode),
    .dmem_read_enable(dmem_read_enable),
    .dmem_read_mode(dmem_read_mode),
    .dmem_wait(dmem_wait)
);

endmodule