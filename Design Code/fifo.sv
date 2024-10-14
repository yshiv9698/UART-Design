`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.09.2024 01:24:29
// Design Name: 
// Module Name: fifo
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


module fifo(
  input rst, clk, en, push_in, pop_in,
  input [7:0] din,
  output  [7:0] dout,
  output empty, full, under_run, over_run,
  output thre_trigger,
  input [3:0] threshold 
    );
    
    reg[7:0] mem[16];
    reg [3:0] waddr=0;
    
    logic push, pop;
    
    /////////////empty flag condition
    reg empty_t;
    always@(posedge clk, posedge rst)
     begin
       if(rst) empty_t<=1'b0;
       else
        begin
          case({push,pop})
             2'b10: empty_t<=1'b0;
             2'b01: empty_t<=(~|(waddr) | ~en);
             default:;
          endcase
        end
     end
    
    ////////////full falg condition
     reg full_t;
    always@(posedge clk, posedge rst)
     begin
       if(rst) full_t<=1'b0;
       else
        begin
          case({push,pop})
             2'b01: full_t<=1'b0;
             2'b10: empty_t<=(&(waddr) | ~en);
             default:;
          endcase
        end
     end
     
     assign push =push_in & ~full_t;
     assign pop=pop_in & ~empty_t;
     
     assign dout=mem[0];
     
    ////////////address pointer update
    always@(posedge clk, posedge rst)
    begin
     if(rst) waddr<=4'h0;
     else
      begin
        case({push,pop})
         2'b10: begin
           if(waddr!=4'hf && full_t==1'b0)
             waddr<=waddr+1;
           else
             waddr<=waddr;
         end 
         
         2'b01: begin
           if(waddr!=0 && empty_t==1'b0)
            waddr<=waddr-1;
           else
            waddr<=waddr;
         end
         
         default:;
        endcase
      end
    end
    /////////// memory update
    
    always@(posedge clk, posedge rst)
    begin
      if(rst)
       begin
          for(int i=0; i<16; i++)
           begin
             mem[i]<=8'h00;
           end
       end
       
       else
        begin
          case({push, pop})
            2'b00:;
            2'b10: mem[waddr]<=din;
            2'b01: begin
              for(int i=0; i<14; i++)
               begin
                 mem[i]<=mem[i+1];
               end
               mem[15]<=8'h00;
            end
            2'b11: begin
              for(int i=0; i<14; i++)
               begin
                 mem[i]<=mem[i+1];
               end
               mem[15]<=8'h00;
               mem[waddr-1]<=din;
            end
          endcase
        end
    end
    
    ////////// under run flag
    reg underrun_t;
    always@(posedge clk, posedge rst)
    begin
     if(rst) underrun_t<=1'b0;
     else if(pop_in==1'b1 && empty_t==1'b1)
      underrun_t<=1'b1;
     else 
      underrun_t<=1'b0;
    end
    
    //////////// over run flag
      reg overrun_t;
    always@(posedge clk, posedge rst)
    begin
     if(rst) overrun_t<=1'b0;
     else if(push_in==1'b1 && full_t==1'b1)
      overrun_t<=1'b1;
     else 
      overrun_t<=1'b0;
    end
    
    //////////// threshold
    reg thre_t;
    always@(posedge clk, posedge rst)
    begin
      if(rst) thre_t<=1'b0;
      else if(push^pop)
       begin
         thre_t<= (waddr>=threshold) ? 1'b1:1'b0;
       end
    end
    
    assign empty= empty_t;
    assign full=full_t;
    assign overrun=overrun_t;
    assign underrun=underrun_t;
    assign thre_trigger= thre_t;
endmodule
