`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.09.2024 01:04:51
// Design Name: 
// Module Name: uart_rx_tb
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


module uart_rx_tb(
  
    );
    reg clk, rst, baud_pulse, rx, sticky_parity, eps;
    reg pen;
    reg [1:0] wls;
    wire push;
    wire pe, fe, bi;
    wire [7:0] dout;
    
    uart_rx rx_dut(.clk(clk), .rst(rst), .baud_pulse(baud_pulse), .rx(rx), .eps(eps), .pen(pen),
    .wls(wls), .push(push), .pe(pe), .fe(fe), .bi(bi), .dout(dout), .sticky_parity(sticky_parity));
    
    initial begin
      clk=0;
      rst=0;
      baud_pulse=0;
      rx=1;
      pen=1;
      eps=0;
      sticky_parity=0;
      wls=2'b11;
    end
    
    // clock generation
    always #5 clk=~clk;
    
    reg [7:0] rx_reg=8'h45;
    
    initial begin
      rst=1'b1;
      repeat(5)@(posedge clk);
      rst=1'b0;
      
      rx=1'b0;
      repeat(16)@(posedge baud_pulse);
      
      for(int i=0; i<8; i++)
       begin
         rx=rx_reg[i];
         repeat(16)@(posedge baud_pulse);
       end
       
       //// parity generation
       rx=~(^rx_reg);
       repeat(16) @(posedge baud_pulse);
       
       /// generate stop bit
       rx=1;
       repeat(16) @(posedge baud_pulse);
    end 
    
    ////////// 
    integer count=5;
    always@(posedge clk)
     begin
       if(rst==0)
        begin
          if(count!=0)
           begin
            count<=count-1;
            baud_pulse<=1'b0;
           end
           
           else
            begin
             count<=5;
             baud_pulse<=1'b1;
            end
        end
     end
    
endmodule
