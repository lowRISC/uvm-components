// Author: Florian Zaruba, ETH Zurich
// Date: 12/20/2016
// Description: This is the test base class which can be extended by real implementations.
//              Advantage of that approach is that the individual child classes do not need to care
//              about the build and connect phase anymore.

class alu_test_base extends uvm_test;

    // UVM Factory Registration Macro
    `uvm_component_utils(alu_test_base)

    //------------------------------------------
    // Data Members
    //------------------------------------------

    //------------------------------------------
    // Component Members
    //------------------------------------------
    // environment configuration
    alu_env_config m_env_cfg;
    // environment
    alu_env m_env;
    fu_if_sequencer sequencer_h;

    reset_sequence reset;
    // ---------------------
    // Agent configuration
    // ---------------------
    // Instruction cache master interface can currently either be
    // a memory master interface
    fu_if_agent_config m_cfg;

    //------------------------------------------
    // Methods
    //------------------------------------------
    // Standard UVM Methods:
    function new(string name = "alu_test_base", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Build the environment, get all configurations
    // Use the factory pattern in order to facilitate UVM functionality
    function void build_phase(uvm_phase phase);
        // create environment
        m_env_cfg = alu_env_config::type_id::create("m_env_cfg");

        // create agent configurations and assign interfaces
        // create agent memory master configuration
        m_cfg = fu_if_agent_config::type_id::create("m_cfg");
        m_env_cfg.m_fu_if_agent_config = m_cfg;
        // Get Virtual Interfaces
        // get master interface DB
        if (!uvm_config_db #(virtual fu_if)::get(this, "", "fu_vif", m_cfg.fu))
            `uvm_fatal("VIF CONFIG", "Cannot get() interface fu_vif from uvm_config_db. Have you set() it?")
        m_env_cfg.m_fu_if = m_cfg.fu;


        // create environment
        uvm_config_db #(alu_env_config)::set(this, "*", "alu_env_config", m_env_cfg);
        m_env = alu_env::type_id::create("m_env", this);

    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        sequencer_h = m_env.m_fu_if_sequencer;
    endfunction

    task run_phase(uvm_phase phase);
        reset = new("reset");
        reset.start(sequencer_h);
    endtask

endclass : alu_test_base