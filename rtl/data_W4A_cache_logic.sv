module data_W4A_cache_logic
#(parameter I_BURST=5'd16, I_CACHE_LENGTH=I_BURST*32)
(
    // clock and reset
	input   logic   clk,        // clock input
	input   logic   resetn,     // reset input
    // GPIO side

	input  logic [31:0] address,
	input  logic read,
	input  logic write,
	input  logic d_enable,
	input  logic [31:0] wrdata,
	input  logic [2:0] wr_data_size,
	input  logic [2:0] rd_data_size,
	output logic wait_data,
	output logic [31:0] reddata,
	 
	 	//Avalon master//
	output logic [31:0] av_address,
	output logic av_read,
	output logic av_write,
	input  logic av_read_data_wait,
	input  logic av_read_data_valid,
	input  logic [31:0] av_reddata,
	output logic [31:0] av_writedata,
	input  logic write_ready_n,
	input  logic av_waitrequest,
	output logic [4:0] av_burstcount
	//---------------//

);

logic [63:0] overwrite_counter;
logic [4:0]  burstcount;
logic [3:0]  offset;
logic [4:0]  index;
logic [3:0]  old_offset;
logic [4:0]  old_index;
logic [20:0] old_tag;
logic [31:0] old_address;  
logic [31:0] cache_reddata[3:0];
logic [31:0] cache_wrdata;
logic [31:0] reddata_reg;
logic cache_write[3:0];

logic [1:0] tag_count;
logic [1:0] tag_count_reg;
logic [1:0] cache_hit_n;
logic [1:0] cache_hit_n_reg;

logic [8:0] cache_address;

logic [31:0] mem_tag_valid [3:0];
logic [31:0] new_tag_valid;

logic [4:0] ca_index;
logic c_miss_start;
logic c_miss_wait; 
logic read_reg;
logic write_reg; 
logic [31:0] wrdata_reg;
logic [3:0] cache_byteenable;
logic [2:0] wr_data_size_reg;
logic [2:0] rd_data_size_reg;
logic cache_hit;
logic cache_edited;
logic av_req;
logic av_req_reg;
logic [1:0] addr_byteena;

logic [2:0] u_data [31:0];
logic [2:0] u_data_write;

enum logic [2:0] {CACHE_IDLE, CACHE_READ, CACHE_WRITE, CACHE_MISS, CACHE_WAIT, MEM_WRITE, AV_READ, AV_WRITE} state, next_state;

assign offset	= address[5:2];
assign index	= address[10:6];
assign addr_byteena	= old_address[1:0];
assign old_offset	= old_address[5:2];
assign old_index	= old_address[10:6];
assign old_tag		= old_address[31:11];
assign new_tag_valid = {9'b0, cache_edited, 1'b1, old_tag};
assign av_req = (address >= 32'h0fffffc0) &&  (address <= 32'h0fffffdf)? 1'b1 : 1'b0;

tags_memory tags_1
(
	.address_a({1'b0,ca_index}),
	.address_b({1'b1,ca_index}),
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
	.address_a({1'b0,ca_index}),
	.address_b({1'b1,ca_index}),
	.clock(clk),
	.data_a(new_tag_valid),
	.data_b(new_tag_valid),
	.wren_a(cache_write[2]),
	.wren_b(cache_write[3]),
	.q_a(mem_tag_valid[2]),
	.q_b(mem_tag_valid[3])
);

data_W4A_cache d_cache_1   
(
	.address_a({1'b0,cache_address}),
	.address_b({1'b1,cache_address}),
	.clock(clk),
	.data_a(cache_wrdata),
	.data_b(cache_wrdata),
	.byteena_a(cache_byteenable),
	.byteena_b(cache_byteenable),
	.wren_a(cache_write[0]),
	.wren_b(cache_write[1]),
	.q_a(cache_reddata[0]),
	.q_b(cache_reddata[1])
);

data_W4A_cache d_cache_2   
(
	.address_a({1'b0,cache_address}),
	.address_b({1'b1,cache_address}),
	.clock(clk),
	.data_a(cache_wrdata),
	.data_b(cache_wrdata),
	.byteena_a(cache_byteenable),
	.byteena_b(cache_byteenable),
	.wren_a(cache_write[2]),
	.wren_b(cache_write[3]),
	.q_a(cache_reddata[2]),
	.q_b(cache_reddata[3])
);

always_comb
begin	
	if (state == AV_READ || state == AV_WRITE)
	begin
		av_address = old_address;
		av_burstcount = 5'h1;
	end
	else
	begin
		av_address = (state == MEM_WRITE) ? {mem_tag_valid[tag_count_reg][20:0], old_index, 6'd0} : {old_address[31:6], 6'd0};
		av_burstcount = I_BURST;
	end
end

always_comb
begin
	if (mem_tag_valid[0][21] && mem_tag_valid[0][20:0] == old_tag) 
	begin
		cache_hit_n = 0;
		cache_hit = 1;
		u_data_write = {1'b1, u_data[old_index][1] ,1'b1};
	end
	else if (mem_tag_valid[1][21] && mem_tag_valid[1][20:0] == old_tag) 
	begin
		cache_hit_n = 1;
		cache_hit = 1;
		u_data_write = {1'b1, u_data[old_index][1] ,1'b0};
	end
	else if (mem_tag_valid[2][21] && mem_tag_valid[2][20:0] == old_tag) 
	begin
		cache_hit_n = 2;
		cache_hit = 1;
		u_data_write = {1'b0, 1'b1, u_data[old_index][0]};
	end
	else if (mem_tag_valid[3][21] && mem_tag_valid[3][20:0] == old_tag) 
	begin
		cache_hit_n = 3;
		cache_hit = 1;
		u_data_write = {1'b0, 1'b0, u_data[old_index][0]};
	end
	else 
	begin
		cache_hit_n = cache_hit_n_reg;
		u_data_write = 3'd0;
		cache_hit = 0;
	end

	if (!mem_tag_valid[0][21])
		tag_count  = 2'h0;
	else if (!mem_tag_valid[1][21])
		tag_count  = 2'h1;
	else if (!mem_tag_valid[2][21])
		tag_count  = 2'h2;
	else if (!mem_tag_valid[3][21])
		tag_count  = 2'h3;
	else
	casex (u_data[old_index])
		3'b0x0 : tag_count  = 2'h0;
		3'b0x1 : tag_count  = 2'h1;
		3'b10x : tag_count  = 2'h2;
		3'b11x : tag_count  = 2'h3;
		default : tag_count = 2'h0;
	endcase	
end

always_comb
begin
	if (c_miss_wait)
	begin
		cache_address =  {old_index, burstcount[3:0]};
		ca_index =  old_index;
	end 
	else if (write_reg || (state == CACHE_WRITE) || (read_reg && !d_enable))
	begin
		cache_address = {old_index, old_offset};
		ca_index =  old_index;
	end
	else
	begin
		cache_address = {index, offset};
		ca_index =  index;
	end
	
	if (wr_data_size_reg == 3'h0 || wr_data_size_reg == 3'h4)
	begin
		case (addr_byteena)
			2'h0 : 
			begin
				cache_wrdata = {24'h0, 	wrdata_reg[7:0]			};
				cache_byteenable = 4'h1;
			end
			2'h1 : 
			begin
				cache_wrdata = {16'h0, 	wrdata_reg[7:0], 8'h0	};
				cache_byteenable = 4'h2;
			end
			2'h2 : 
			begin
				cache_wrdata = {8'h0 , 	wrdata_reg[7:0], 16'h0	};
				cache_byteenable = 4'h4;
			end
			2'h3 : 
			begin
				cache_wrdata = {			wrdata_reg[7:0], 24'h0	};
				cache_byteenable = 4'h8;
			end
			default: 
			begin
				cache_wrdata = 32'bx;
				cache_byteenable = 4'h0;
			end
		endcase
	end
	else if (wr_data_size_reg == 3'h1 || wr_data_size_reg == 3'h5)
	begin
		case (addr_byteena)
			2'h0 : 
			begin
				cache_wrdata = {16'h0, 	wrdata_reg[15:0]		};
				cache_byteenable = 4'h3;
			end
			2'h1 : 
			begin
				cache_wrdata = {8'h0, 	wrdata_reg[15:0], 8'h0	};
				cache_byteenable = 4'h6;
			end
			2'h2 : 
			begin
				cache_wrdata = { 		wrdata_reg[15:0], 16'h0	};
				cache_byteenable = 4'hc;
			end
			default: 
			begin
				cache_wrdata = 32'bx;
				cache_byteenable = 4'h0;
			end
		endcase
	end
	else
	begin
		cache_wrdata = wrdata_reg;
		cache_byteenable = 4'hf;
	end

	reddata = reddata_reg;
	cache_edited = 0;
	cache_write[0]  = 0;
	cache_write[1]  = 0;
	cache_write[2]  = 0;
	cache_write[3]  = 0;
	case (state)
	CACHE_IDLE:
	begin
		wait_data = 0;
		if (d_enable)
			if(read)
				next_state = av_req ? AV_READ : CACHE_READ;
			else if (write)
				next_state = av_req ? AV_WRITE : CACHE_WRITE;
			else
				next_state = CACHE_IDLE;
		else
			next_state = CACHE_IDLE;
	end
	CACHE_READ:
	begin
		if (cache_hit)
		begin
			wait_data = 0;
			if (rd_data_size_reg == 3'h0 || rd_data_size_reg == 3'h4)
				case (addr_byteena)
					2'h0 : reddata = {24'h0, cache_reddata[cache_hit_n][7:0]};
					2'h1 : reddata = {24'h0, cache_reddata[cache_hit_n][15:8]};
					2'h2 : reddata = {24'h0, cache_reddata[cache_hit_n][23:16]};
					2'h3 : reddata = {24'h0, cache_reddata[cache_hit_n][31:24]};
					default: reddata = 32'bx;
				endcase
			else if (rd_data_size_reg == 3'h1 || rd_data_size_reg == 3'h5)
				case (addr_byteena)
					2'h0 : reddata = {16'h0, cache_reddata[cache_hit_n][15:0]};
					2'h1 : reddata = {16'h0, cache_reddata[cache_hit_n][23:8]};
					2'h2 : reddata = {16'h0, cache_reddata[cache_hit_n][31:16]};
					default: reddata = 32'bx;
				endcase
			else
				reddata = cache_reddata[cache_hit_n];
			if(read)
				next_state = av_req ? AV_READ : CACHE_READ;
			else if (write)
				next_state = av_req ? AV_WRITE : CACHE_WRITE;
			else
				next_state = CACHE_IDLE;
		end
		else 
		begin
			wait_data = 1;
			if (mem_tag_valid[tag_count][22])
				next_state = MEM_WRITE;
			else
				next_state = CACHE_MISS;
		end			
	end
	CACHE_WRITE:
	begin
		if (cache_hit)
		begin
			wait_data = 0;
			cache_edited = 1;
			cache_write[cache_hit_n]  = 1;
			if (write || read)
				next_state = CACHE_WAIT;
			else
				next_state = CACHE_IDLE;
		end
		else
		begin
			cache_edited = 0;
			wait_data = 1;
			cache_write[0]  = 0;
			cache_write[1]  = 0;
			cache_write[2]  = 0;
			cache_write[3]  = 0;
			if (mem_tag_valid[tag_count][22])
				next_state = MEM_WRITE;
			else
				next_state = CACHE_MISS;
		end
	end
	CACHE_MISS:
	begin
		wait_data = 1;
		cache_wrdata = av_reddata;
		cache_byteenable = 4'hf;
		if (c_miss_wait) 
		begin
			next_state = CACHE_MISS;
			if (av_read_data_valid)
				cache_write[tag_count_reg]  = 1;
			else
				cache_write[tag_count_reg]  = 0;
		end
		else if (write_reg)
			next_state = CACHE_WRITE;
		else if (read_reg)
			next_state = CACHE_WAIT;
		else
			next_state = CACHE_IDLE;
	end
	CACHE_WAIT:
	begin
		wait_data = 1;
		if(read_reg)
			next_state = av_req_reg ? AV_READ : CACHE_READ;
		else if(write_reg)
			next_state = av_req_reg ? AV_WRITE : CACHE_WRITE;
		else
			next_state = CACHE_IDLE;
	end
	MEM_WRITE:
	begin
		wait_data = 1;
		if (c_miss_wait) next_state = MEM_WRITE;
		else next_state = CACHE_MISS;
	end
	AV_READ:
	begin
		reddata = av_reddata;
		wait_data = av_read_data_wait || av_read;
		if (av_read_data_valid) 
		begin
			if(read)
				next_state = av_req ? AV_READ : CACHE_READ;
			else if (write)
				next_state = av_req ? AV_WRITE : CACHE_WRITE;
			else
				next_state = CACHE_IDLE;
		end
		else
			next_state = AV_READ;
	end
	AV_WRITE:
	begin
		wait_data = write_ready_n || av_write;
		if (!write_ready_n) 
		begin
			if(read)
				next_state = av_req ? AV_READ : CACHE_READ;
			else if (write)
				next_state = av_req ? AV_WRITE : CACHE_WRITE;
			else
				next_state = CACHE_IDLE;
		end
		else
			next_state = AV_WRITE;
	end
	default:
	begin
		wait_data = 0;
		next_state = CACHE_IDLE;
	end
	endcase
end

always_ff @(posedge clk)
begin
	if (!resetn)
	begin
		state				<= CACHE_IDLE;
		cache_hit_n_reg 	<= 0;
		av_read 			<= 0;
		c_miss_start	<= 0;
		c_miss_wait		<= 0;
		overwrite_counter <= 0;
		read_reg		<= 0;
		write_reg		<= 0;
		burstcount		<= 0;
		av_write		<= 0;
		av_writedata	<= 0;
		wrdata_reg		<= 0;
		av_req_reg		<= 0;
		wr_data_size_reg <= 0;
		rd_data_size_reg <= 0;
		tag_count_reg 	<= 0;
		old_address		<= address;
	end
	else
	begin
		state <= next_state;
		reddata_reg <= reddata;
		if((d_enable || state == CACHE_READ) && (read || write))
		begin
			old_address <= address;
		end
		if (d_enable)
		begin
			if ((state == CACHE_WRITE) || (state == CACHE_READ))
			u_data[old_index] <= u_data_write;
			if (read)
				rd_data_size_reg <= rd_data_size;
			if (write)
				wr_data_size_reg <= wr_data_size;
		end	 		
		case (next_state)
		CACHE_IDLE:
		begin
			read_reg	<= 0;
			write_reg	<= 0;
			av_req_reg	<= 0;
		end
		CACHE_WRITE:
		begin
			if (d_enable)
			begin
				read_reg	<= read;
				write_reg	<= write;
				wrdata_reg  <= wrdata;
				av_req_reg	<= av_req;
			end
		end
		CACHE_READ:
		begin
			if (d_enable)
			begin
				read_reg	<= read;
				write_reg	<= 0;
				av_req_reg	<= av_req;
			end
		end
		CACHE_MISS:
		begin
			c_miss_wait <= 1;
			if (!c_miss_start)
			begin
				tag_count_reg <= tag_count;
				if (!write_ready_n)
				begin
					av_read 	 <= 1;
					c_miss_start <= 1;
				end
			end
			else
			if (burstcount != I_BURST)
			begin
				av_read <= 0;
				if (av_read_data_valid)
				begin
					burstcount <= burstcount + 1;
				end
			end
			else
			begin
				c_miss_start 	<= 0;
				burstcount		<= 0;
				c_miss_wait <= 0;
			end
		end
		MEM_WRITE:
		begin
			av_writedata <= cache_reddata[tag_count_reg];
			if (!c_miss_wait)
			begin
				c_miss_wait <= 1;
				tag_count_reg <= tag_count;
			end
			else
			if (!c_miss_start)
			begin
				c_miss_start <= 1;
				burstcount <= burstcount + 1;
			end
			else
			if ((burstcount - 1) != I_BURST)
			begin
				av_write 	 <= 1;
				if (!av_waitrequest)
					burstcount <= burstcount + 1;
			end
			else
			begin
				av_write 	 	<= 0;
				c_miss_start 	<= 0;
				burstcount		<= 0;
				c_miss_wait <= 0;
				overwrite_counter <= overwrite_counter + 1;
			end
		end
		CACHE_WAIT:
		begin
			if (d_enable)
			begin
				read_reg	<= read;
				write_reg	<= write;
				wrdata_reg  <= wrdata;
			end
		end
		AV_READ:
		begin
			if (!(av_read || av_read_data_wait))
				av_read <= 1;
			else
				av_read <= 0;
		end
		AV_WRITE:
		begin
			if (!(av_write || write_ready_n))
			begin
				av_write <= 1;
				av_writedata <= wrdata;
			end
			else
				av_write <= 0;
		end
		endcase
	end
end

endmodule

