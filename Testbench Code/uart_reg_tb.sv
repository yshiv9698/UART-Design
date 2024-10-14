`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.09.2024 15:55:08
// Design Name: 
// Module Name: uart_reg_tb
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


module uart_reg_tb(

    );
    
reg clk=0, rst=0;
reg wr_i, rd_i;
reg rx_fifo_empty_i;
reg[7:0] rx_fifo_in;
reg [2:0] addr_i;
reg [7:0] din_i;
reg rx_oe, rx_pe, rx_fe, rx_bi;
wire tx_push_o;    // add new data to tx FIFO
wire rx_pop_o;    // read data from Rx FIFO

wire baud_out; // baud pulse for transmitter and receiver

wire tx_rst, rx_rst;
wire [3:0] rx_fifo_threshold;

wire [7:0] dout_o;

csr_t csr;

registers_uart dut(
.clk(clk), .rst(rst), .wr_i(wr_i), .rd_i(rd_i), .rx_fifo_empty_i(rx_fifo_empty_i),
.rx_oe(rx_oe), .rx_pe(rx_pe), .rx_fe(rx_fe), .rx_bi(rx_bi), .addr_i(addr_i), .din_i(din_i),
.tx_push_o(tx_push_o), .rx_pop_o(rx_pop_o), .baud_out(baud_out), .tx_rst(tx_rst), .rx_rst(rx_rst), 
.rx_fifo_threshold(rx_fifo_threshold), .dout_o(dout_o), .csr_o(csr), .rx_fifo_in(rx_fifo_in)
);

// clock generation
always #5 clk=~clk;

initial begin
  rst=1;
  repeat(5) @(posedge clk);
  rst=0;
  
  //set DLAB (MSB) of LCR (3H) register to 1
  wr_i=1;
  addr_i=3'h3;
  din_i=8'b1000_0000;
  @(posedge clk);
  
  // update MSB of divisor latch
  addr_i=3'h1;
  din_i=8'b0000_0001;
  @(posedge clk);
  
  // update LSB of divisor latch
  addr_i=3'h0;
  din_i=8'b0000_1000; ////////////// 00000_0001_0000_1000
  @(posedge clk);
  
  // make DLAB 0
  addr_i=3'h3;
  din_i=8'b0000_0000;
  @(posedge clk);
  $stop;
  end
  


endmodule
