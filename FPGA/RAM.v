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
  addr == 0 ? 16'b1000000000000000 :
  addr == 2 ? 16'b1010000000000111 :
  addr == 4 ? 16'b1101111111111100 :
  0;

endmodule
