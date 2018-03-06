module riscv (
    input clk,
    input reset_n,

    output [9:0] led,
    input uart_rx,
    output uart_tx
);

logic [31:0] rom_address;
logic rom_enable;
logic [31:0] rom_data;

logic [31:0] ram_address;
logic ram_enable;
logic [31:0] ram_write_data;
logic [31:0] ram_read_data;
logic ram_write_enable;
logic [2:0] ram_write_mode;
logic ram_read_enable;
logic [2:0] ram_read_mode;

logic illegal_op;
logic rom_wait;
logic ram_wait;

core core0 (
    .clk(clk),
    .reset_n(reset_n),
    .illegal_op(illegal_op),

    .rom_address(rom_address),
    .rom_enable(rom_enable),
    .rom_data(rom_data),
     .rom_wait(rom_wait),

    .ram_address(ram_address),
    .ram_enable(ram_enable),
    .ram_write_data(ram_write_data),
    .ram_read_data(ram_read_data),
    .ram_write_enable(ram_write_enable),
    .ram_write_mode(ram_write_mode),
    .ram_read_enable(ram_read_enable),
    .ram_read_mode(ram_read_mode),
     .ram_wait(ram_wait)
);

logic dmem_rom_enable;
logic dmem_ram_enable;
logic [31:0] dmem_rom_q;
logic [31:0] dmem_ram_q;
logic [31:0] dmem_ram_address;
logic [2:0] dmem_ram_read_mode;
logic dmem_ram_write_enable;
logic [31:0] dmem_ram_write_data;
logic [3:0] dmem_ram_write_byteen;

logic [31:0] dmem_led_write_data;
logic dmem_led_write_enable;
logic dmem_led_enable;
logic [31:0] led_output;

always begin
    led[9:0] = led_output[9:0];
    rom_wait = 0;
    ram_wait = 0;
    //
    // INPUT SIDE
    //
    dmem_rom_enable = 0;
    dmem_ram_enable = 0;
    dmem_led_enable = 0;
    dmem_led_write_data = 0;
    dmem_led_write_enable = 0;
    dmem_ram_write_data = 0;
    dmem_ram_write_byteen = 0;
    dmem_ram_write_enable = 0;
    if (ram_address[31:16] == 16'h8000) begin
        // RAM
        dmem_ram_enable = ram_enable;

        dmem_ram_write_enable = ram_write_enable;

        if (ram_write_mode[1:0] == 0) begin
            // Store byte
            case (ram_address[1:0])
                0: begin
                    dmem_ram_write_data = {24'h0, ram_write_data[7:0]};
                    dmem_ram_write_byteen = 4'b0001;
                end
                1: begin
                    dmem_ram_write_data = {16'h0, ram_write_data[7:0], 8'h0};
                    dmem_ram_write_byteen = 4'b0010;
                end
                2: begin
                    dmem_ram_write_data = {8'h0, ram_write_data[7:0], 16'h0};
                    dmem_ram_write_byteen = 4'b0100;
                end
                3: begin
                    dmem_ram_write_data = {ram_write_data[7:0], 24'h0};
                    dmem_ram_write_byteen = 4'b1000;
                end
            endcase
        end else if (ram_write_mode[1:0] == 1) begin
            // Store halfword
            dmem_ram_write_data = 0;
            dmem_ram_write_byteen = 4'b0000;
        end else if (ram_write_mode[1:0] == 2) begin
            // Store word
            dmem_ram_write_data = ram_write_data;
            dmem_ram_write_byteen = 4'b1111;
        end else begin
            // Unknown store
            dmem_ram_write_data = 0;
            dmem_ram_write_byteen = 4'b0000;
        end
    end else if (ram_address[31:16] == 16'h7000) begin
        dmem_led_enable = ram_enable;
        dmem_led_write_enable = ram_write_enable;
        if (ram_write_mode[1:0] == 2) begin
            dmem_led_write_data = ram_write_data;
        end
    end else begin
         // ROM
         dmem_rom_enable = ram_enable;
    end

    //
    // OUTPUT SIDE
    //
    if (dmem_ram_address[31:16] == 16'h8000) begin
        // RAM
        if (dmem_ram_read_mode[1:0] == 0) begin
            // Read byte
            case (dmem_ram_address[1:0])
                0: ram_read_data = {24'h0, dmem_rom_q[7:0]};
                1: ram_read_data = {24'h0, dmem_rom_q[15:8]};
                2: ram_read_data = {24'h0, dmem_rom_q[23:16]};
                3: ram_read_data = {24'h0, dmem_rom_q[31:24]};
            endcase
        end else if (dmem_ram_read_mode[1:0] == 1) begin
            // Read halfword
            ram_read_data = 0;
        end else if (dmem_ram_read_mode[1:0] == 2) begin
            // Read word
            ram_read_data = dmem_ram_q;
        end else begin
            ram_read_data = 0;
        end
    end else begin
         // ROM
         if (dmem_ram_read_mode[1:0] == 0) begin
            // Read byte
            case (dmem_ram_address[1:0])
                0: ram_read_data = {24'h0, dmem_rom_q[7:0]};
                1: ram_read_data = {24'h0, dmem_rom_q[15:8]};
                2: ram_read_data = {24'h0, dmem_rom_q[23:16]};
                3: ram_read_data = {24'h0, dmem_rom_q[31:24]};
            endcase
         end else if (dmem_ram_read_mode[1:0] == 1) begin
            // Read halfword
            ram_read_data = 0;
         end else if (dmem_ram_read_mode[1:0] == 2) begin
            // Read word
            ram_read_data = dmem_rom_q;
         end else begin
            ram_read_data = 0;
         end
    end
end

always @(posedge clk) begin
    if (!reset_n) begin
        dmem_ram_address <= 0;
        dmem_ram_read_mode <= 0;
        led_output <= 0;
    end else begin
        dmem_ram_address <= ram_address;
        dmem_ram_read_mode <= ram_read_mode;
        if (dmem_led_enable && dmem_led_write_enable)
            led_output <= dmem_led_write_data;
        else
            led_output <= led_output;
     end
end

rom rom0 (
    .address_a(rom_address[15:2]),
    .address_b(ram_address[15:2]),
    .clock_a(clk),
    .clock_b(clk),
    .enable_a(rom_enable),
    .enable_b(dmem_rom_enable),
    .q_a(rom_data),
    .q_b(dmem_rom_q)
);

ram ram0 (
     .address(ram_address[15:2]),
     .byteena(dmem_ram_write_byteen),
     .clken(dmem_ram_enable),
     .clock(clk),
     .data(dmem_ram_write_data),
     .wren(dmem_ram_write_enable),
     .q(dmem_ram_q)
);

endmodule