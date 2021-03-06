
module apb_master (pclk, rstn, psel, penable, pwrite, paddr, pwdata, prdata,
                   done, ip_din, sink_data, sink_addr);
    input                    pclk;
    input                    rstn;
    output                   psel;
    output                   penable;
    output                   pwrite;
    output [`ADDR_WIDTH-1:0] paddr;
    output [`DATA_WIDTH-1:0] pwdata;
    input  [`DATA_WIDTH-1:0] prdata;
    output [`DATA_WIDTH-1:0] ip_din;
    input  [`DATA_WIDTH-1:0] sink_data;
    input  [`ADDR_WIDTH-1:0] sink_addr;
    input                    done;

`ifdef APB3
    input pslverr;
    input pready; 
`endif

   wire                   wr, rd;
   reg  [`DATA_WIDTH-1:0] din_r;   

   //-------------Output Ports Data Type------------------
   reg psel, penable;
   
   //-------------Internal Constants--------------------------
   parameter IDLE = 1, SETUP = 3, ACCESS = 2;
   
   //-------------Internal Variables---------------------------
   reg  [1:0]   state     ; // Seq part of the FSM
   reg  [1:0]   next_state; // combo part of FSM

   //----------State machine combinational logic--------------
   always @ (state or done)
   begin : FSM_COMBO
      next_state = IDLE;
      case(state)
          IDLE   : 
              if (!done)
                next_state = SETUP;
              else
                next_state = IDLE;
          SETUP  : 
              next_state = ACCESS;
          ACCESS : 
              if (done)
                 next_state = IDLE;
              else
                 next_state = SETUP;
              // with wait states add ACCESS => ACCESS loop          
          default : 
              next_state = IDLE;
      endcase
   end

   //----------Seq Logic-----------------------------
   always @ (posedge pclk)
   begin : FSM_SEQ
      if (!rstn) begin
        state <=  #1  IDLE;
      end else begin
        state <=  #1  next_state;
      end
   end

   //----------Output Registers---------------------
   //
   // Can be avoided using combinational assign instead of register process
   //
   always @ (posedge pclk)
   begin : OUTPUT_LOGIC
      if (!rstn) begin
          psel    <=  #1  1'b0;
          penable <=  #1  1'b0;
      end
      else begin
        case(state)
          IDLE : begin
                   psel    <=  #1  1'b0;
                   penable <=  #1  1'b0;
                 end
         SETUP : begin
                   psel    <=  #1  1'b1;
                   penable <=  #1  1'b0;
                 end
         ACCESS : begin
                   psel    <=  #1  1'b1;
                   penable <=  #1  1'b1;
                 end
         default : begin
                   psel    <=  #1  1'b0;
                   penable <=  #1  1'b0;
                 end
        endcase
      end
   end 
   
   assign pwrite = 1;
   assign paddr  = sink_addr;
   assign pwdata = sink_data;

endmodule

