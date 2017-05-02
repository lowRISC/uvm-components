// Author: Florian Zaruba, ETH Zurich
// Date: 02.05.2017
// Description: lsu_if sequence consisting of lsu_if_sequence_items
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

class lsu_if_sequence extends uvm_sequence #(lsu_if_seq_item);

    // UVM Factory Registration Macro
    `uvm_object_utils(lsu_if_sequence)

    //-----------------------------------------------
    // Data Members (Outputs rand, inputs non-rand)
    //-----------------------------------------------


    //------------------------------------------
    // Constraints
    //------------------------------------------



    //------------------------------------------
    // Methods
    //------------------------------------------

    // Standard UVM Methods:
    function new(string name = "lsu_if_sequence");
      super.new(name);
    endfunction

    task body;
      lsu_if_seq_item req;

      begin
        req = lsu_if_seq_item::type_id::create("req");
        start_item(req);
        assert(req.randomize());
        finish_item(req);
      end
    endtask:body

endclass : lsu_if_sequence