`timescale 1ns / 1ps
module image(
    output [7:0] pixel,
    input [15:0] addr
    );

reg [7:0] img [2**16-1:0];
initial $readmemh("toucan.mem", img, 0, 160*100-1);

assign pixel = img[addr];

endmodule
