typedef enum {
    NORMAL,
    UNALIGNED
} memory_state_t;

module memory(
    input clk,
    input reset_n,

    output [9:0] led,
    output [47:0] hex,
    input [9:0] switch,
    output [11:0] bg_color,
    input uart_rx,
    output uart_tx,

    input [31:0] imem_address,
    input imem_enable,
    output [31:0] imem_data,
    output imem_wait,

    input [31:0] dmem_address,
    input dmem_enable,
    input [31:0] dmem_write_data,
    output [31:0] dmem_read_data,
    input dmem_write_enable,
    input [2:0] dmem_write_mode,
    input dmem_read_enable,
    input [2:0] dmem_read_mode,
    output dmem_wait
);

rom rom0 (
    .address_a(imem_address[15:2]),
    .address_b(selected_dmem_address[15:2]),
    .clock_a(clk),
    .clock_b(clk),
    .enable_a(imem_enable),
    .enable_b(rom_enable),
    .q_a(imem_data),
    .q_b(rom_q)
);

ram ram0 (
    .address(selected_dmem_address[15:2]),
    .byteena(ram_byteen),
    .clken(ram_enable),
    .clock(clk),
    .data(ram_write_data),
    .wren(ram_write_enable),
    .q(ram_q)
);

mmio mmio0 (
    .reset_n(reset_n),
    .address(selected_dmem_address[15:2]),
    .byteena(mmio_byteen),
    .clken(mmio_enable),
    .clock(clk),
    .data(mmio_write_data),
    .wren(mmio_write_enable),
    .q(mmio_q),
    .led(led),
    .hex(hex),
    .switch(switch),
    .bg_color(bg_color),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx)
);

logic [31:0] selected_dmem_address;
// ROM control signals
logic rom_enable;
// RAM control signals
logic ram_enable;
logic ram_write_enable;
logic [31:0] ram_write_data;
logic [3:0] ram_byteen;
// MMIO control signals
logic mmio_enable;
logic mmio_write_enable;
logic [31:0] mmio_write_data;
logic [3:0] mmio_byteen;

// Memory outputs
logic [31:0] rom_q;
logic [31:0] ram_q;
logic [31:0] mmio_q;

// Internal state storage
memory_state_t memory_state;
memory_state_t next_memory_state;
logic [31:0] last_dmem_address;
logic [2:0] last_dmem_read_mode;
logic [31:0] last_dmem_read_data;
logic [2:0] last_dmem_write_mode;
logic [31:0] last_dmem_write_data;
logic last_dmem_enable;
logic last_dmem_write_enable;

always begin
    // Internal lines
    logic [31:0] dmem_read_data_internal;
    logic [31:0] dmem_write_data_internal;
    logic [3:0] dmem_byteen_internal;

    imem_wait = 0;
    dmem_wait = 0;
    next_memory_state = NORMAL;

    if (memory_state == NORMAL) begin
        //
        // INPUT SIDE
        //

        // Set up the write data and the byte enable
        dmem_write_data_internal = 0;
        dmem_byteen_internal = 0;
        if (dmem_write_mode[1:0] == 0) begin
            // Store byte
            case (dmem_address[1:0])
                0: dmem_write_data_internal = {24'h0, dmem_write_data[7:0]};
                1: dmem_write_data_internal = {16'h0, dmem_write_data[7:0], 8'h0};
                2: dmem_write_data_internal = {8'h0, dmem_write_data[7:0], 16'h0};
                3: dmem_write_data_internal = {dmem_write_data[7:0], 24'h0};
            endcase
            dmem_byteen_internal = (4'b1 << dmem_address[1:0]);
        end else if (dmem_write_mode[1:0] == 1) begin
            // Store halfword
            case (dmem_address[1:0])
                0: dmem_write_data_internal = {16'h0, dmem_write_data[15:0]};
                1: dmem_write_data_internal = {8'h0, dmem_write_data[15:0], 8'h0};
                2: dmem_write_data_internal = {dmem_write_data[15:0], 16'h0};
                3: dmem_write_data_internal = {dmem_write_data[7:0], 24'h0};
            endcase
            case (dmem_address[1:0])
                0: dmem_byteen_internal = 4'b0011;
                1: dmem_byteen_internal = 4'b0110;
                2: dmem_byteen_internal = 4'b1100;
                3: dmem_byteen_internal = 4'b1000;
            endcase
        end else if (dmem_write_mode[1:0] == 2) begin
            // Store word
            case (dmem_address[1:0])
                0: dmem_write_data_internal = dmem_write_data;
                1: dmem_write_data_internal = {dmem_write_data[23:0], 8'h0};
                2: dmem_write_data_internal = {dmem_write_data[15:0], 16'h0};
                3: dmem_write_data_internal = {dmem_write_data[7:0], 24'h0};
            endcase
            case (dmem_address[1:0])
                0: dmem_byteen_internal = 4'b1111;
                1: dmem_byteen_internal = 4'b1110;
                2: dmem_byteen_internal = 4'b1100;
                3: dmem_byteen_internal = 4'b1000;
            endcase
        end

        if (dmem_write_enable && ((dmem_write_mode[1:0] == 1 && dmem_address[1:0] == 3) || (dmem_write_mode[1:0] == 2 && dmem_address[1:0] != 0)) ||
            dmem_read_enable && ((dmem_read_mode[1:0] == 1 && dmem_address[1:0] == 3) || (dmem_read_mode[1:0] == 2 && dmem_address[1:0] != 0)))
        begin
            next_memory_state = UNALIGNED;
        end

        selected_dmem_address = dmem_address;
        // Default ROM settings
        rom_enable = 0;
        // Default RAM settings
        ram_enable = 0;
        ram_write_enable = 0;
        ram_write_data = 0;
        ram_byteen = 0;
        // Default MMIO settings
        mmio_enable = 0;
        mmio_write_enable = 0;
        mmio_write_data = 0;
        mmio_byteen = 0;

        // Select the correct inputs for each memory region
        if (selected_dmem_address[31:16] == 16'h8000) begin
            // RAM
            ram_enable = dmem_enable;
            ram_write_enable = dmem_write_enable;
            ram_write_data = dmem_write_data_internal;
            ram_byteen = dmem_byteen_internal;
        end else if (selected_dmem_address[31:16] == 16'h0000) begin
            // ROM
            rom_enable = dmem_enable;
        end else if (selected_dmem_address[31:16] == 16'h7000) begin
            mmio_enable = dmem_enable;
            mmio_write_enable = dmem_write_enable;
            mmio_write_data = dmem_write_data_internal;
            mmio_byteen = dmem_byteen_internal;
        end

        //
        // OUTPUT SIDE
        //
        case (last_dmem_address[31:16])
            16'h0000: dmem_read_data_internal = rom_q;
            16'h7000: dmem_read_data_internal = mmio_q;
            16'h8000: dmem_read_data_internal = ram_q;
            default: dmem_read_data_internal = 0;
        endcase

        // Select the correct bytes from the output
        dmem_read_data = 0;
        if (last_dmem_read_mode[1:0] == 0) begin
            // Read byte
            case (last_dmem_address[1:0])
                0: dmem_read_data = {24'h0, dmem_read_data_internal[7:0]};
                1: dmem_read_data = {24'h0, dmem_read_data_internal[15:8]};
                2: dmem_read_data = {24'h0, dmem_read_data_internal[23:16]};
                3: dmem_read_data = {24'h0, dmem_read_data_internal[31:24]};
            endcase
         end else if (last_dmem_read_mode[1:0] == 1) begin
            // Read halfword
            case (last_dmem_address[1:0])
                0: dmem_read_data = {16'h0, dmem_read_data_internal[15:0]};
                1: dmem_read_data = {16'h0, dmem_read_data_internal[23:8]};
                2: dmem_read_data = {16'h0, dmem_read_data_internal[31:16]};
                3: dmem_read_data = {16'h0, dmem_read_data_internal[7:0], last_dmem_read_data[31:24]};
            endcase
         end else if (last_dmem_read_mode[1:0] == 2) begin
            // Read word
            case (last_dmem_address[1:0])
                0: dmem_read_data = dmem_read_data_internal;
                1: dmem_read_data = {dmem_read_data_internal[7:0], last_dmem_read_data[31:8]};
                2: dmem_read_data = {dmem_read_data_internal[15:0], last_dmem_read_data[31:16]};
                3: dmem_read_data = {dmem_read_data_internal[23:0], last_dmem_read_data[31:24]};
            endcase
         end
    end else begin
        //
        // INPUT SIDE
        //
        dmem_wait = 1;

        // Set up the write data and the byte enable
        dmem_write_data_internal = 0;
        dmem_byteen_internal = 0;
        if (last_dmem_write_mode[1:0] == 0) begin
            // Store byte, this should never be the case
            dmem_write_data_internal = 0;
            dmem_byteen_internal = 0;
        end else if (last_dmem_write_mode[1:0] == 1) begin
            // Store halfword
            if (last_dmem_address[1:0] == 3) begin
                dmem_write_data_internal = {24'h0, last_dmem_write_data[15:8]};
                dmem_byteen_internal = 4'b0001;
            end else begin
                dmem_write_data_internal = 0;
                dmem_byteen_internal = 0;
            end
        end else if (last_dmem_write_mode[1:0] == 2) begin
            // Store word
            case (last_dmem_address[1:0])
                0: dmem_write_data_internal = 0;
                1: dmem_write_data_internal = {24'h0, last_dmem_write_data[31:24]};
                2: dmem_write_data_internal = {16'h0, last_dmem_write_data[31:16]};
                3: dmem_write_data_internal = {8'h0, last_dmem_write_data[31:8]};
            endcase
            case (last_dmem_address[1:0])
                0: dmem_byteen_internal = 0;
                1: dmem_byteen_internal = 4'b0001;
                2: dmem_byteen_internal = 4'b0011;
                3: dmem_byteen_internal = 4'b0111;
            endcase
        end

        selected_dmem_address = last_dmem_address + 32'h4;
        // Default ROM settings
        rom_enable = 0;
        // Default RAM settings
        ram_enable = 0;
        ram_write_enable = 0;
        ram_write_data = 0;
        ram_byteen = 0;
        // Default MMIO settings
        mmio_enable = 0;
        mmio_write_enable = 0;
        mmio_write_data = 0;
        mmio_byteen = 0;

        // Select the correct inputs for each memory region
        if (selected_dmem_address[31:16] == 16'h8000) begin
            // RAM
            ram_enable = last_dmem_enable;
            ram_write_enable = last_dmem_write_enable;
            ram_write_data = dmem_write_data_internal;
            ram_byteen = dmem_byteen_internal;
        end else if (selected_dmem_address[31:16] == 16'h0000) begin
            // ROM
            rom_enable = last_dmem_enable;
        end else if (selected_dmem_address[31:16] == 16'h7000) begin
            mmio_enable = last_dmem_enable;
            mmio_write_enable = last_dmem_write_enable;
            mmio_write_data = dmem_write_data_internal;
            mmio_byteen = dmem_byteen_internal;
        end

        //
        // OUTPUT SIDE
        //
        case (last_dmem_address[31:16])
            16'h0000: dmem_read_data_internal = rom_q;
            16'h7000: dmem_read_data_internal = mmio_q;
            16'h8000: dmem_read_data_internal = ram_q;
            default: dmem_read_data_internal = 0;
        endcase

        // Select the correct bytes from the output
        dmem_read_data = dmem_read_data_internal;
    end
end

always @(posedge clk) begin
    if (!reset_n) begin
        memory_state <= NORMAL;
        last_dmem_address <= 0;
        last_dmem_read_mode <= 0;
        last_dmem_read_data <= 0;
        last_dmem_write_mode <= 0;
        last_dmem_write_data <= 0;
        last_dmem_enable <= 0;
        last_dmem_write_enable <= 0;
    end else begin
        memory_state <= next_memory_state;
        if (memory_state == NORMAL) begin
            last_dmem_read_mode <= dmem_read_mode;
        end else begin
            last_dmem_read_mode <= last_dmem_read_mode;
        end
        last_dmem_address <= selected_dmem_address;
        last_dmem_read_data <= dmem_read_data;
        last_dmem_write_mode <= dmem_write_mode;
        last_dmem_write_data <= dmem_write_data;
        last_dmem_enable <= dmem_enable;
        last_dmem_write_enable <= dmem_write_enable;
     end
end

endmodule
