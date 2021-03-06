`include "global.svh"

module main_mem (
   input logic clk_i,
   input logic rst_ni, // wipe out all data

   mem_rwport.slave rw_intf,
   mem_rport.slave r_intf[0:`MEM_RPORTS-1]
);

   logic state;
   logic [7:0] ptr;
   always_ff @(posedge clk_i, posedge rst_ni) begin
      if (rst_ni) begin
         state <= 0;
         ptr <= 8'b0;
      end else begin
         state <= 1;
         ptr <= ptr + 1;
      end
   end

   genvar gi;
   generate
   for (gi = 0; gi < `MEM_RPORTS; gi++) begin : g
      logic [7:0] aaddr, baddr;
      /* verilator lint_off UNUSED */
      logic [15:0] adout, bdin, bdout;
      logic aen, ben, bwen;
      assign aaddr = r_intf[gi].addr;
      assign baddr = state ? ptr : rw_intf.addr;
      assign bdin = state ? 16'b0 : rw_intf.wdata;
      assign aen = r_intf[gi].val;
      assign ben = state || rw_intf.val;
      assign bwen = state || rw_intf.val && rw_intf.wen;

      logic [15:0] mem[0:255];
      always_ff @(posedge clk_i) begin
         // Ensure the memory is write-first.
         if (ben) begin
            if (bwen) begin
               mem[baddr] <= bdin;
            end else begin
               bdout <= mem[baddr];
            end
         end
         if (aen) begin
            adout <= mem[aaddr];
         end
      end

      assign r_intf[gi].rdata = adout;
      assign r_intf[gi].rdy = 1;
      if (gi == 0) begin
         assign rw_intf.rdata = bdout;
         assign rw_intf.rdy = 1;
      end
   end
   endgenerate

endmodule
