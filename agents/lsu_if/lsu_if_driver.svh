// Author: Florian Zaruba, ETH Zurich
// Date: 02.05.2017
// Description: Driver for interface lsu_if
// Copyright (C) 2017 ETH Zurich, University of Bologna
// All rights reserved.
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.
// Bug fixes and contributions will eventually be released under the
// SolderPad open hardware license in the context of the PULP platform
// (http://www.pulp-platform.org), under the copyright of ETH Zurich and the
// University of Bologna.

class lsu_if_driver extends uvm_driver #(lsu_if_seq_item);

    // UVM Factory Registration Macro
    `uvm_component_utils(lsu_if_driver)

    // Virtual Interface
    virtual lsu_if fu;

    //---------------------
    // Data Members
    //---------------------
    lsu_if_agent_config m_cfg;

    // Standard UVM Methods:
    function new(string name = "lsu_if_driver", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        lsu_if_seq_item cmd;
        seq_item_port.get_next_item(cmd);

        seq_item_port.item_done();
    endtask : run_phase

    function void build_phase(uvm_phase phase);
      if (!uvm_config_db #(lsu_if_agent_config)::get(this, "", "lsu_if_agent_config", m_cfg) )
         `uvm_fatal("CONFIG_LOAD", "Cannot get() configuration lsu_if_agent_config from uvm_config_db. Have you set() it?")

      fu = m_cfg.fu;
    endfunction: build_phase
endclass : lsu_if_driver
