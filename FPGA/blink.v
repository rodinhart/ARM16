`timescale 1ns / 1ps

module blink(
	 output LD0,
	 output LD1,
	 output LD2,
	 output LD3,
	 output LD4,
	 output LD5,
	 output LD6,
	 output LD7,
	 
	 output CA,
	 output CB,
	 output CC,
	 output CD,
	 output CE,
	 output CF,
	 output CG,
	 output DP,
	 output AN0,
	 output AN1,
	 output AN2,
	 output AN3,
	 
	 output RED0,
	 output RED1,
	 output RED2,
	 output GREEN0,
	 output GREEN1,
	 output GREEN2,
	 output BLUE0,
	 output BLUE1,
	 output HSYNC,
	 output VSYNC,
	 
    input GCLK0,
	 input SW0,
	 input SW1,
	 input SW2,
	 input SW3,
	 input SW4,
	 input SW5,
	 input SW6,
	 input SW7,
	 input BTNL,
	 input BTNR,
	 input BTNU,
	 input BTND,
	 input BTNS
    );

// clock and fetch cycle
wire clock;
debounce _debounce(clock, BTNR, GCLK0);
wire exec;

// instruction register
wire [15:0] ir_reg;
wire [15:0] ir_data;
register ir_(ir_reg, clock, ir_load, ir_data);

// register bank
wire [15:0] r0_reg;
wire [15:0] r0_data;
register r0_(r0_reg, clock, r0_load, r0_data);

wire [15:0] r1_reg;
wire [15:0] r1_data;
register r1_(r1_reg, clock, r1_load, r1_data);

wire [15:0] r2_reg;
wire [15:0] r2_data;
register r2_(r2_reg, clock, r2_load, r2_data);

wire [15:0] r3_reg;
wire [15:0] r3_data;
register r3_(r3_reg, clock, r3_load, r3_data);

wire [15:0] r4_reg;
wire [15:0] r4_data;
register r4_(r4_reg, clock, r4_load, r4_data);

wire [15:0] r5_reg;
wire [15:0] r5_data;
register r5_(r5_reg, clock, r5_load, r5_data);

wire [15:0] r6_reg;
wire [15:0] r6_data;
register r6_(r6_reg, clock, r6_load, r6_data);

wire [15:0] r7_reg;
wire [15:0] r7_data;
programcounter r7_(r7_reg, clock, r7_load, r7_data, r7_count);

// busses

// in1 bus
wire [15:0] in1_reg;
wire [2:0] in1_select;
assign in1_reg =
  in1_select == 0 ? r0_reg :
  in1_select == 1 ? r1_reg :
  in1_select == 2 ? r2_reg :
  in1_select == 3 ? r3_reg :
  in1_select == 4 ? r4_reg :
  in1_select == 5 ? r5_reg :
  in1_select == 6 ? r6_reg :
  in1_select == 7 ? r7_reg :
  0;

// in2 bus
wire [15:0] in2_reg;
wire [2:0] in2_select;
assign in2_reg =
  in2_select == 0 ? r0_reg :
  in2_select == 1 ? r1_reg :
  in2_select == 2 ? r2_reg :
  in2_select == 3 ? r3_reg :
  in2_select == 4 ? r4_reg :
  in2_select == 5 ? r5_reg :
  in2_select == 6 ? r6_reg :
  in2_select == 7 ? r7_reg :
  0;

// in3 bus
wire [15:0] in3_reg;
wire [15:0] alu_out;

// out bus
wire [2:0] alu_op;
ALU alu_(alu_out, C, N, Z, V, in1_reg, in3_reg, 0, alu_op);

wire [15:0] ram_out;
RAM ram_(ram_out, clk, ram_load, in2_reg, alu_out);

wire [15:0] out_reg;
wire out_ramnotalu;
assign out_reg = out_ramnotalu ? ram_out : alu_out;

assign ir_data = out_reg;
assign r0_data = out_reg;
assign r1_data = out_reg;
assign r2_data = out_reg;
assign r3_data = out_reg;
assign r4_data = out_reg;
assign r5_data = out_reg;
assign r6_data = out_reg;
assign r7_data = out_reg;

// control logic
microcode microcode_(exec, clock);

assign r7_count = ~exec;

assign in1_select = ~exec ?
  3'd7 :
  ir_reg[10:8];

assign in2_select = ir_reg[2:0];

assign in3_reg = ~exec ?
	16'h0 :
	ir_reg[15:14] == 2'b10 ? {8'h0, ir_reg[7:0]} :
	in2_reg; // extend sign for x
	
assign alu_op =
	~exec ? 3'b100 :
	ir_reg[15:14] == 2'b10 ? ir_reg[13:11] :
	ir_reg[6:4];

assign out_ramnotalu = ~exec ? 1 : 0;

assign ir_load = ~exec;
wire [2:0] temp_load;
assign temp_load = ir_reg[10:8];
assign r0_load = exec && temp_load == 3'b000;
assign r1_load = exec && temp_load == 3'b001;
assign r2_load = exec && temp_load == 3'b010;
assign r3_load = exec && temp_load == 3'b011;
assign r4_load = exec && temp_load == 3'b100;
assign r5_load = exec && temp_load == 3'b101;
assign r6_load = exec && temp_load == 3'b110;
assign r7_load = exec && temp_load == 3'b111;

// output register
wire [15:0] output_reg;
//wire [15:0] output_data;
//register output_(output_reg, clock, BTNU, output_data);
segments segments_(
  {DP, CG, CF, CE, CD, CC, CB, CA},
  {AN3, AN2, AN1, AN0},
  GCLK0,
  output_reg);

wire [3:0] switches = {SW3, SW2, SW1, SW0};
assign output_reg =
  switches == 0 ? r0_reg :
  switches == 1 ? r1_reg :
  switches == 2 ? r2_reg :
  switches == 3 ? r3_reg :
  switches == 4 ? r4_reg :
  switches == 5 ? r5_reg :
  switches == 6 ? r6_reg :
  switches == 7 ? r7_reg :
  switches == 8 ? ir_reg :
  switches == 9 ? in1_reg :
  switches == 10 ? in2_reg :
  switches == 11 ? in3_reg :
  switches == 12 ? out_reg : 0;
  
 assign LD0 = SW0;
 assign LD1 = SW1;
 assign LD2 = SW2;
 assign LD3 = SW3;
 assign LD4 = SW4;
 assign LD5 = SW5;
 assign LD6 = exec;
 assign LD7 = ~exec;

// display
clock25mhz clock25mhz_(clk25, GCLK0);
wire [13:0] addr;
vga vga_(
  {BLUE1, BLUE0, GREEN2, GREEN1, GREEN0, RED2, RED1, RED0}, HSYNC, VSYNC,
  addr,
  clk25,
  8'hff);

endmodule

module microcode(
  output reg exec,
  input clk
  );
  
always @ (posedge clk) begin
 exec <= ~exec;
end
  
endmodule