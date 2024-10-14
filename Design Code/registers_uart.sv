`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.09.2024 15:47:28
// Design Name: 
// Module Name: registers_uart
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

///////////FCR (FIFO Control Register)
typedef struct packed{
 logic [1:0] rx_trigger;        // receive trigger
 logic [1:0] reserved;    // reserved
 logic dma_mode;             // DMA mode select
 logic tx_rst;           // Transmit FIFO reset
 logic rx_rst;           //receive FIFO reset
 logic ena;               // FIFO eenable
} fcr_t; 

 ////////////// LCR
   typedef struct packed {
    logic       dlab;    
    logic       set_break;     
    logic       sticky_parity;     
    logic       eps; 
    logic       pen;
    logic       stb; 
    logic [1:0] wls; 
  } lcr_t;   
  
 ////////////// LSR
   typedef struct packed {
    logic       rx_fifo_error;
    logic       temt;              //Transmitter Emtpy
    logic       thre;              //Transmitter Holding Register Empty
    logic       bi;                //Break Interrupt
    logic       fe;                //Framing Error
    logic       pe;                //Parity Error
    logic       oe;                //Overrun Error
    logic       dr;                //Data Ready
  } lsr_t; //Line Status Register
  
  //struct to hold all registers
 typedef struct {
 fcr_t       fcr; 
 lcr_t       lcr; 
 lsr_t       lsr; 
 logic [7:0] scr; 
 } csr_t;
  
//////structure for holding msb and lsb of baud counter
 typedef struct packed {
    logic [7:0] dmsb;               //Divisor Latch MSB
    logic [7:0] dlsb;               //Divisor Latch LSB
  } div_t;
 
 


module registers_uart(
   input clk, rst,
   input [2:0] addr_i,
   input wr_i, rd_i,
   input [7:0] din_i,
   output tx_push_o,
   output rx_pop_o,
   output baud_out,
   output reg[7:0] dout_o,
   input [7:0] rx_fifo_in,
   output rx_rst, tx_rst,
   output [3:0] rx_fifo_threshold,
   input rx_fifo_empty_i,
   input rx_oe, rx_pe, rx_fe, rx_bi,
   output csr_t csr_o
    );
    
    csr_t csr;
    
    ////////// Register structure
/*
Total 10 registers and address bus of size 3-bit (0-7)
Seventh bit of data format registe / Divisor Latch access bit (DLAB)
DLAB = 0 -> addr :0   THR/ RHR
            addr :1   IER
DLAB = 1 -> addr :0   LSB of baud rate divisor
            addr : 1  MSB of baud rate divisor
 ---------------------------------------------------           
            addr : 2  Interrupt Identification Reg IIR (R)  + FCR(FIFO control Reg)(new) (W)
            addr : 3  Data format reg / LCR
            addr : 4  Modem control reg / MCR
            addr : 5  Serialization Status register / LSR
            addr : 6  Modem Status Reg / MSR
            addr : 7 Scratch pad reg / SPR
*/
///THR -> temporary buffer for stroing data to be transmitted serially
//// old uart 8250 (16550 p) :  single byte buffer
//// 16550 : 16 byte of buffer
//// once wr is high push data to tx fifo
//// if dlab = 0, wr = 1 and addr = 0 then send push signal to TX fifo

wire tx_fifo_wr;
assign tx_fifo_wr= wr_i & (addr_i==3'b000) & (csr.lcr.dlab==1'b0);
assign tx_push_o=tx_fifo_wr;

//-----------------------------------------------------------------------
 
//RHR -> Hold the data recv by the shift register serially
//// read the data and push in the RX FIFO
//// if dlab = 0, rd = 1 and addr = 0 then send pop signal to RX fifo

wire rx_fifo_rd;
assign rx_fifo_rd= rd_i & (addr_i==3'b000) & (csr.lcr.dlab==1'b0);
assign rx_pop_o=rx_fifo_rd;

reg [7:0] rx_data;

always@(posedge clk)
 begin
   if(rx_pop_o)
    begin
      rx_data<=rx_fifo_in;
    end
 end
 
 ////////////////// Baud Generation Logic
 div_t dl;
 ///////////update dlsb if wr==1 dlab=1 and addr=0
 always@(posedge clk)
  begin
    if(wr_i && addr_i==3'b000 && csr.lcr.dlab==1'b1)
     begin
        dl.dlsb<=din_i;
     end
  end
  
 ///////////update dmsb if wr==1 dlab=1 and addr=1
 always@(posedge clk)
  begin
    if(wr_i && addr_i==3'b001 && csr.lcr.dlab==1'b1)
     begin
        dl.dmsb<=din_i;
     end
  end
  
  reg baud_pulse=0;
  reg[15:0] baud_cnt=0;
  reg update_baud;
  
  ///////// sense update in baud values
  always@(posedge clk)
   begin
     update_baud<= wr_i & (csr.lcr.dlab==1'b1) &((addr_i==3'b000 | addr_i==3'b001));
   end


/////////////// baud counter
always@(posedge clk, posedge rst)
 begin
   if(rst)
    
        baud_cnt<=16'h0000;
    
   else if(update_baud || baud_cnt<=16'h0000)
   
        baud_cnt<=dl;
   
   else
      
        baud_cnt<=baud_cnt-1;
 end
 
 ////////generate baud pulse when baud count reaches zero
 always@(posedge clk)
  begin
     if(baud_cnt==16'h0000 && dl!=16'h0000)
      baud_pulse<=1'b1;
     else
      baud_pulse<=1'b0;
  end
 
 assign baud_out = baud_pulse;  // for both receiver and transmitter
 
 
 ///////////////FIFO  Control register (FCR)
 /// Use to Enable FIFO Mode, Set FIFO Threshold, Clear FIFO
 // 0 -> Enable TX and RX FIFO
// 1 -> Clear RECV FIFO
// 2 -> Clear TX FIFO
// 3 -> DMA Mode Enable
// 4-5 -> Reserved
/*
 6-7 -> FIFO Threshold / trigger level for RX FIFO
00 - 1 byte
01 - 4 bytes
10 - 8 bytes
11 - 14 bytes
threshold will enable interrupt request , level falls below thre will clear interrupt
*/
 
////fifo write operation-> read data from user and update bits of fcr

always@(posedge clk, posedge rst)
 begin
   if(rst)
    begin
      csr.fcr<=8'h00;
    end
   
   else if(wr_i==1'b1 && addr_i==3'h2)
    begin
    csr.fcr.ena<=din_i[0];
    csr.fcr.rx_rst<=din_i[1];
    csr.fcr.tx_rst<=din_i[2];
    csr.fcr.dma_mode<=din_i[3];
    csr.fcr.rx_trigger<=din_i[7:6];
    end
    
   else 
    begin
      csr.fcr.rx_rst<=1'b0;
      csr.fcr.tx_rst<=1'b0;
    end
 end
 
 assign tx_rst=csr.fcr.tx_rst;
 assign rx_rst=csr.fcr.rx_rst;
 
////////////// based on the rx_trigger, generate threshold count for rx fifo
reg [3:0] rx_fifo_th_count=0;

always_comb
 begin
  if(csr.fcr.ena==1'b0)
   begin
     rx_fifo_th_count=4'd0;
   end
  
  else 
   begin
     case(csr.fcr.rx_trigger)
      2'b00: rx_fifo_th_count=4'd1;
      2'b01: rx_fifo_th_count=4'd4;
      2'b10: rx_fifo_th_count=4'd8;
      2'b11: rx_fifo_th_count=4'd14;
     endcase
   end
 end
 
 assign rx_fifo_threshold=rx_fifo_th_count;    //  go to rx fifo
 
 ///////////////////////Line control register ------> defines format of transmitted data
 
 lcr_t lcr;
 reg [7:0] lcr_temp;
 
 ///////////write new data to LCR
 always@(posedge clk)
  begin
    if(rst)
     csr.lcr<=8'h00;
    
    else if(wr_i==1'b1 && addr_i==3'h3)
     csr.lcr<=din_i;
  end
  
 ///////////////read lcr
 always@(posedge clk)
  begin
    if(rd_i==1'b1 && addr_i==3'h3)
     lcr_temp<=csr.lcr;
  end
  
 ////////////////////
 
 lsr_t lsr;
 reg [7:0] lsr_temp;
 ////// ----- LSR -- Serialization Status register   ---> Read only register
///////////////// - 8250
///// Trans Overwrite | Recv Overrun | Break | Parity Error | Framing Error | TXE | TBE | RxRDY 
/////      0                  1          2          3               4          5     6      7
 
//////////////   -16550
/////   DR | OE | PE | FE | BI | THRE | TEMT | RXFIFOE                                                                                  
////     0 <--------------------------------------> 7 
 
//-------------------bit 0 ---------------------------------
///bit 0 shows byte is rcvd in the rcv bufer and buffer can be read.
/// fifo will reset empty flag if data is present in rxfifo
//// LSR[0] <= ~empty_flag;
//// if flag is 1 / no data -> buffer is empty and do not require read
/////  flag is 0 / some data -> buffer have data and can be read
 
//-------------------bit 1 ---------------------------------
////////// Overrun error  - Data recv from serial port is slower than it recv
////////// occurs when data is recv after fifo is full and shift reg is already filled
 
 
///// -------------------- bit 2 -----------------------------
//////// PE - Parity error 
/*
0 = No parity error has been detected,
1 = A parity error has been detected with the character at the top of the receiver FIFO.
*/
 
///// -------------------- bit 3 -----------------------------
//////// FE - Frame error 
/*
 A framing error occurs when the received character does not have a valid STOP bit. In
response to a framing error, the UART sets the FE bit and waits until the signal on the RX pin goes high.
*/
 
///// -------------------- bit 4 -----------------------------
//////// Bi - Break indicator
/*
The BI bit is set whenever the receive data input (UARTn_RXD) was held low for longer than a
full-word transmission time. A full-word transmission time is defined as the total time to transmit the START, data,
PARITY, and STOP bits. 
*/
 
///// -------------------- bit 5 -----------------------------
//////// THRE
/*
0 = Transmitter FIFO is not empty. At least one character has been written to the transmitter FIFO. The transmitter
FIFO may be written to if it is not full.
1 = Transmitter FIFO is empty. The last character in the FIFO has been transferred to the transmitter shift register
(TSR).
*/
 
///// -------------------- bit 6 -----------------------------
//////// TEMT
/*
0 = Either the transmitter FIFO or the transmitter shift register (TSR) contains a data character.
1 = Both the transmitter FIFO and the transmitter shift register (TSR) are empty
*/
///// -------------------- bit 7 -----------------------------
//////// RXFIFOE
/*
0 = There has been no error, or RXFIFOE was cleared because the CPU read the erroneous character from the
receiver FIFO and there are no more errors in the receiver FIFO.
1 = At least one parity error, framing error, or break indicator in the receiver FIFO.
*/

////////////update the content of LSR register
always@(posedge clk, posedge rst)
 begin
   if(rst)
    begin
     csr.lsr<=8'h60;   //// both fifo and shift register are empty thre=1, tempt=1// 0110 0000
    end
   
   else
    begin
     csr.lsr.dr<= ~rx_fifo_empty_i;
     csr.lsr.oe<= rx_oe;
     csr.lsr.pe<= rx_pe;
     csr.lsr.fe<= rx_fe;
     csr.lsr.bi<= rx_bi;
    end
 end

////////////////// read register content
always@(posedge clk)
 begin
   if(rd_i==1'b1 && addr_i==3'h5)
    begin
      lsr_temp<=csr.lsr;
    end
 end
 
 //////////////Scratch pad register
 
// write new data to scr
always@(posedge clk, posedge rst)
 begin
   if(rst)  csr.scr<=8'h00;
   else if(wr_i==1'b1 && addr_i==3'h7)
    csr.scr<=din_i;
 end
 
 //////////////read data from scr
 reg [7:0] scr_temp;
 
 always@(posedge clk)
  begin
   if(rd_i==1'b1 && addr_i==3'h7)
    scr_temp<=csr.scr;
  end
  
//////////////////////////////////////

always@(posedge clk)
begin
case(addr_i)
0: dout_o <= csr.lcr.dlab ? dl.dlsb : rx_data;
1: dout_o <= csr.lcr.dlab ? dl.dmsb : 8'h00; /// csr.ier
2: dout_o <= 8'h00; /// iir
3: dout_o <= lcr_temp; /// lcr
4: dout_o <= 8'h00; //mcr;
5: dout_o <= lsr_temp; ///lsr
6: dout_o <= 8'h00; // msr
7: dout_o <= scr_temp; // scr
default: ;
endcase
end

assign csr_o=csr;
 endmodule