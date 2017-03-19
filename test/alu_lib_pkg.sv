// Author: Florian Zaruba, ETH Zurich
// Date: 12/20/2016
// Description: This package contains all test related functionality.
package alu_lib_pkg;
    // Standard UVM import & include:
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    // Import the memory interface agent
    import fu_if_agent_pkg::*;
    import alu_env_pkg::*;
    import alu_sequence_pkg::*;
    
    // Test based includes like base test class and specializations of it
    // ----------------
    // Base test class
    // ----------------
    `include "alu_test_base.svh"
    // -------------------
    // Child test classes
    // -------------------
    // plain randomized test
    `include "alu_test.svh"

endpackage
