// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 09/04/2017
// Description: ALU scoreboard, checks stimuli it receives from
//              the monitors export

class alu_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(alu_scoreboard);

     uvm_analysis_imp#(fu_if_seq_item, alu_scoreboard) item_export;

    bit [63:0] result;
    bit [31:0] result32;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
       super.build_phase(phase);
       item_export = new("item_export", this);
    endfunction : build_phase

    virtual function void write (fu_if_seq_item seq_item);
        result = 64'b0;
        result32 = 32'b0;
        // check for all possible ALU operations
        case(fu_op'(seq_item.operator))
            ADD:
              result = seq_item.operand_a + seq_item.operand_b;
            ADDW: begin
              result32 = seq_item.operand_a[31:0] + seq_item.operand_b[31:0];
              result = {{32{result32[31]}}, result32}; // sign extend the result
            end
            SUB:
             result = seq_item.operand_a - seq_item.operand_b;
            SUBW: begin
             result32 = seq_item.operand_a[31:0] - seq_item.operand_b[31:0];
             result = {{32{result32[31]}}, result32};
            end
            XORL:
              result =  seq_item.operand_a ^ seq_item.operand_b;
            ORL:
              result =  seq_item.operand_a | seq_item.operand_b;
            ANDL:
              result =  seq_item.operand_a & seq_item.operand_b;
            SRA:
              result = $signed(seq_item.operand_a[63:0]) >>> seq_item.operand_b[5:0];
            SRL:
              result = $unsigned(seq_item.operand_a) >>> seq_item.operand_b[5:0];
            SLL:
              result = $unsigned(seq_item.operand_a) <<< seq_item.operand_b[5:0];
            SRLW: begin
              result32 = $unsigned(seq_item.operand_a[31:0]) >>> seq_item.operand_b[4:0];
              result = {{32{result32[31]}}, result32};
            end
            SLLW: begin
              result32 = $unsigned(seq_item.operand_a[31:0]) <<< seq_item.operand_b[4:0];
              result = {{32{result32[31]}}, result32};
            end
            SRAW: begin
              result32 = $signed(seq_item.operand_a[31:0]) >>> seq_item.operand_b[4:0];
              result = {{32{result32[31]}}, result32};
            end
        endcase

        if (result != seq_item.result)
          `uvm_error("ALU Scoreboard", $sformatf("Result: %0h, Expected %0h", seq_item.result, result))

    endfunction : write;

endclass : alu_scoreboard
