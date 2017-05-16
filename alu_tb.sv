// Author: Florian Zaruba, ETH Zurich
// Date: 03/19/2017
// Description: Top level testbench module. Instantiates the top level DUT, configures
//              the virtual interfaces and starts the test passed by +UVM_TEST+
//
// Copyright (C) 2017 ETH Zurich, University of Bologna
// All rights reserved.
module alu_tb;

    import uvm_pkg::*;
    // import the main test class
    import alu_lib_pkg::*;
    import ariane_pkg::*;

    logic clk;
    logic rstn_i;

    localparam OPERATOR_SIZE = 8;
    localparam OPERAND_SIZE = 64;

    fu_if #(OPERATOR_SIZE, OPERAND_SIZE) alu_if (clk);

    // ------------------------
    // DUT - Device Under Test
    // ------------------------
    alu
    dut
    (
        .trans_id_i             (                           ),
        .alu_valid_i            (                           ),
        .operator_i             ( fu_op'(alu_if.operator)   ),
        .operand_a_i            ( alu_if.operand_a          ),
        .operand_b_i            ( alu_if.operand_b          ),
        .result_o               ( alu_if.result             ),
        .alu_valid_o            (                           ),
        .alu_ready_o            (                           ),
        .alu_trans_id_o         (                           )
    );

    initial begin
    // register the ALU interface
    uvm_config_db #(virtual fu_if)::set(null, "uvm_test_top", "fu_vif", alu_if);
    end

    initial begin
        clk = 1'b0;
        rstn_i = 1'b0;
        repeat(8)
            #10ns clk = ~clk;

        rstn_i = 1'b1;

        forever
            #10ns clk = ~clk;
    end

    initial begin
        // print the topology
        uvm_top.enable_print_topology = 1;
        // Start UVM test
        run_test();
    end
endmodule
