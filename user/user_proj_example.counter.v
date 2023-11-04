// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32,
    parameter DELAYS=10
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);


    wire clk;
    assign clk =wb_clk_i;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

    wire [31:0]Di0;
    wire EN0;
    wire [3:0]WE0;
    wire [31:0]A0;
    wire [31:0]Do0;

    reg [31:0]bram_addr=0;
    reg [3:0]bram_we;
    reg bram_en;
    assign A0 =bram_addr;
    assign WE0=bram_we;
    assign EN0=bram_en;
    assign Di0=wbs_dat_i;

    assign wbs_ack_o=Wbs_ack_o;
    assign wbs_dat_o=Do0;

    reg Wbs_ack_o=0;

   // IO
    assign io_out = count;
    assign io_oeb = {(`MPRJ_IO_PADS-1){rst}};

    // IRQ
    assign irq = 3'b000;	// Unused

    // LA
    assign la_data_out = {{(127-BITS){1'b0}}, count};
    // Assuming LA probes [65:64] are for controlling the count clk & reset  
    assign clk = (~la_oenb[64]) ? la_data_in[64]: wb_clk_i;
    assign rst = (~la_oenb[65]) ? la_data_in[65]: wb_rst_i;

reg [4:0]count=0;

//wishbone controller
always @(posedge clk ) begin

    bram_addr <= wbs_adr_i;
    if(wbs_adr_i[31:24]==8'b00111000)begin
    if(wbs_cyc_i && wbs_stb_i) begin
        if(count<11)begin
            //$display("count:%d ack%d datao:%x din:%x addr:%x stb:%d sel:%d we:%d",count,Wbs_ack_o,wbs_dat_o,wbs_dat_i,wbs_adr_i,wbs_stb_i,wbs_sel_i,wbs_we_i);
            count<=count+1;
            if(wbs_sel_i==15) begin
                bram_en<=1;               
                    if(wbs_we_i) begin
                    bram_we <= 4'b1111;
                    end
                    else begin
                    bram_we <= 4'b0000;                                
                    end
            end
            else bram_en<=0;

        Wbs_ack_o <= 1'b0;
        end
        else begin
            count<=0;
            Wbs_ack_o <= 1'b1;  
        end
    end
    else bram_we <= 4'b0000; 
    end
end


















    bram user_bram (
        .CLK(clk),
        .WE0(WE0),
        .EN0(EN0),
        .Di0(Di0),
        .Do0(Do0),
        .A0(A0)
    );

endmodule



`default_nettype wire
