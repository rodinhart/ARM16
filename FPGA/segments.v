`timescale 1ns / 1ps
module segments(
	 output [7:0] cathodes,
	 output [3:0] anodes,
    input clk,
    input [15:0] d
    );

reg [19:0] count = 0;
always @ (posedge clk) begin
 count <= count + 20'h1;
end

wire [3:0] digit;
assign digit = d[4*count[19:18] +: 4];

wire [6:0] segs;
SSD_Decoder decoder_(digit, segs); 

assign cathodes = {1'b1, segs};

not(t19, count[19]);
not(t18, count[18]);
nand(anodes[0], t19, t18);
nand(anodes[1], t19, count[18]);
nand(anodes[2], count[19], t18);
nand(anodes[3], count[18], count[19]);

endmodule
