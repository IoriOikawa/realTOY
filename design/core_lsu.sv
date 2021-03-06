`include "global.svh"

module core_lsu (
   input logic clk_i,
   input logic rst_ni,

   input logic val_i,
   input logic wen_i,
   input logic [7:0] addr_i,
   input logic [15:0] data_i,
   output logic [15:0] data_ro,
   output logic rdy_o,

   stdio.in stdin_intf,
   stdio.out stdout_intf,

   mem_rwport.master mem_rw_intf
);

   logic state, state_next;
   always_ff @(posedge clk_i) begin
      if (~rst_ni) begin
         state <= 0;
      end else if (val_i && rdy_o) begin
         state <= state_next;
      end
   end

   assign data_ro = state ? stdin_intf.data : mem_rw_intf.rdata;

   always_comb begin
      state_next = 0;
      rdy_o = 0;
      stdin_intf.rdy = 0;
      stdout_intf.val = 0;
      stdout_intf.data = '0;
      mem_rw_intf.val = 0;
      mem_rw_intf.wen = 0;
      mem_rw_intf.addr = '0;
      mem_rw_intf.wdata = '0;
      if (val_i) begin
         if (addr_i == 8'hff) begin
            if (wen_i) begin
               rdy_o = stdout_intf.rdy;
               stdout_intf.val = 1;
               stdout_intf.data = data_i;
            end else begin
               state_next = 1;
               rdy_o = stdin_intf.val;
               stdin_intf.rdy = 1;
            end
         end else begin
            rdy_o = mem_rw_intf.rdy;
            mem_rw_intf.val = 1;
            mem_rw_intf.wen = wen_i;
            mem_rw_intf.addr = addr_i;
            mem_rw_intf.wdata = data_i;
         end
      end
   end

endmodule
