// Author: Florian Zaruba, ETH Zurich
// Date: 10/28/2017
// Description: Scoreboard model
//              Golden model for the scoreboard
//
// Copyright (C) 2017 ETH Zurich, University of Bologna
// All rights reserved.

class Scoreboard;

    scoreboard_entry_t decoded_instructions[$];
    scoreboard_entry_t issued_instructions[$];
    static logic[TRANS_ID_BITS-1:0] i = 0;

    // utility function to get randomized input data
    static function scoreboard_entry_t randomize_scoreboard();
            exception_t exception = { 63'h0, 63'h0, 1'b0};
            scoreboard_entry_t entry = {
                63'b0, i, ALU, ADD, 5'h5, 5'h5, 5'h5, 64'h0, 1'b0, 1'b0, exception, 1'b0
            };
            return entry;
    endfunction : randomize_scoreboard

    // just allow one operation
    function void submit_instruction(scoreboard_entry_t entry);
        entry.trans_id = i;
        i = (++i % 8);
        decoded_instructions.push_back(entry);
    endfunction : submit_instruction

    // get the current issue instruction
    function scoreboard_entry_t get_issue();
        scoreboard_entry_t issue = decoded_instructions.pop_front();
        // put in issue queue
        issued_instructions.push_back(issue);
        return issue;
    endfunction : get_issue

    // write back to scoreboard
    function void write_back(logic [TRANS_ID_BITS-1:0] trans_id, logic [63:0] value);
        for (int i = 0; i < $size(issued_instructions); i++) begin
            if (issued_instructions[i].trans_id == trans_id) begin
                // $display("Model Write Back: %0h", value);
                issued_instructions[i].valid    = 1'b1;
                issued_instructions[i].result   = value;
            end
        end
    endfunction : write_back

    // commit the instruction, e.g.: delete it from the entries
    function scoreboard_entry_t commit();
        return issued_instructions.pop_front();
    endfunction : commit

    // return the clobbered registers
    function logic [31:0][$bits(fu_t)-1:0] get_clobber();
        logic [31:0][$bits(fu_t)-1:0] result;
        for (int i = 0; i < $size(issued_instructions); i++) begin
            if (issued_instructions[i].rd != 5'h0) begin
                result[issued_instructions[i].rd] = issued_instructions[i].fu;
            end
        end
        return result;
    endfunction : get_clobber


endclass : Scoreboard
