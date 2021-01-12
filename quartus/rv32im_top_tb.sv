`timescale 1 ns/ 1 ps

module rv32im_top_tb();

	logic clk;
	logic clrn;
		
	rv32im_top dut (
		.clk(clk),
		.resetn(clrn) 
	);
	
	
	initial                                                
	begin                                                  
		clk=0;
		clrn = 0;
		#10;
        clk=1;
        #10;
        clk=0;
        #10;
        clk=1;
        #10;
        clk=0;
        #10;
        clk=1;
        #10;
        clk=0;
        clrn = 1;
		forever #10 clk=~clk;
	end   
	
		initial
	begin
		repeat (400) @(posedge clk);
		$stop;
	end
	
endmodule


