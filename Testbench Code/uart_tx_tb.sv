`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.09.2024 01:07:48
// Design Name: 
// Module Name: uart_tx_tb
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


module uart_tx_tb(

    );
    
    reg clk, rst, baud_pulse,pen, thre,stb,sticky_parity, eps,set_break;
reg [7:0] din;
reg [1:0] wls;
wire pop, sreg_empty, tx;
 
uart_tx tx_dut (.clk(clk), .rst(rst), .baud_pulse(baud_pulse), .pen(pen), .thre(thre),
.stb(stb), .sticky_parity(sticky_parity),.eps(eps), .set_break(set_break), .din(din), .wls(wls), .pop(pop), .tx(tx), .sreg_empty(sreg_empty));
 
initial begin
rst = 0;
clk = 0;
baud_pulse = 0;
pen = 1'b1;
thre = 0;
stb = 1 ; //// stop will be for 2-bit duration
sticky_parity = 0; ///sticky parity is off
eps = 1; ///even parity
set_break = 0;
din = 8'h13;
wls = 2'b11; ///data width : 8-bits
end
///////////////
always #5 clk =~clk;
/////////////////
initial begin
rst = 1'b1;
repeat(5)@(posedge clk);
rst = 0;
end
 
////////////////
integer count = 5;
 
always@(posedge clk)
begin
if(rst == 0)
begin
    if(count  != 0)
    begin
    count <= count - 1;
    baud_pulse <= 1'b0;
    end
    else
    begin
    count <= 5;
    baud_pulse <= 1'b1;
    end
end
end
//////////////////////////
 
endmodule

