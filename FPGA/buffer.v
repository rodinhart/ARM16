`timescale 1ns / 1ps
module buffer(
    inout [15:0] q,
    input enable,
	 input [15:0] d
    );

assign q = enable ? d : 16'bZZZZZZZZZZZZZZZZ;

endmodule
