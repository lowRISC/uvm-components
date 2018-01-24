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
// Date: 30.04.2017
// Description: mem_if_agent package - compile unit
package mem_if_agent_pkg;
    // configure the slave memory interface
    // 1. either as a slave with random grant response
    // 2. as a master interface making random data requests
    // 3. as a slave with no grant randomization
    // 4. replay data
    typedef enum {
        SLAVE, SLAVE_REPLAY, SLAVE_NO_RANDOM, MASTER
    } mem_if_config;
    // Mode of request either read or write
    typedef enum {
        READ, WRITE
    } mode_t;

    // UVM Import
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Sequence item to model transactions
    `include "mem_if_seq_item.svh"
    // Agent configuration object
    `include "mem_if_agent_config.svh"
    // Driver
    `include "mem_if_driver.svh"
    // Coverage monitor
    // `include "mem_if_coverage_monitor.svh"
    // Monitor that includes analysis port
    `include "mem_if_monitor.svh"
    // Sequencer
    `include "mem_if_sequencer.svh"
    // Main agent
    `include "mem_if_agent.svh"
    // Sequence
    `include "mem_if_sequence.svh"
endpackage: mem_if_agent_pkg
