`timescale 1ns/1ps

import ariane_pkg::*;

module ariane_top_tb;
   // CPU Control Signals
   logic                           fetch_enable_i = 1;         // start fetching data
   // Core ID; Cluster ID and boot address are considered more or less static
   logic [63:0]                    boot_addr_i = 64'H40000000;            // reset boot address
   // Debug Interface
   logic                           debug_req_i = 0;
   logic                           debug_gnt_o;
   logic                           debug_rvalid_o;
   logic [15:0]                    debug_addr_i = 0;
   logic                           debug_we_i = 0;
   logic [63:0]                    debug_wdata_i = 0;
   logic [63:0]                    debug_rdata_o;
   logic                           debug_halted_o;
   logic                           debug_halt_i = 0;
   logic                           debug_resume_i = 0;

   logic             clk_i, rst_ni;          
   logic             test_en_i = 'b1; // enable all clock gates for testing
   // Core ID; Cluster ID and boot address are considered more or less static
   logic [ 3:0]      core_id_i = 'b0;
   logic [ 5:0]      cluster_id_i = 'b0;
   logic             flush_req_i = 'b0;
   logic             flushing_o;
   // Interrupt s
   logic [1:0]       irq_i = 'b0; // level sensitive IR lines; mip & sip
   logic             ipi_i = 'b0; // inter-processor interrupts
   logic             sec_lvl_o; // current privilege level oot
   // Timer facilities
   logic [63:0]      time_i = 'b0; // global time (most probably coming from an RTC)
   logic             time_irq_i = 'b0; // timer interrupt in
   logic [63:0]      mtimecmp_o;             // time comparison threshold
   logic [63:0]      minten_o;               // external machine interrupt enable
   logic [63:0]      sinten_o;               // external supervisor interrupt enable
   tracer_t          tracer;
   

   
   parameter logic [63:0]               CACHE_START_ADDR  = 64'h8000_0000;
 // address on which to decide whether the request is cache-able or not
   parameter int                        unsigned AXI_ID_WIDTH      = 10;
   parameter int                        unsigned AXI_USER_WIDTH    = 1;
   parameter int                        unsigned AXI_ADDRESS_WIDTH = 64;
   parameter int                        unsigned AXI_DATA_WIDTH    = 64;
   
   ariane_wrapped dut(.*);

   initial
     begin
        clk_i = 0;
        rst_ni = 0;
        forever
          begin
             #1000
               clk_i = 1;
             #1000
               clk_i = 0;
             #1000
               clk_i = 1;
             #1000
               clk_i = 0;
             #1000
               clk_i = 1;
             #1000
               clk_i = 0;
             #1000
               clk_i = 1;
             #1000
               clk_i = 0;
               rst_ni = 1;
             
          end
     end
                     
endmodule
                        
