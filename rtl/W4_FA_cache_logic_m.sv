

module W4_FA_cache_logic_m
#(parameter I_BURST=3'h4, I_CACHE_LENGTH=I_BURST*32)
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
	input  logic av_wait_data,
	input  logic [I_CACHE_LENGTH - 1:0] av_reddata,
	output logic [I_CACHE_LENGTH - 1:0] av_writedata,
	input  logic write_ready_n,
	output logic [2:0] av_burstcount 
	//---------------//

);

logic [1:0]  offset;
logic [3:0]  index;
logic [23:0] tag; 
logic [1:0]  old_offset;
logic [3:0]  old_index;
logic [23:0] old_tag;
logic [31:0] old_address;  
logic [I_CACHE_LENGTH - 1:0] cache_reddata;
logic [I_CACHE_LENGTH - 1:0] cache_wrdata;
logic cache_write [3:0];

logic [1:0] tag_count;
logic [1:0] cache_hit;

logic [31:0] mem_tag_valid [3:0];
logic [31:0] new_tag_valid;
logic transmission; 
logic c_miss_start;
logic c_miss_wait; 

enum logic [2:0] {CACHE_HIT, CACHE_MISS, CACHE_WRITE, CACHE_WAIT} state, new_state;

assign offset	= address[3:2];
assign index	= address[7:4];
assign tag		= address[31:8]; 
assign old_offset	= old_address[3:2];
assign old_index	= old_address[7:4];
assign old_tag		= old_address[31:8];  
assign av_write 	= 0;
assign av_writedata = 0;
assign av_address = old_address;
assign av_burstcount = I_BURST;
assign new_tag_valid = {5'b00000, tag_count, 1'b1, old_tag};

tags_memory tags_1
(
	.address_a({1'b0,index}),
	.address_b({1'b1,index}),
	.clock(clk),
	.data_a(new_tag_valid),
	.data_b(new_tag_valid),
	.wren_a(cache_write[0]),
	.wren_b(cache_write[1]),
	.q_a(mem_tag_valid[0]),
	.q_b(mem_tag_valid[1])
);
tags_memory tags_2
(
	.address_a({1'b0,index}),
	.address_b({1'b1,index}),
	.clock(clk),
	.data_a(new_tag_valid),
	.data_b(new_tag_valid),
	.wren_a(cache_write[2]),
	.wren_b(cache_write[3]),
	.q_a(mem_tag_valid[2]),
	.q_b(mem_tag_valid[3])
);

i_DM_cache i_cache   
(
	.address({old_index, tag_count}),
	.clock(clk),
	.data(cache_wrdata),
	.wren(cache_write[0] |
			cache_write[1] |
			cache_write[2] |
			cache_write[3]),
	.q(cache_reddata)
);

always_comb
begin
	transmission = (av_read || av_wait_data);
	cache_hit = 2'h0;
	case (state)
	CACHE_HIT:
	begin
		if (!read && !wait_data) 
		begin
			wait_data = 0;
			new_state = CACHE_WAIT;
		end
		else if (mem_tag_valid[0][22] && mem_tag_valid[0][21:0] == old_tag) 
		begin
			cache_hit = 0;
			wait_data = 0;
			new_state = CACHE_HIT;
		end
		else if (mem_tag_valid[1][22] && mem_tag_valid[1][21:0] == old_tag) 
		begin
			cache_hit = 1;
			wait_data = 0;
			new_state = CACHE_HIT;
		end
		else if (mem_tag_valid[2][22] && mem_tag_valid[2][21:0] == old_tag) 
		begin
			cache_hit = 2;
			wait_data = 0;
			new_state = CACHE_HIT;
		end
		else if (mem_tag_valid[3][22] && mem_tag_valid[3][21:0] == old_tag) 
		begin
			cache_hit = 3;
			wait_data = 0;
			new_state = CACHE_HIT;
		end
		else 
		begin
			wait_data = resetn ? 1 : 0;
			tag_count = mem_tag_valid[0];
			new_state = CACHE_MISS;
		end
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
		reddata 			<= 0;
		av_read 			<= 0;
		cache_wrdata	<= 0;
		c_miss_start	<= 0;
		c_miss_wait		<= 0;
		//cache_write 	<= 0;
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
			if (c_miss_wait)
			begin
				case (old_offset)
				2'b00: reddata <= cache_reddata[31:0];
				2'b01: reddata <= cache_reddata[63:32];
				2'b10: reddata <= cache_reddata[95:64];
				2'b11: reddata <= cache_reddata[127:96];
				endcase
				c_miss_wait <= 0;
			end
			else if(read)
				case (offset)
				2'b00: reddata <= cache_reddata[31:0];
				2'b01: reddata <= cache_reddata[63:32];
				2'b10: reddata <= cache_reddata[95:64];
				2'b11: reddata <= cache_reddata[127:96];
				endcase
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
			if (!transmission)
			begin
				cache_wrdata <= av_reddata;
				cache_write[0] <= 1;
				c_miss_start <= 0;
			end
			else
			begin
				av_read <= 0;
			end
		end
		CACHE_WRITE:
			cache_write[0] <= 0;
		endcase
	end
end

endmodule

