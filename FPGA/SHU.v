`timescale 1ns / 1ps
module SHU(
    output [3:0] s,
    output C,
	 output N,
	 output Z,
	 output V,
    input [3:0] a,
    input [3:0] b,
    input cin,
	 input [2:0] op
    );

wire [4:0] r;
assign r =
  op == 0 ? a << b : // lsl
  op == 1 ? a >>> b : // lsr
  op == 2 ? {a[3], a[3], a[3], a[3], a} >> b : // asr
  op == 3 ? (a >>> b) | (a << (4 - b)) : // ror  b%4?
  op == 4 ? (a >>> b) | (a << (5 - b)) | (cin << b) : // rrx     c3210   10c32
  op == 5 ? 0 :
  op == 6 ? 0 :
  op == 7 ? a + 4'h2 : // lnk
  0;

assign s = r[3:0];
assign C = r[4];
assign N = r[3];
assign Z = r[3:0] == 0;
assign V = (~a[3])&((~b[3])^op[1])&r[3] | a[3]&(b[3]^op[1])&(~r[3]);

endmodule
