/*
*  File            :   nf_top_ahb.sv
*  Autor           :   Vlasov D.V.
*  Data            :   2018.11.27
*  Language        :   SystemVerilog
*  Description     :   This is top unit
*  Copyright(c)    :   2018 - 2019 Vlasov D.V.
*/

module rv32im_top
(
    // clock and reset
    input   logic   [0  : 0]    clk,        // clock input
    input   logic   [0  : 0]    resetn,     // reset input
	 output logic [63:0] cycle_count,
	 output	 logic test_done,
    // GPIO side
	 
	 	//Avalon master//
	output logic [31:0] data_address,
	//output logic [3:0]byteenable,
	output logic data_read,
	output logic data_write,
	input  logic data_waitrequest,
	input  logic [31:0] data_reddata,
	output logic [31:0] data_writedata,
	output logic [2:0] data_burstcount,
	output logic data_beginbursttransfer, 
	input  logic data_readdatavalid,
	
		 	//Avalon master//
	output logic [31:0] inst_address,
	//output logic [3:0]byteenable,
	output logic inst_read,
	output logic inst_write,
	input  logic inst_waitrequest,
	input  logic [31:0] inst_reddata,
	output logic [31:0] inst_writedata,
	output logic [2:0] inst_burstcount,
	output logic inst_beginbursttransfer, 
	input  logic inst_readdatavalid
	
	//---------------//

);

    // instruction memory (IF)
    logic   [31 : 0]    addr_i;         // address instruction memory
    logic   [31 : 0]    rd_i;           // read instruction memory
    logic   [31 : 0]    wd_i;           // write instruction memory
    logic   [0  : 0]    we_i;           // write enable instruction memory signal
    logic   [1  : 0]    size_i;         // size for load/store instructions
    logic   [0  : 0]    req_i;          // request instruction memory signal
    logic   [0  : 0]    req_ack_i;      // request acknowledge instruction memory signal
    // data memory and other's
    logic   [31 : 0]    addr_dm;        // address data memory
    logic   [31 : 0]    rd_dm;          // read data memory
    logic   [31 : 0]    wd_dm;          // write data memory
    logic   [0  : 0]    we_dm;          // write enable data memory signal
    logic   [1  : 0]    size_dm;        // size for load/store instructions
    logic   [0  : 0]    req_dm;         // request data memory signal
    logic   [0  : 0]    req_ack_dm;     // request acknowledge data memory signal
    // cross connect data
    logic   [31 : 0]    addr_cc;        // address cc_data memory
    logic   [31 : 0]    rd_cc;          // read cc_data memory
    logic   [31 : 0]    wd_cc;          // write cc_data memory
    logic   [0  : 0]    we_cc;          // write enable cc_data memory signal
    logic   [1  : 0]    size_cc;        // size for load/store instructions
    logic   [0  : 0]    req_cc;         // request cc_data memory signal
    logic   [0  : 0]    req_ack_cc;     // request acknowledge cc_data memory signal
    // RAM side
    logic   [31 : 0]    ram_addr;       // addr memory
    logic   [3  : 0]    ram_we;         // write enable
    logic   [31 : 0]    ram_wd;         // write data
    logic   [31 : 0]    ram_rd;         // read data
	 
	 logic data_write_ready_n;
	 int print_t;

	 logic [31:0] av_address_i;
	 logic av_read_i;
	 logic av_write_i;
	 logic av_wait_data_i;
	 logic [127:0] av_reddata_i;
	 logic [127:0] av_writedata_i;
	 logic [127:0] av_reddata_d;
	 logic [127:0] av_writedata_d;
	 logic write_ready_n_i;
	 logic [2:0] burstcount_i;
	 
	 assign rd_dm = av_reddata_d [31:0];
	 assign av_writedata_d = {96'h0, wd_dm};
	 assign test_done = (wd_dm == 'h12345678) ? 1 : 0;
DM_cache_logic_m i_cache_controller
(
	.clk(clk),    
	.resetn(resetn), 
	.address(addr_i),
	.read(req_i),
	.wait_data(req_ack_i),
	.reddata(rd_i),
	.av_address(av_address_i),
	.av_read(av_read_i),
	.av_write(av_write_i),
	.av_wait_data(av_wait_data_i),
	.av_reddata(av_reddata_i),
	.av_writedata(av_writedata_i),
	.write_ready_n(write_ready_n_i),
	.av_burstcount(burstcount_i) 
);	 

 AV_master instr_av_master(
		.clk ( clk ),
		.clrn ( resetn ),
		.data_address_in ( av_address_i ),
		.data_read_in ( av_read_i ),
		.data_write_in ( av_write_i ),
		
		.data_write_value_in ( av_writedata_i ),
		
		.data_wait_out ( av_wait_data_i ),
		.data_write_ready_n_out ( write_ready_n_i ),
		.data_read_value_out ( av_reddata_i ),
		.burstcount_in(burstcount_i),
		//Avalon master//
		.av_address (inst_address),
		//.av_byteenable (byteenable),
		.av_read (inst_read),
		.av_write (inst_write),
		.av_waitrequest (inst_waitrequest),
		.av_reddata (inst_reddata),
		.av_writedata (inst_writedata),
		.av_burstcount (inst_burstcount),
		.av_beginbursttransfer (inst_beginbursttransfer), 
		.av_readdatavalid (inst_readdatavalid)
	
	//---------------//
	);

AV_master data_av_master(
		.clk ( clk ),
		.clrn ( resetn ),
		.data_address_in ( addr_dm ),
		.data_read_in ( req_dm ),
		.data_write_in ( we_dm ),
		
		.data_write_value_in ( av_writedata_d ),
		
		.data_wait_out ( req_ack_dm ),
		.data_write_ready_n_out ( data_write_ready_n ),
		.data_read_value_out ( av_reddata_d ),
		.burstcount_in(3'h1),
		//Avalon master//
		.av_address (data_address),
		//.av_byteenable (byteenable),
		.av_read (data_read),
		.av_write (data_write),
		.av_waitrequest (data_waitrequest),
		.av_reddata (data_reddata),
		.av_writedata (data_writedata),
		.av_burstcount (data_burstcount),
		.av_beginbursttransfer (data_beginbursttransfer), 
		.av_readdatavalid (data_readdatavalid)
	
	//---------------//
	);
     
    // Creating one nf_cpu_0
    core rv32im_cpu_0
    (
        // clock and reset
        .clk            ( clk           ),      // clk  
        .reset_n         ( resetn        ),      // resetn
        // instruction memory (IF)
        .imem_address         ( addr_i        ),      // address instruction memory
        .imem_data           ( rd_i          ),      // read instruction memory
        .imem_enable          ( req_i         ),      // request instruction memory signal
        .imem_wait      ( req_ack_i     ),      // request acknowledge instruction memory signal
        // data memory and other's
        .dmem_address        ( addr_dm       ),      // address data memory
        .dmem_read_data          ( rd_dm         ),      // read data memory
        .dmem_write_data          ( wd_dm         ),      // write data memory
        .dmem_write_enable          ( we_dm         ),      // write enable data memory signal
        .dmem_write_mode        ( size_dm       ),      // size for load/store instructions
        .dmem_read_enable         ( req_dm        ),      // request data memory signal
        .dmem_wait     ( req_ack_dm    ) ,      // request acknowledge data memory signal
		  .cycle_count		(cycle_count)
    );
	 
	 
	always_ff @(posedge clk)
	begin
		if (!resetn)
			print_t <= 0;
		else if (addr_dm == 'h2000 && we_dm)
			print_t <= wd_dm;
	end
    
	
endmodule : rv32im_top
