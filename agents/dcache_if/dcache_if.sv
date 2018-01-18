// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 29.05.2017
// Description: DCache interface

// Guard statement proposed by "Easier UVM" (doulos)
`ifndef DCACHE_IF_SV
`define DCACHE_IF_SV
interface dcache_if
    (
        input clk
    );
        wire [11:0]  address_index;     // Index portion of address
        wire [43:0]  address_tag;       // Tag portion of the address
        wire [63:0]  data_wdata;        // Data to be written
        wire         data_req;          // Requests read data
        wire         data_gnt;          // Request has been granted, signals can be changed as
                                        // soon as request has been granted
        wire         kill_req;          // Request to kill the previous request
        wire         tag_valid;         // The tag (or kill request) is valid
        wire         data_rvalid;       // Read data is valid
        wire [63:0]  data_rdata;        // Read data
        wire         data_we;           // Write enable
        wire [7:0]   data_be;           // Byte enable

        clocking mck @(posedge clk);
            input   address_index, address_tag, data_wdata, data_we, data_req, kill_req, tag_valid, data_be;
            output  data_rvalid, data_rdata, data_gnt;
        endclocking

        // Memory interface configured as slave
        clocking sck @(posedge clk);
            output  address_index, address_tag, data_wdata, data_we, data_req, kill_req, tag_valid, data_be;
            input   data_rvalid, data_rdata, data_gnt;
        endclocking

        clocking pck @(posedge clk);
            // default input #1ns output #1ns;
            input  address_index, address_tag, data_wdata, data_req, data_we, data_be, kill_req, tag_valid,
                   data_gnt, data_rvalid, data_rdata;
        endclocking

        modport master (
            clocking mck
        );
        modport slave  (
            clocking sck
        );
endinterface

`endif
