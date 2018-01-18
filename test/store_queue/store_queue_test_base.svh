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
// Date: 29.05.2017
// Description: store_queue base test class

class store_queue_test_base extends uvm_test;

    // UVM Factory Registration Macro
    `uvm_component_utils(store_queue_test_base)

    //------------------------------------------
    // Data Members
    //------------------------------------------

    //------------------------------------------
    // Component Members
    //------------------------------------------
    // environment configuration
    store_queue_env_config m_env_cfg;
    // environment
    store_queue_env m_env;
    store_queue_if_sequencer sequencer_h;

    // reset_sequence reset;
    // ---------------------
    // Agent configuration
    // ---------------------
    // functional unit interface
    store_queue_if_agent_config m_store_queue_if_cfg;
    mem_if_agent_config m_mem_if_cfg;

    //------------------------------------------
    // Methods
    //------------------------------------------
    // standard UVM methods:
    function new(string name = "store_queue_test_base", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // build the environment, get all configurations
    // use the factory pattern in order to facilitate UVM functionality
    function void build_phase(uvm_phase phase);
        // create environment
        m_env_cfg = store_queue_env_config::type_id::create("m_env_cfg");

        // create agent configurations and assign interfaces
        // create agent store_queue_if configuration
        m_store_queue_if_cfg = store_queue_if_agent_config::type_id::create("m_store_queue_if_cfg");
        m_env_cfg.m_store_queue_if_agent_config = m_store_queue_if_cfg;

        m_mem_if_cfg = mem_if_agent_config::type_id::create("m_mem_if_cfg");
        m_env_cfg.m_mem_if_agent_config = m_mem_if_cfg;

        // get store_queue_if virtual interfaces
        // get master interface DB
        if (!uvm_config_db #(virtual store_queue_if)::get(this, "", "store_queue_if", m_store_queue_if_cfg.m_vif))
            `uvm_fatal("VIF CONFIG", "Cannot get() interface store_queue_if from uvm_config_db. Have you set() it?")
        m_env_cfg.m_store_queue_if = m_store_queue_if_cfg.m_vif;

        if (!uvm_config_db #(virtual mem_if)::get(this, "", "mem_if", m_mem_if_cfg.fu))
            `uvm_fatal("VIF CONFIG", "Cannot get() interface mem_if from uvm_config_db. Have you set() it?")
        m_env_cfg.m_mem_if = m_mem_if_cfg.fu;
        // configure as SLAVE in replay mode
        m_env_cfg.m_mem_if_agent_config.mem_if_config = SLAVE_REPLAY;
        m_env_cfg.m_mem_if_agent_config.store_if = 1'b1;

        // create environment
        uvm_config_db #(store_queue_env_config)::set(this, "*", "store_queue_env_config", m_env_cfg);
        m_env = store_queue_env::type_id::create("m_env", this);

    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        sequencer_h = m_env.m_store_queue_if_sequencer;
    endfunction

    task run_phase(uvm_phase phase);
        // reset = new("reset");
        // reset.start(sequencer_h);
    endtask

endclass : store_queue_test_base
