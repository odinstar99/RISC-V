

module DM_cache_logic_m
#(parameter I_BURST=5'd16, I_CACHE_LENGTH=I_BURST*32)
(
    // clock and reset
	input   logic   clk,        // clock input
	input   logic   resetn,     // reset input
    // GPIO side

	input  logic [31:0] address,
	input  logic read,
	output logic wait_data,
	output logic [31:0] reddata,
	 
	 	//Avalon master//
	output logic [31:0] av_address,
	output logic av_read,
	output logic av_write,
	input  logic av_read_data_valid,
	input  logic [I_CACHE_LENGTH - 1:0] av_reddata,
	output logic [I_CACHE_LENGTH - 1:0] av_writedata,
	input  logic write_ready_n,
	output logic [4:0] av_burstcount 
	//---------------//
);

logic [63:0] overwrite_counter;

logic [4:0]  burstcount;
logic [3:0]  offset;
logic [6:0]  index;
logic [18:0] tag; 
logic [3:0]  old_offset;
logic [6:0]  old_index;
logic [18:0] old_tag;
logic [31:0] old_address;  
logic [I_CACHE_LENGTH - 1:0] cache_reddata;
logic [I_CACHE_LENGTH - 1:0] cache_wrdata;
logic cache_write;

logic [31:0] mem_tag_valid;
logic [31:0] new_tag_valid;
logic [6:0]  ca_index;
logic c_miss_start;
logic c_miss_wait; 

enum logic [2:0] {CACHE_HIT, CACHE_MISS, CACHE_WRITE, CACHE_WAIT} state, new_state;

assign offset	= address[5:2];
assign index	= address[12:6];
assign tag		= address[31:13]; 
assign old_offset	= old_address[5:2];
assign old_index	= old_address[12:6];
assign old_tag		= old_address[31:13];  
assign av_write 	= 0;
assign av_writedata = 0;
assign av_address = {old_address[31:6], 6'd0};
assign av_burstcount = I_BURST;
assign new_tag_valid = {12'b0, 1'b1, old_tag};

tags_valids tags
(
	.address(ca_index),
	.clock(clk),
	.data(new_tag_valid),
	.wren(cache_write),
	.q(mem_tag_valid)
);

i_DM_cache i_cache   
(
	.address(ca_index),
	.clock(clk),
	.data(cache_wrdata),
	.wren(cache_write),
	.q(cache_reddata)
);

always_comb
begin
	ca_index = (c_miss_wait || !(read || wait_data)) ? old_index : index;
	reddata = 'bx;
	case (state)
	CACHE_HIT:
	begin
		if (!(read || wait_data) || (mem_tag_valid[19] && mem_tag_valid[18:0] == old_tag)) 
		begin
			wait_data = 0;
			new_state = CACHE_HIT;
		end
		else 
		begin
			wait_data = resetn ? 1 : 0;
			new_state = CACHE_MISS;
		end
		
		if(read)
		begin
			case (old_offset)
			4'd0:  reddata = cache_reddata[31:0];
			4'd1:  reddata = cache_reddata[63:32];
			4'd2:  reddata = cache_reddata[95:64];
			4'd3:  reddata = cache_reddata[127:96];
			4'd4:  reddata = cache_reddata[159:128];
			4'd5:  reddata = cache_reddata[191:160];
			4'd6:  reddata = cache_reddata[223:192];
			4'd7:  reddata = cache_reddata[255:224];
			4'd8:  reddata = cache_reddata[287:256];
			4'd9:  reddata = cache_reddata[319:288];
			4'd10: reddata = cache_reddata[351:320];
			4'd11: reddata = cache_reddata[383:352];
			4'd12: reddata = cache_reddata[415:384];
			4'd13: reddata = cache_reddata[447:416];
			4'd14: reddata = cache_reddata[479:448];
			4'd15: reddata = cache_reddata[511:480];
			default: reddata = 'bx;
			endcase
		 end
		else
			reddata = 'bx;
			
	end
	CACHE_MISS:
	begin
		wait_data = resetn ? 1 : 0;
		if (c_miss_start) new_state = CACHE_MISS;
		else new_state = CACHE_WRITE;
	end
	CACHE_WRITE:
	begin
		wait_data = resetn ? 1 : 0;
		new_state = CACHE_HIT;
	end
	default:
	begin
		wait_data = 0;
		new_state = CACHE_HIT;
	end
	endcase
end

always_ff @(posedge clk)
begin
	if (!resetn)
	begin
		state				<= CACHE_HIT;
		av_read 			<= 0;
		cache_wrdata	<= 0;
		c_miss_start	<= 0;
		c_miss_wait		<= 0;
		cache_write 	<= 0;
		overwrite_counter <= 0;
		burstcount		<= 0;
		old_address		<= address;
	end
	else
	begin
		state <= new_state;
		if(!wait_data && read)
		begin
			old_address <= address;
		end
		case (new_state)
		CACHE_HIT:
		begin
			c_miss_wait <= 0;
			burstcount	<= 0;
		end
		CACHE_MISS:
		begin
			c_miss_wait <= 1;
			if (!c_miss_start)
			begin
				av_read 		<= 1;
				c_miss_start <= 1;
			end
			else
			if (burstcount != I_BURST)
			begin
				av_read <= 0;
				if (av_read_data_valid)
				begin
					case (burstcount)
						4'd0:  cache_wrdata[31:0]		<= av_reddata;
						4'd1:  cache_wrdata[63:32]		<= av_reddata;
						4'd2:  cache_wrdata[95:64]		<= av_reddata;
						4'd3:  cache_wrdata[127:96]		<= av_reddata;
						4'd4:  cache_wrdata[159:128]	<= av_reddata;
						4'd5:  cache_wrdata[191:160]	<= av_reddata;
						4'd6:  cache_wrdata[223:192]	<= av_reddata;
						4'd7:  cache_wrdata[255:224]	<= av_reddata;
						4'd8:  cache_wrdata[287:256]	<= av_reddata;
						4'd9:  cache_wrdata[319:288]	<= av_reddata;
						4'd10: cache_wrdata[351:320]	<= av_reddata;
						4'd11: cache_wrdata[383:352]	<= av_reddata;
						4'd12: cache_wrdata[415:384]	<= av_reddata;
						4'd13: cache_wrdata[447:416]	<= av_reddata;
						4'd14: cache_wrdata[479:448]	<= av_reddata;
						4'd15: cache_wrdata[511:480]	<= av_reddata; 
						default: cache_wrdata <= 'bx;
					endcase
					burstcount <= burstcount + 1;
				end
			end
			else
			begin
				cache_write <= 1;
				c_miss_start <= 0;
				if(mem_tag_valid[19])
					overwrite_counter = overwrite_counter + 1;
			end
		end
		CACHE_WRITE:
			cache_write <= 0;
		endcase
	end
end

endmodule

