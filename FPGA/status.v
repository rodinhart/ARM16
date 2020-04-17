`timescale 1ns / 1ps
module status(
    output reg C,
    output reg N,
    output reg Z,
    output reg V,
    input clk,
    input load,
    input cin,
    input nin,
    input zin,
    input vin
    );

always @ (posedge clk) begin
  if (load == 1) begin
    C <= cin;
	 N <= nin;
	 Z <= zin;
	 V <= vin;
  end else begin
    C <= C;
	 N <= N;
	 Z <= Z;
	 V <= V;
  end
end

endmodule
