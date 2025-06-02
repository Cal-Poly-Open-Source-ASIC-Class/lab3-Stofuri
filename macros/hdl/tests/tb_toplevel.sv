`timescale 1ns/1ps
`default_nettype none

module tb_toplevel;

    // Clock & reset
    logic clk;

    // DUT inputs
    logic         pA_wb_stb_i, pB_wb_stb_i;
    logic [10:0]  pA_wb_addr_i, pB_wb_addr_i;
    logic [31:0]  pA_wb_data_i, pB_wb_data_i;
    logic [31:0]  pA_wb_data_o,pB_wb_data_o;
    logic         pA_wb_en_i,pB_wb_en_i;
    logic  [3:0]  pA_wb_we_i,pB_wb_we_i;
    logic         pA_wb_ack_o,pB_wb_ack_o;
    logic         pA_wb_stall_o,pB_wb_stall_o;

    // DUT outputs
    logic [31:0]  pA_data_o, pB_data_o;

    // Instantiate DUT
    toplevel dut (
        .clk           (clk),
        .pA_wb_stb_i   (pA_wb_stb_i),
        .pB_wb_stb_i   (pB_wb_stb_i),
        .pA_wb_en_i    (pA_wb_en_i),
        .pB_wb_en_i    (pB_wb_en_i),
        .pA_wb_we_i    (pA_wb_we_i),
        .pB_wb_we_i    (pB_wb_we_i),
        .pA_wb_addr_i  (pA_wb_addr_i),
        .pB_wb_addr_i  (pB_wb_addr_i),
        .pA_wb_data_i  (pA_wb_data_i),
        .pB_wb_data_i  (pB_wb_data_i),
        .pA_wb_data_o  (pA_wb_data_o),
        .pB_wb_data_o  (pB_wb_data_o),
        .pA_wb_ack_o   (pA_wb_ack_o),
        .pB_wb_ack_o   (pB_wb_ack_o),
        .pA_wb_stall_o (pA_wb_stall_o),
        .pB_wb_stall_o (pB_wb_stall_o)
    );

    // Clock generation
    localparam CLK_PERIOD = 10;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Simulation setup
    always begin
        $dumpfile("tb_toplevel.vcd");
        $dumpvars(0, tb_toplevel);

        // Initialize
        clk <= 0;

        pA_wb_en_i  <= 0;
        pB_wb_en_i  <= 0;
        pA_wb_stb_i <= 0;
        pB_wb_stb_i <= 0;
        pA_wb_addr_i <= 0;
        pB_wb_addr_i <= 0;
        pA_wb_data_i <= 0;
        pB_wb_data_i <= 0;
        pA_wb_we_i <= 0;
        pB_wb_we_i <= 0;
        #15
        // Testcases

        // first case
        pA_wb_stb_i <= 1;
        pB_wb_stb_i <= 0;
        pA_wb_data_i <= 1;
        pA_wb_addr_i <= 11'b00000000100;
        pA_wb_we_i <= 4'b1111;
        pA_wb_en_i  <= 1;

        #10
        pA_wb_data_i <= 32'b00000000000000000000000000000010; //write 2
        pA_wb_addr_i <= 11'b00000001000;                      //addr 4
        #10;
        pA_wb_data_i <= 32'b00000000000000000000000000000011; //write 3
        pA_wb_addr_i <= 11'b00000010000;                      //addr 8
        #10;
        pA_wb_data_i <= 32'b00000000000000000000000000000100; //write 4
        pA_wb_addr_i <= 11'b00000100000;                      //addr 16
        #10;
        pA_wb_data_i <= 32'b00000000000000000000000000000101; //write 5
        pA_wb_addr_i <= 11'b00001000000;                      //addr 32
        #10;
        pA_wb_we_i <= 0;
        pA_wb_addr_i <= 11'b00000000100; //read 1
        #10;
        pA_wb_addr_i <= 11'b00000001000; //read 2
        #10;
        pA_wb_addr_i <= 11'b00000010000; //read 3
        #10;
        pA_wb_addr_i <= 11'b00000100000; //read 4
        #10;
        pA_wb_addr_i <= 11'b00001000000; //read 5
        #10;
        pA_wb_stb_i  <= 1'b1;
        pB_wb_stb_i  <= 1'b1;
        pA_wb_addr_i <= 11'b10000000000;
        pB_wb_addr_i <= 11'b00000000100;
        #10
        pA_wb_addr_i <= 11'b00000000000; // 0
        pB_wb_addr_i <= 11'b00000001000; // 8
        #10
        pA_wb_addr_i <= 11'b00000000000; // 0
        pB_wb_addr_i <= 11'b00000001100; // c
        #10
        pA_wb_addr_i <= 11'b00000000100; // 4
        pB_wb_addr_i <= 11'b00000001100; // c
        #10
        pA_wb_addr_i <= 11'b00000000100; // 4
        pB_wb_addr_i <= 11'b00000010000; // 10
        #10
        pA_wb_addr_i <= 11'b00000001000; // 8
        pB_wb_addr_i <= 11'b00000010000; // 10
        #10
        pA_wb_addr_i <= 11'b00000001000; // 8
        pB_wb_addr_i <= 11'b00000010100; // 14
        #10
        pA_wb_addr_i <= 11'b00000001100; // c
        pB_wb_addr_i <= 11'b00000010100; // 14


        // Done
        #50;
        $display("Simulation complete.");
        $finish;
    end


endmodule
