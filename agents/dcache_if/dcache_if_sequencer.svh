// Author: Florian Zaruba, ETH Zurich
// Date: 29.05.2017
// Description: dcache_if Sequencer for dcache_if_sequence_item
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

class dcache_if_sequencer extends uvm_sequencer #(dcache_if_seq_item);

    // UVM Factory Registration Macro
    `uvm_component_utils(dcache_if_sequencer)

    // Standard UVM Methods:
    function new(string name="dcache_if_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass: dcache_if_sequencer


