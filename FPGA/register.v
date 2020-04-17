`timescale 1ns / 1ps
module register(
    output reg [15:0] q,
    input clk,
    input load,
    input [15:0] d
    );

always @ (posedge clk) begin
  if (load == 1)
    q <= d;
  else
    q <= q;
end

endmodule
