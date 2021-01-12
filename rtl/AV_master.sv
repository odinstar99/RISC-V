module AV_master(

	input logic clk,
	input logic clrn,
	
	/* data memory bus */
	input  logic [31:0] data_address_in,
	input logic data_read_in,
	input logic data_write_in,
	input logic [127:0] data_write_value_in,	
	output logic data_wait_out,
	output logic data_write_ready_n_out,
	output logic [127:0] data_read_value_out,	
	input logic [2:0] burstcount_in,
	
	//Avalon master//
	output logic [31:0] av_address,
	output logic av_read,
	output logic av_write,
	input  logic av_waitrequest,
	input  logic [31:0] av_reddata,
	output logic [31:0] av_writedata,
	output logic [2:0] av_burstcount,
	output logic av_beginbursttransfer, 
	input  logic av_readdatavalid
	
	//---------------//
);


	logic data_wait;
//Avalon master//
	logic [31:0] address;
	logic read;
	logic write;
	logic [31:0] writedata [3:0];
	logic [31:0] readdata  [3:0];
	logic [2:0] burstcount;
	logic beginbursttransfer; 
	
	enum logic [2:0] {IDLE, WRITE_START, WRITE, READ_START, READ} av_master_state, av_master_current_state; /*Idle - 0, write - 1, read - 2, waitreq - 3*/
//-----------------//	
	
	assign av_address		= address;
	assign av_read			= read;
	assign av_write		= write;
	assign writedata[3]	= data_write_value_in[127:96];
	assign writedata[2]	= data_write_value_in[95:64];
	assign writedata[1]	= data_write_value_in[63:32];
	assign writedata[0]	= data_write_value_in[31:0];
	assign data_read_value_out[127:96] 	= readdata[3];
	assign data_read_value_out[95:64] 	= readdata[2];
	assign data_read_value_out[63:32] 	= readdata[1];
	assign data_read_value_out[31:0] 	= readdata[0];
	assign data_wait_out = data_wait;
	assign av_beginbursttransfer = beginbursttransfer;
	
	always_comb
	begin
		case (av_master_current_state)
		IDLE:
			if (data_write_in ) av_master_state = WRITE_START;
			else if (data_read_in) av_master_state = READ_START;
			else av_master_state = IDLE;
		WRITE_START:
			av_master_state = WRITE;
		WRITE:
			if (burstcount != av_burstcount) av_master_state = WRITE;
			else av_master_state = IDLE;
		READ_START:
			av_master_state = READ;
		READ:
			if (burstcount != av_burstcount) av_master_state = READ;
			else av_master_state = IDLE;
		default:
			av_master_state = IDLE;
		endcase
	end
	
	//Avalon master //
	always_ff @(posedge clk)
	begin
		if (!clrn)
		begin
			address 						<= 0;
			read 							<= 0;
			write 						<= 0;
			data_wait 					<= 0;
			data_write_ready_n_out	<= 0;
			readdata[3]					<= 0;
			readdata[2]					<= 0;
			readdata[1]					<= 0;
			readdata[0]					<= 0;
			av_writedata				<= 0;
			beginbursttransfer		<= 0;
			av_burstcount				<= 0;
			burstcount					<= 0;
			av_master_current_state <= IDLE;
		end
		else
		begin
			av_master_current_state <= av_master_state;
			case (av_master_state)
			IDLE:
			begin
				burstcount <= 1;
				address <= 0;
				read <= 0;
				write <= 0;
				data_wait <= 0;
				data_write_ready_n_out	<= 0;
				beginbursttransfer <= 0; 
			end
			WRITE_START:
			begin
				burstcount <= 0;
				av_burstcount <= burstcount_in;
				address <= data_address_in;
				write <= 1;
				av_writedata <= writedata[burstcount];
				beginbursttransfer <= 1;
				data_write_ready_n_out	<= 1; 
			end
			WRITE:
			begin
				beginbursttransfer <= 0;
				av_writedata <= writedata[burstcount];
				burstcount <= av_waitrequest ? burstcount : burstcount + 1'h1; 
			end
			READ_START:
			begin
				burstcount <= 0;
				av_burstcount <= burstcount_in;
				address <= data_address_in;
				read <= 1;
				beginbursttransfer <= 1;
				data_wait <= 1; 
			end
			READ:
			begin
				read <= read ? (av_waitrequest ? 1'h1 : 1'h0) : 1'h0;
				beginbursttransfer <= 0;
				if (av_readdatavalid)
				begin
					readdata[burstcount] <= av_reddata;
					burstcount <= burstcount + 1'h1; 
				end
			end
			endcase
		end
	end
	
	//----------------------------------------------------//

endmodule
