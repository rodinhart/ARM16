`timescale 1ns / 1ps
module ALU(
    output [15:0] s,
    output C,
	 output N,
	 output Z,
	 output V,
    input [15:0] a,
    input [15:0] b,
    input cin,
	 input [2:0] op
    );

wire [16:0] r;
assign r =
  op == 0 ? b :
  op == 1 ? a & b :
  op == 2 ? ~b :
  op == 3 ? a ^ b :
  op == 4 ? a + b :
  op == 5 ? a + b + cin :
  op == 6 ? a + (~b) + 1 :
  op == 7 ? a + (~b) + cin : 0;

assign s = r[15:0];
assign C = r[16];
assign N = r[15];
assign Z = r[15:0] == 0;
assign V = (~a[15])&((~b[15])^op[1])&r[15] | a[15]&(b[15]^op[1])&(~r[15]);

endmodule
