`timescale 1ns / 1ps
module RAM(
    output [15:0] q,
    input clk,
    input load,
    input [15:0] d,
    input [3:0] addr
    );

//reg [15:0] mem [7:0];

assign q =
  addr == 0 ? 16'b1000000001000010 :
  addr == 2 ? 16'b1000000100010100 :
  addr == 4 ? 16'b1110100011100001 :
  0;

endmodule
