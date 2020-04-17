`timescale 1ns / 1ps
module clock25mhz(
    output clk25,
    input clk100
    );

reg [1:0] cnt;

always @ (posedge clk100) begin
  cnt <= cnt + 1'b1;
end

assign clk25 = cnt[1];

endmodule
