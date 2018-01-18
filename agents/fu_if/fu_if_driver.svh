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
// Date: 12/21/2016
// Description: Driver of the memory interface

class fu_if_driver extends uvm_driver #(fu_if_seq_item);

    // UVM Factory Registration Macro
    `uvm_component_utils(fu_if_driver)

    // Virtual Interface
    virtual fu_if fu;

    //---------------------
    // Data Members
    //---------------------
    fu_if_agent_config m_cfg;

    // Standard UVM Methods:
    function new(string name = "fu_if_driver", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        fu_if_seq_item cmd;
        fork
        forever begin : cmd_loop
            shortint unsigned result;

            // using clocking blocks this is possible
            seq_item_port.get_next_item(cmd);

            fu.sck.operand_a <= cmd.operand_a;
            fu.sck.operand_b <= cmd.operand_b;
            fu.sck.operand_c <= cmd.operand_c;
            fu.sck.operator <= cmd.operator;

            @(fu.sck)

            cmd.result = fu.sck.result;
            cmd.compare_result = fu.sck.comparison_result;

            seq_item_port.item_done();

        end : cmd_loop
        join_none
    endtask : run_phase

    function void build_phase(uvm_phase phase);
      if (!uvm_config_db #(fu_if_agent_config)::get(this, "", "fu_if_agent_config", m_cfg) )
         `uvm_fatal("CONFIG_LOAD", "Cannot get() configuration fu_if_agent_config from uvm_config_db. Have you set() it?")

      fu = m_cfg.fu;
    endfunction: build_phase
endclass : fu_if_driver
