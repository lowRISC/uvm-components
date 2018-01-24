// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 3/18/2017
// Description: Scoreboard interface
//              The interface can be used in Master or Slave mode.

// Guard statement proposed by "Easier UVM" (doulos)
`ifndef SCOREBOARD_IF__SV
`define SCOREBOARD_IF_SV

import ariane_pkg::*;

interface scoreboard_if #(parameter int NR_WB_PORTS = 1)(input clk);
    wire                                           flush;
    wire [31:0][$bits(fu_t)-1:0]                   rd_clobber;
    wire [4:0]                                     rs1_address;
    wire [63:0]                                    rs1;
    wire                                           rs1_valid;
    wire [4:0]                                     rs2_address;
    wire [63:0]                                    rs2;
    wire                                           rs2_valid;
    scoreboard_entry_t                             commit_instr;
    wire                                           commit_ack;
    scoreboard_entry_t                             decoded_instr;
    wire                                           decoded_instr_valid;
    wire                                           decoded_instr_ack;
    scoreboard_entry_t                             issue_instr;
    wire                                           issue_instr_valid;
    wire                                           issue_ack;
    wire [NR_WB_PORTS-1:0][TRANS_ID_BITS-1:0]      trans_id;
    wire [NR_WB_PORTS-1:0][63:0]                   wdata;
    wire [NR_WB_PORTS-1:0][$bits(exception_t)-1:0] ex;
    wire [NR_WB_PORTS-1:0]                         wb_valid;

    // Scoreboard interface configured as master
    clocking mck @(posedge clk);
        default input #1 output #5; // save timing
        output   flush, rs1_address, rs2_address, commit_ack, decoded_instr, decoded_instr_valid, issue_ack, trans_id, wdata, ex, wb_valid;
        input    rd_clobber, rs1, rs1_valid, rs2, rs2_valid, commit_instr, issue_instr, issue_instr_valid, decoded_instr_ack;
    endclocking
    // Scoreboard interface configured in passive mode (-> monitor)
    clocking pck @(posedge clk);
        input flush, rs1_address, rs2_address, commit_ack, decoded_instr, decoded_instr_valid, issue_ack, trans_id, wdata, ex, wb_valid,
              rd_clobber, rs1, rs1_valid, rs2, rs2_valid, commit_instr, issue_instr, issue_instr_valid, decoded_instr_ack;
    endclocking

    modport master  (clocking mck);
    modport passive (clocking pck);

endinterface
`endif
