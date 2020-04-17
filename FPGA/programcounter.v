`timescale 1ns / 1ps
module programcounter(
    output reg [15:0] q,
    input clk,
    input load,
    input [15:0] d,
    input count
    );

always @ (posedge clk) begin
  if (load == 1)
    q <= d;
  else
    if (count == 1)
      q <= q + 16'h2;
    else
	   q <= q;
end

endmodule
