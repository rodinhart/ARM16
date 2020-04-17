`timescale 1ns / 1ps
module vga(
    output [7:0] index,
    output HSYNC,
    output VSYNC,
    output [13:0] addr,
    input clk,
    input [7:0] d
    );

reg [9:0] hcnt = 0;
always @ (posedge clk) begin
  if (hcnt == 799)
    hcnt <= 10'h0;
  else
    hcnt <= hcnt + 1'b1;
end

assign HSYNC = hcnt >= 656 ? hcnt < 752 ? 1'b0 : 1'b1 : 1'b1;

reg [8:0] vcnt = 0;
always @ (posedge clk) begin
  if (hcnt == 656)
    if (vcnt == 524)
	   vcnt <= 9'h0;
	 else
	   vcnt <= vcnt + 1'b1;
  else
    vcnt <= vcnt;
end

assign VSYNC = vcnt >= 490 ? vcnt < 492 ? 1'b0 : 1'b1 : 1'b1;

assign addr = hcnt[9:2] + 160 * (vcnt[8:2] - 10);
assign index = hcnt < 640 ? vcnt >= 40 && vcnt < 440 ? d : 8'h0 : 8'h0;

endmodule
