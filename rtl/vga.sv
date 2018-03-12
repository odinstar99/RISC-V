module vga (
    input vga_clk,
    input reset_n,

    input [11:0] bg_color,

    output [3:0] vga_r,
    output [3:0] vga_g,
    output [3:0] vga_b,
    output vga_hs,
    output vga_vs
);

logic [15:0] vga_hs_counter;
logic [15:0] next_vga_hs_counter;
logic [15:0] vga_vs_counter;
logic [15:0] next_vga_vs_counter;

logic [15:0] pixel_x;
logic [15:0] next_pixel_x;
logic [15:0] pixel_y;
logic [15:0] next_pixel_y;

//                             horizontal      vertical
// format          pixelf | act fro syn bac | act fro syn bac
// 640x480, 60Hz   25.175 | 640 16  96  48  | 480 11  2   31 --
// 800x600, 72Hz   50.000 | 800 56  120 64  | 600 37  6   23 ++
// 1920x1080x60    148.50 | 1920 88 44  148 | 1080 4  5   36 ++

// 640x480
// localparam H_ACTIVE = 640;
// localparam H_FRONT = 16;
// localparam H_SYNC = 96;
// localparam H_BACK = 48;
// localparam H_TOTAL = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;
// localparam H_POL = 1'b0;
// localparam V_ACTIVE = 480;
// localparam V_FRONT = 11;
// localparam V_SYNC = 2;
// localparam V_BACK = 31;
// localparam V_TOTAL = V_ACTIVE + V_FRONT + V_SYNC + V_BACK;
// localparam V_POL = 1'b0;

// 800x600
// localparam H_ACTIVE = 800;
// localparam H_FRONT = 56;
// localparam H_SYNC = 120;
// localparam H_BACK = 64;
// localparam H_TOTAL = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;
// localparam H_POL = 1'b1;
// localparam V_ACTIVE = 600;
// localparam V_FRONT = 37;
// localparam V_SYNC = 6;
// localparam V_BACK = 23;
// localparam V_TOTAL = V_ACTIVE + V_FRONT + V_SYNC + V_BACK;
// localparam V_POL = 1'b1;

// 1024x768
// localparam H_ACTIVE = 1024;
// localparam H_FRONT = 24;
// localparam H_SYNC = 136;
// localparam H_BACK = 160;
// localparam H_TOTAL = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;
// localparam H_POL = 1'b0;
// localparam V_ACTIVE = 768;
// localparam V_FRONT = 3;
// localparam V_SYNC = 6;
// localparam V_BACK = 29;
// localparam V_TOTAL = V_ACTIVE + V_FRONT + V_SYNC + V_BACK;
// localparam V_POL = 1'b0;

// 1920x1080
// localparam H_ACTIVE = 1920;
// localparam H_FRONT = 88;
// localparam H_SYNC = 44;
// localparam H_BACK = 148;
// localparam H_TOTAL = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;
// localparam H_POL = 1'b1;
// localparam V_ACTIVE = 1080;
// localparam V_FRONT = 4;
// localparam V_SYNC = 5;
// localparam V_BACK = 36;
// localparam V_TOTAL = V_ACTIVE + V_FRONT + V_SYNC + V_BACK;
// localparam V_POL = 1'b1;

// 1280x720x60 (aka 720p)   74.25   13.47   1280    72  80  216 1648    +   720 3   5   22  750 +
localparam H_ACTIVE = 1280;
localparam H_FRONT = 72;
localparam H_SYNC = 80;
localparam H_BACK = 216;
localparam H_TOTAL = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;
localparam H_POL = 1'b1;
localparam V_ACTIVE = 720;
localparam V_FRONT = 3;
localparam V_SYNC = 5;
localparam V_BACK = 22;
localparam V_TOTAL = V_ACTIVE + V_FRONT + V_SYNC + V_BACK;
localparam V_POL = 1'b1;

always_comb begin
    logic hvalid;
    logic vvalid;

    next_vga_vs_counter = vga_vs_counter;
    next_vga_hs_counter = vga_hs_counter + 1;
    if (next_vga_hs_counter == H_TOTAL) begin
        next_vga_hs_counter = 0;
        next_vga_vs_counter = vga_vs_counter + 1;
    end
    if (next_vga_vs_counter == V_TOTAL) begin
        next_vga_vs_counter = 0;
    end

    vga_r = 0;
    vga_g = 0;
    vga_b = 0;

    vga_hs = (vga_hs_counter < H_SYNC) ? H_POL : ~H_POL;
    vga_vs = (vga_vs_counter < V_SYNC) ? V_POL : ~V_POL;

    hvalid = (vga_hs_counter >= (H_BACK + H_SYNC) && vga_hs_counter < (H_TOTAL - H_FRONT));
    vvalid = (vga_vs_counter >= (V_BACK + V_SYNC) && vga_vs_counter < (V_TOTAL - V_FRONT));

    if (hvalid && vvalid) begin
        vga_r = bg_color[3:0];
        vga_g = bg_color[7:4];
        vga_b = bg_color[11:8];
    end

    next_pixel_x = hvalid ? pixel_x + 1 : 0;
    next_pixel_y = vvalid ? (next_vga_hs_counter == 0 ? pixel_y + 1 : pixel_y) : 0;
end

always_ff @(posedge vga_clk) begin
    if (!reset_n) begin
        vga_hs_counter <= 0;
        vga_vs_counter <= 0;
        pixel_x <= 0;
        pixel_y <= 0;
    end else begin
        vga_hs_counter <= next_vga_hs_counter;
        vga_vs_counter <= next_vga_vs_counter;
        pixel_x <= next_pixel_x;
        pixel_y <= next_pixel_y;
    end
end

endmodule
