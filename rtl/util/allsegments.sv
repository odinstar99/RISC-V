module allsegments(
	input [23:0] in,
	output [47:0] segments
);

logic [6:0] num1;
logic [6:0] num2;
logic [6:0] num3;
logic [6:0] num4;
logic [6:0] num5;
logic [6:0] num6;

hexto7segment h27s1(
	.in(in[3:0]),
	.out(num1)
);
hexto7segment h27s2(
	.in(in[7:4]),
	.out(num2)
);
hexto7segment h27s3(
	.in(in[11:8]),
	.out(num3)
);
hexto7segment h27s4(
	.in(in[15:12]),
	.out(num4)
);
hexto7segment h27s5(
	.in(in[19:16]),
	.out(num5)
);
hexto7segment h27s6(
	.in(in[23:20]),
	.out(num6)
);

always_comb begin
	segments[6:0] = num1;
	segments[7] = 1;
	segments[14:8] = num2;
	segments[15] = 1;
	segments[22:16] = num3;
	segments[23] = 1;
	segments[30:24] = num4;
	segments[31] = 1;
	segments[38:32] = num5;
	segments[39] = 1;
	segments[46:40] = num6;
	segments[47] = 1;
end

endmodule
