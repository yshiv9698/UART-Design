`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.09.2024 17:47:59
// Design Name: 
// Module Name: fifo_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fifo_tb;
    reg rst, clk, en, push_in, pop_in;
reg [7:0] din;
wire [7:0] dout;
wire empty, full, overrun, underrun;
reg [3:0] threshold;
wire thre_trigger;

initial begin
  rst=0;
  clk=0;
  en=0;
  din=0;
end

fifo dut_fifo(
.clk(clk), .rst(rst), .en(en), .push_in(push_in), .pop_in(pop_in), .din(din), 
.dout(dout), .empty(empty), .full(full), .over_run(overrun), .under_run(underrun), .threshold(threshold),
.thre_trigger(thre_trigger)
);

always #5 clk=~clk;

initial begin
  rst=1'b1;
  repeat(5) @(posedge clk);
  for(int i=0; i<18; i++)
  begin
    rst=1'b0;
    push_in=1'b1;
    din=$urandom();
    pop_in=1'b0;
    en=1'b1;
    threshold=4'ha;
    @(posedge clk);
  end
end
endmodule
