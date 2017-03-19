// Author: Florian Zaruba, ETH Zurich
// Date: 12/20/2016
// Description: Agent configuration object.
//              This object is used by the agent to modularize the build and connect process.

class fu_if_agent_config extends uvm_object;

    // UVM Factory Registration Macro
    `uvm_object_utils(fu_if_agent_config)

    // Virtual Interface
    virtual fu_if fu;
    //------------------------------------------
    // Data Members
    //------------------------------------------
    // Is the agent active or passive
    uvm_active_passive_enum active = UVM_ACTIVE;

    // Is the memory interface a master or slave
    bit is_master = 0;

    // Standard UVM Methods:
    extern function new(string name = "fu_if_agent_config");

endclass : fu_if_agent_config


function fu_if_agent_config::new(string name = "fu_if_agent_config");
    super.new(name);
endfunction : new
