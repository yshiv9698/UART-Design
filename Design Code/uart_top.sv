`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.09.2024 01:01:35
// Design Name: 
// Module Name: uart_top
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


module uart_top(
    
    input clk, rst, wr, rd,
    input [2:0] addr,
    input [7:0] din,
    output tx,
    input rx,
    output [7:0] dout 
    );
    
 csr_t csr;
 wire baud_pulse, pen, thre,stb;
 wire tx_fifo_push, tx_fifo_pop;
 wire [7:0] tx_fifo_out;
 wire tx_rst, rx_rst;
 wire r_oe, r_pe, r_fe, r_bi;
 wire rx_fifo_push;
 wire rx_fifo_threshold;
 wire rx_fifo_out, rx_fifo_pop;
 wire [7:0]rx_out;
 
 registers_uart registers_uart_inst (
     .clk(clk),
     .rst(rst),
     .wr_i(wr),
     .rd_i(rd),
     .rx_fifo_empty_i(),
     .rx_oe(),
     .rx_pe(r_pe),
     .rx_fe(r_fe),
     .rx_bi(r_bi),
     
     .addr_i(addr),
     .din_i(din),
     .tx_push_o(tx_fifo_push),
     .rx_pop_o(rx_fifo_pop),
     .baud_out(baud_pulse),
     .tx_rst(tx_rst),
     .rx_rst(rx_rst),
     .rx_fifo_threshold(rx_fifo_threshold),
     .dout_o(dout),
     .csr_o(csr),
     .rx_fifo_in(rx_fifo_out)
 );
 
 ///////////////tx Logic
 uart_tx uart_tx_inst(
   .clk(clk),
   .rst(rst),
   .baud_pulse(baud_pulse),
   .pen(csr.lcr.pen),
   .thre(1'b0),
   .stb(csr.lcr.stb),
   .sticky_parity(csr.lcr.sticky_parity),
   .eps(csr.lcr.eps),
   .set_break(csr.lcr.set_break),
   .din(tx_fifo_out),
   .wls(csr.lcr.wls),
   .pop(tx_fifo_pop),
   .sreg_empty(),
   .tx(tx)
 );
 
 
 //////////////////tx FIFO
 fifo tx_fifo_inst(
  .clk(clk),
  .rst(rst),
  .en(csr.fcr.ena),
  .push_in(tx_fifo_push),
  .pop_in(tx_fifo_pop),
  .din(din),
  .dout(tx_fifo_out),
  .empty(),
  .full(),
  .over_run(),
  .under_run(),
  .threshold(4'h0),
  .thre_trigger()
 );
 
 ///////////Rx Logic
 uart_rx uart_rx_inst (
    .clk (clk),
    .rst (rst),
    .baud_pulse (baud_pulse),
    .rx (rx),
    .sticky_parity (csr.lcr.sticky_parity),
    .eps (csr.lcr.eps),
    .pen (csr.lcr.pen),
    .wls (csr.lcr.wls),
    .push (rx_fifo_push),
    .pe (r_pe),
    .fe (r_fe),
    .bi (r_bi),
    .dout(rx_out)
);

fifo rx_fifo_inst (
    .rst (rst),
    .clk (clk),
    .en (csr.fcr.ena),
    .push_in (rx_fifo_push),
    .pop_in (rx_fifo_pop),
    .din (rx_out),
    .dout (rx_fifo_out),
    .empty (), /// fifo empty ier
    .full (),
    .over_run (),
    .under_run (),
    .threshold (rx_fifo_threshold),
    .thre_trigger ()
);
endmodule
