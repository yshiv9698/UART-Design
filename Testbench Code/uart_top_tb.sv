`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.09.2024 02:04:34
// Design Name: 
// Module Name: uart_top_tb
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


module uart_top_tb(

    );
    reg clk, rst, wr, rd;
    reg rx;
    reg [2:0] addr;
    reg [7:0] din;
    
    wire tx;
    wire [7:0] dout;
    
    uart_top dut (.clk(clk), .rst(rst), .wr(wr), .rd(rd), .addr(addr), .din(din), .tx(tx), .dout(dout));
    
    initial begin
      rst=0;
      clk=0;
      wr=0;
      rd=0;
      addr=0;
      din=0;
      rx=1;
    end
    
    always #5 clk=~clk;
    
    initial begin
      rst=1'b1;
      repeat(5)@(posedge clk);
      rst=1'b0;
      
      /// set dlab=1
      @(negedge clk);
      wr=1;
      addr=3'h3;
      din=8'b1000_0000;
      
      ////lsb latch=08
      @(negedge clk);
      addr=3'h0;
      din=8'b0000_1000;
      
      ////msb latch=01
      @(negedge clk);
      addr=3'h1;
      din=8'b0000_0001; //0000_00010000_1000
      
      //////dlab=0, wls=00(5 bits), stb=1(single stop bit), pen=1, eps=0(odd), sp=0
      @(negedge clk);
      addr=3'h3;
      din=8'b0000_1100;
      
      ///push fo in the tx_fifo
      @(negedge clk);
      addr=3'h0;
      din=8'b1111_0000; // 10000  parity=0
      
      //remove wr
      @(negedge clk);
      wr=0;
      @(posedge dut.uart_tx_inst.sreg_empty);
      repeat(48) @(posedge dut.uart_tx_inst.baud_pulse);
      $stop;
    end
    
endmodule
