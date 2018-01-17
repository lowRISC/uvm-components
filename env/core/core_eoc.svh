// Author: Florian Zaruba, ETH Zurich
// Date: 05.06.2017
// Description: Determines end of computation
//
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

class core_eoc extends uvm_scoreboard;
    // UVM Factory Registration Macro
    `uvm_component_utils(core_eoc)
    event got_write;
    int exit_code = 0;
    string sig_dump_name;
    longint unsigned tohost;
    uvm_phase phase;
    string_buffer sb;

    // get the command line processor for parsing the plus args
    static uvm_cmdline_processor uvcl = uvm_cmdline_processor::get_inst();

    //------------------------------------------
    // Methods
    //------------------------------------------
    // analysis port
    uvm_analysis_imp #(mem_if_seq_item, core_eoc) item_export;
    // Standard UVM Methods:
    function new(string name = "core_eoc", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(longint unsigned)::get(this, "", "tohost", tohost))
            `uvm_fatal("VIF CONFIG", "Cannot get() interface core_if from uvm_config_db. Have you set() it?")

        // create a new string buffer and intercept the characters written to the UART address
        sb = new("sb", this);
        sb.set_logger("UART");

        // create the analysis export
        item_export  = new("item_export", this);
    endfunction

    function void write (mem_if_seq_item seq_item);
        // get the tohost value -> for details see the riscv-fesvr implementation
        if (seq_item.address == tohost) begin
            exit_code = seq_item.data >> 1;
            if (exit_code)
                `uvm_error( "Core Test",  $sformatf("*** FAILED *** (tohost = %0d)", exit_code) )
            else
                `uvm_info( "Core Test",  $sformatf("*** SUCCESS *** (tohost = %0d)", exit_code), UVM_LOW)

            -> got_write;

        end

        // UART Hack
        if (seq_item.address == 'h3000000) begin
            // $display("%c", seq_item.wdata);
            sb.append(seq_item.data[7:0]);
        end

    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);

        phase.raise_objection(this, "core_eoc");
        @got_write;
        phase.drop_objection(this, "core_eoc");

    endtask

endclass : core_eoc
