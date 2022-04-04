module AV_master(

	input logic clk,
	input logic clrn,
	
	/* data memory bus */
	input  logic [31:0] data_address_in,
	input logic data_read_in,
	input logic data_write_in,
	input logic [31:0] data_write_value_in,	
	output logic read_data_valid_out,
	output logic read_data_wait_out,
	output logic data_write_wait_out,
	output logic waitrequest,
	output logic [31:0] data_read_value_out,	
	input logic [4:0] burstcount_in,
	//input logic [3:0] byteenable, 
	
	//Avalon master//
	output logic [31:0] av_address,
	output logic av_read,
	output logic av_write,
	input  logic av_waitrequest,
	input  logic [31:0] av_reddata,
	output logic [31:0] av_writedata,
	output logic [4:0] av_burstcount,
	output logic av_beginbursttransfer, 
	input  logic av_readdatavalid//,
	//output logic [3:0] av_byteenable
	
	//---------------//
);


//Avalon master//
	logic [31:0] address;
	logic read;
	logic write;
	logic [4:0] burstcount;
	logic beginbursttransfer; 
	
	enum logic [2:0] {IDLE, WRITE_START, WRITE, READ_START, READ} av_master_state, av_master_current_state; /*Idle - 0, write - 1, read - 2, waitreq - 3*/
//-----------------//	
	
	assign av_address		= address;
	assign av_read			= read;
	assign av_write			= write;
	assign av_beginbursttransfer = beginbursttransfer;
	assign waitrequest = av_waitrequest;
	//assign av_byteenable = byteenable;
	
	always_comb
	begin
		case (av_master_current_state)
		IDLE:
		begin
			if (data_write_in) 
			begin 
				av_master_state = WRITE_START;
				data_write_wait_out = 1;
			end
			else if (data_read_in) 
			begin
				av_master_state = READ_START;
				data_write_wait_out = 0;
			end
			else 
			begin
				av_master_state = IDLE;
				data_write_wait_out = 0;
			end
		end
		WRITE_START:
		begin
			av_master_state = WRITE;
			data_write_wait_out = 1;
		end
		WRITE:
		begin
			if (burstcount != av_burstcount) av_master_state = WRITE;
			else if (data_write_in ) av_master_state = WRITE_START;
			else if (data_read_in) av_master_state = READ_START;
			else av_master_state = IDLE;
			data_write_wait_out = 1;
		end
		READ_START:
		begin
			av_master_state = READ;
			data_write_wait_out = 0;
		end
		READ:
		begin
			if (burstcount != av_burstcount) av_master_state = READ;
			else if (data_write_in ) av_master_state = WRITE_START;
			else if (data_read_in) av_master_state = READ_START;
			else av_master_state = IDLE;
			data_write_wait_out = 0;
		end
		default:
		begin
			av_master_state = IDLE;
			data_write_wait_out = 0;
		end
		endcase
	end
	
	//Avalon master //
	always_ff @(posedge clk)
	begin
		if (!clrn)
		begin
			address 					<= 0;
			read 						<= 0;
			write 						<= 0;
			read_data_valid_out 		<= 0;
			read_data_wait_out			<= 0;
			data_read_value_out			<= 0;
			av_writedata				<= 0;
			beginbursttransfer			<= 0;
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
				read_data_valid_out <= 0;
				read_data_wait_out <= 0;
				beginbursttransfer <= 0; 
			end
			WRITE_START:
			begin
				burstcount <= 0;
				av_burstcount <= burstcount_in;
				address <= data_address_in;
				write <= 1;
				read <= 0;
				av_writedata <= data_write_value_in;
				beginbursttransfer <= 1;
			end
			WRITE:
			begin
				beginbursttransfer <= 0;
				av_writedata <= data_write_value_in;
				if (!av_waitrequest)
				begin
					burstcount <= burstcount + 1'h1;
				end
				if (burstcount == av_burstcount - 1)
					write <= 0;
			end
			READ_START:
			begin
				burstcount <= 0;
				av_burstcount <= burstcount_in;
				address <= data_address_in;
				read <= 1;
				write <= 0;
				beginbursttransfer <= 1;
				read_data_wait_out <= 1;
			end
			READ:
			begin
				read <= read ? (av_waitrequest ? 1'h1 : 1'h0) : 1'h0;
				beginbursttransfer <= 0;
				if (av_readdatavalid)
				begin
					data_read_value_out <= av_reddata;
					burstcount <= burstcount + 1'h1;
					read_data_valid_out <= 1; 
					read_data_wait_out <= 0;
				end
				else
				begin
					read_data_wait_out <= 1;
					read_data_valid_out <= 0; 
				end
			end
			endcase
		end
	end
	
	//----------------------------------------------------//

endmodule
