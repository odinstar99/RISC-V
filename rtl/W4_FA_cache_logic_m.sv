

module W4_FA_cache_logic_m
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
	input  logic av_wait_data,
	input  logic [I_CACHE_LENGTH - 1:0] av_reddata,
	output logic [I_CACHE_LENGTH - 1:0] av_writedata,
	input  logic write_ready_n,
	output logic [4:0] av_burstcount 
	//---------------//

);

logic [63:0] overwrite_counter;

logic [3:0]  offset;
logic [4:0]  index;
logic [20:0] tag; 
logic [3:0]  old_offset;
logic [4:0]  old_index;
logic [20:0] old_tag;
logic [31:0] old_address;  
logic [I_CACHE_LENGTH - 1:0] cache_reddata [3:0];
logic [I_CACHE_LENGTH - 1:0] cache_wrdata;
logic cache_tag_write [3:0];
logic cache_write[3:0];

logic [1:0] tag_count;
logic [1:0] cache_hit;
logic [1:0] cache_hit_reg;

logic [4:0] cache_address;

logic [31:0] mem_tag_valid [3:0];
logic [31:0] new_tag_valid;
logic transmission; 
logic c_miss_start;
logic c_miss_wait; 

logic [2:0] u_data [32:0];
logic [2:0] u_data_write;

enum logic [2:0] {CACHE_HIT, CACHE_MISS, CACHE_WRITE, CACHE_WAIT} state, new_state;

assign offset	= address[5:2];
assign index	= address[10:6];
assign tag		= address[31:11]; 
assign old_offset	= old_address[5:2];
assign old_index	= old_address[10:6];
assign old_tag		= old_address[31:11];  
assign av_write 	= 0;
assign av_writedata = 0;
assign av_address = {old_address[31:6], 6'd0};
assign av_burstcount = I_BURST;

tags_memory tags_1
(
	.address_a({1'b0,cache_address}),
	.address_b({1'b1,cache_address}),
	.clock(clk),
	.data_a(new_tag_valid),
	.data_b(new_tag_valid),
	.wren_a(cache_tag_write[0]),
	.wren_b(cache_tag_write[1]),
	.q_a(mem_tag_valid[0]),
	.q_b(mem_tag_valid[1])
);
tags_memory tags_2
(
	.address_a({1'b0,cache_address}),
	.address_b({1'b1,cache_address}),
	.clock(clk),
	.data_a(new_tag_valid),
	.data_b(new_tag_valid),
	.wren_a(cache_tag_write[2]),
	.wren_b(cache_tag_write[3]),
	.q_a(mem_tag_valid[2]),
	.q_b(mem_tag_valid[3])
);

i_4WA_cache i_cache_1   
(
	.address_a({1'b0,cache_address}),
	.address_b({1'b1,cache_address}),
	.clock(clk),
	.data_a(cache_wrdata),
	.data_b(cache_wrdata),
	.wren_a(cache_write[0]),
	.wren_b(cache_write[1]),
	.q_a(cache_reddata[0]),
	.q_b(cache_reddata[1])
);

i_4WA_cache i_cache_2   
(
	.address_a({1'b0,cache_address}),
	.address_b({1'b1,cache_address}),
	.clock(clk),
	.data_a(cache_wrdata),
	.data_b(cache_wrdata),
	.wren_a(cache_write[2]),
	.wren_b(cache_write[3]),
	.q_a(cache_reddata[2]),
	.q_b(cache_reddata[3])
);

always_comb
begin
	new_tag_valid = {10'b0000000, 1'b1, old_tag};
	cache_address = (c_miss_wait || !(read || wait_data)) ? old_index : index;
end

always_comb
begin
	transmission = (av_read || av_wait_data);
	//tag_count = mem_tag_valid[0][23:22];
	cache_hit = cache_hit_reg;
	u_data_write = 3'd0;
	reddata = 'bx;
	case (state)
	CACHE_HIT:
	begin
		if (!(read || wait_data)) 
		begin
			wait_data = 0;
			new_state = CACHE_HIT;
		end
		else if (mem_tag_valid[0][21] && mem_tag_valid[0][20:0] == old_tag) 
		begin
			cache_hit = 0;
			wait_data = 0;//(index != old_index) ? 1 : 0;
			new_state = CACHE_HIT;
			u_data_write = {1'b1, u_data[index][1] ,1'b1};
		end
		else if (mem_tag_valid[1][21] && mem_tag_valid[1][20:0] == old_tag) 
		begin
			cache_hit = 1;
			wait_data = 0;//(index != old_index) ? 1 : 0;
			new_state = CACHE_HIT;
			u_data_write = {1'b1, u_data[index][1] ,1'b0};
		end
		else if (mem_tag_valid[2][21] && mem_tag_valid[2][20:0] == old_tag) 
		begin
			cache_hit = 2;
			wait_data = 0;//(index != old_index) ? 1 : 0;
			new_state = CACHE_HIT;
			u_data_write = {1'b0, 1'b1, u_data[index][0]};
		end
		else if (mem_tag_valid[3][21] && mem_tag_valid[3][20:0] == old_tag) 
		begin
			cache_hit = 3;
			wait_data = 0;//(index != old_index) ? 1 : 0;
			new_state = CACHE_HIT;
			u_data_write = {1'b0, 1'b0, u_data[index][0]};
		end
		else 
		begin
			wait_data = resetn ? 1 : 0;
			new_state = CACHE_MISS;
			u_data_write = 3'd0;
		end
		
		if(read)
		//if(read && !c_miss_wait)
		begin
			case (old_offset)
			4'd0:  reddata = cache_reddata[cache_hit][31:0];
			4'd1:  reddata = cache_reddata[cache_hit][63:32];
			4'd2:  reddata = cache_reddata[cache_hit][95:64];
			4'd3:  reddata = cache_reddata[cache_hit][127:96];
			4'd4:  reddata = cache_reddata[cache_hit][159:128];
			4'd5:  reddata = cache_reddata[cache_hit][191:160];
			4'd6:  reddata = cache_reddata[cache_hit][223:192];
			4'd7:  reddata = cache_reddata[cache_hit][255:224];
			4'd8:  reddata = cache_reddata[cache_hit][287:256];
			4'd9:  reddata = cache_reddata[cache_hit][319:288];
			4'd10: reddata = cache_reddata[cache_hit][351:320];
			4'd11: reddata = cache_reddata[cache_hit][383:352];
			4'd12: reddata = cache_reddata[cache_hit][415:384];
			4'd13: reddata = cache_reddata[cache_hit][447:416];
			4'd14: reddata = cache_reddata[cache_hit][479:448];
			4'd15: reddata = cache_reddata[cache_hit][511:480];
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
		state					 <= CACHE_HIT;
		cache_hit_reg 		 <= 0;
		av_read 				 <= 0;
		cache_wrdata		 <= 0;
		c_miss_start		 <= 0;
		c_miss_wait			 <= 0;
		cache_tag_write[0] <= 0;
		cache_tag_write[1] <= 0;
		cache_tag_write[2] <= 0;
		cache_tag_write[3] <= 0;
		overwrite_counter  <= 0;
		tag_count 			 <= 0;
		old_address			 <= address;
	end
	else
	begin
		state <= new_state;
		if((!wait_data && read))
		begin
			old_address <= address;
		end
		case (new_state)
		CACHE_HIT:
		begin
			cache_tag_write[0] <= 0;
			cache_tag_write[1] <= 0;
			cache_tag_write[2] <= 0;
			cache_tag_write[3] <= 0;
			c_miss_wait 		 <= 0;
			if(read)
			begin
				u_data[old_index] <= u_data_write;
				cache_hit_reg <= cache_hit;
			end
		end
		CACHE_MISS:
		begin
			c_miss_wait <= 1;
			if (!c_miss_start)
			begin
				av_read 		 <= 1;
				c_miss_start <= 1;
				casex (u_data[old_index])
				3'b0x0 : tag_count  <=0;
				3'b0x1 : tag_count  <=1;
				3'b10x : tag_count  <=2;
				3'b11x : tag_count  <=3;
				default : tag_count <=0;
				endcase
			end
			else
			if (!transmission)
			begin
				cache_wrdata <= av_reddata;
				cache_write[tag_count] <= 1;
				c_miss_start <= 0;
				if(mem_tag_valid[tag_count][21])
					overwrite_counter = overwrite_counter + 1;
			end
			else
			begin
				av_read <= 0;
			end
		end
		CACHE_WRITE:
		begin
			cache_write[tag_count] <= 0;
			cache_tag_write[tag_count] <= 1;
		end
		endcase
	end
end

endmodule

