// Author: Florian Zaruba, ETH Zurich
// Date: 12/20/2016
// Description: This is the main memory interface agent.
class fu_if_agent extends uvm_component;
    // UVM Factory Registration Macro
    `uvm_component_utils(fu_if_agent)
    //------------------------------------------
    // Data Members
    //------------------------------------------
    fu_if_agent_config m_cfg;
    //------------------------------------------
    // Component Members
    //------------------------------------------
    uvm_analysis_port #(fu_if_seq_item) ap;
    fu_if_driver m_driver;
    fu_if_sequencer m_sequencer;
    //------------------------------------------
    // Methods
    //------------------------------------------
    // Standard UVM Methods:
    extern function new(string name = "fu_if_agent", uvm_component parent = null);
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
endclass : fu_if_agent

function fu_if_agent::new(string name = "fu_if_agent", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

function void fu_if_agent::build_phase(uvm_phase phase);
    if (!uvm_config_db #(fu_if_agent_config)::get(this, "", "fu_if_agent_config", m_cfg) )
     `uvm_fatal("CONFIG_LOAD", "Cannot get() configuration apb_agent_config from uvm_config_db. Have you set() it?")

    m_driver = fu_if_driver::type_id::create("m_driver", this);
    m_sequencer = spi_sequencer::type_id::create("m_sequencer", this);

endfunction : build_phase

function void fu_if_agent::connect_phase(uvm_phase phase);

    m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    m_driver.m_cfg = m_cfg;
endfunction: connect_phase