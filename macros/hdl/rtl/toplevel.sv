`timescale 1ns/1ps
`default_nettype none

module toplevel (
    input         clk,        
    // Bus transaction request  
    input         pA_wb_stb_i, 
    input         pB_wb_stb_i, 
    input         pA_wb_en_i,
    input         pB_wb_en_i,
    input   [3:0] pA_wb_we_i,
    input   [3:0] pB_wb_we_i,
    // Address for RAM A & B   
    input  [10:0] pA_wb_addr_i, 
    input  [10:0] pB_wb_addr_i,
    // Input data 
    input  [31:0] pA_wb_data_i, 
    input  [31:0] pB_wb_data_i,
    // Outputs when stall is complete 
    output [31:0] pA_wb_data_o,
    output [31:0] pB_wb_data_o,
    output        pA_wb_stall_o,
    output        pB_wb_stall_o,
    output logic  pA_wb_ack_o,
    output logic  pB_wb_ack_o
);

// Internal wires and logic
logic [7:0] muxA1_out_o, muxB1_out_o;
logic [31:0] muxA2_out_o, muxB2_out_o;
logic [31:0] ramA_data_o, ramB_data_o;

logic        pA_muxA_sel_o, pB_muxB_sel_o;
logic        pA_muxA_sel_b_o, pB_muxB_sel_b_o;
logic        pA_stall_o, pB_stall_o;
logic [1:0]  pA_mux_offset_i, pB_mux_offset_i;
logic [1:0]  pA_mux_offset_o, pB_mux_offset_o;
logic [31:0] byte_mask_A, byte_mask_B;
logic        flip_flop_o;

// Pre-sliced address components to avoid tool issues
logic [7:0] pA_addr_8b, pB_addr_8b;
assign pA_addr_8b = pA_wb_addr_i[9:2];
assign pB_addr_8b = pB_wb_addr_i[9:2];


// Address muxes for RAM A
always_comb begin
    case (pA_muxA_sel_o)
        1'b0: muxA1_out_o = pA_addr_8b;
        1'b1: muxA1_out_o = pB_addr_8b;
        default: muxA1_out_o = 8'hFF;
    endcase
end 

// Address muxes for RAM B
always_comb begin
    case (pB_muxB_sel_o)
        1'b0: muxB1_out_o = pA_addr_8b;
        1'b1: muxB1_out_o = pB_addr_8b;
        default: muxB1_out_o = 8'hFF;
    endcase
end 
logic [31:0] pA_dataA, pB_dataB;
// Data Port Muxes for RAM A
always_comb begin
    case (pA_muxA_sel_o)
        1'b0: pA_dataA = pA_wb_data_i;
        1'b1: pA_dataA = pB_wb_data_i;
        default: pA_dataA = 32'hFFFFFFFF;
    endcase
end 

// Data Port Muxes for RAM B
always_comb begin
    case (pB_muxB_sel_o)
        1'b0: pB_dataB = pA_wb_data_i;
        1'b1: pB_dataB = pB_wb_data_i;
        default: pB_dataB = 32'hFFFFFFFF;
    endcase
end 

// Byte offset selection
assign pA_mux_offset_i = pA_wb_addr_i[1:0];
assign pB_mux_offset_i = pB_wb_addr_i[1:0];

reg_file #(.WIDTH(2)) byte_selA_reg (
    .CLK      (clk),
    .data_in  (pA_mux_offset_i),
    .data_out (pA_mux_offset_o)
);

reg_file #(.WIDTH(2)) byte_selB_reg (
    .CLK      (clk),
    .data_in  (pB_mux_offset_i),
    .data_out (pB_mux_offset_o)
);

// Write-enable decoding (one-hot)
//byte_offset_A
wire [31:0] ram_A_byte, ram_A_half, ram_A_up_byte, ram_A_word;
assign ram_A_byte    = { 24'h000000,ramA_data_o [7:0]};
assign ram_A_half    = {  16'h0000,ramA_data_o [15:0]};
assign ram_A_up_byte = {     8'h00,ramA_data_o [23:0]};
assign ram_A_word    = ramA_data_o;

//byte_offset_B
wire [31:0] ram_B_byte, ram_B_half, ram_B_up_byte, ram_B_word;
assign ram_B_byte    = { 24'h000000,ramB_data_o [7:0]};
assign ram_B_half    = {  16'h0000,ramB_data_o [15:0]};
assign ram_B_up_byte = {     8'h00,ramB_data_o [23:0]};
assign ram_B_word    = ramB_data_o;

always_comb begin
    case (pA_mux_offset_o)
        2'b00: byte_mask_A = ram_A_word;      //word
        2'b01: byte_mask_A = ram_A_byte;      //byte
        2'b10: byte_mask_A = ram_A_half;      //halfword
        2'b11: byte_mask_A = ram_A_up_byte;   //upperbyte
        default: byte_mask_A = 32'h00000000;
    endcase
end

always_comb begin
    case (pB_mux_offset_o)
        2'b00: byte_mask_B = ram_B_word;      //word
        2'b01: byte_mask_B = ram_B_byte;      //byte
        2'b10: byte_mask_B = ram_B_half;      //halfword
        2'b11: byte_mask_B = ram_B_up_byte;   //upperbyte
        default: byte_mask_B = 32'h00000000;
    endcase
end 

// RAM A instance
DFFRAM256x32 RAM_A (
    .CLK (clk),
    .WE0 (pA_wb_we_i),
    .EN0 (pA_wb_en_i),
    .Di0 (pA_dataA),
    .Do0 (ramA_data_o),
    .A0  (muxA1_out_o)
);

// RAM B instance
DFFRAM256x32 RAM_B (
    .CLK (clk),
    .WE0 (pB_wb_we_i),
    .EN0 (pB_wb_en_i),
    .Di0 (pB_dataB),
    .Do0 (ramB_data_o),
    .A0  (muxB1_out_o)
);

// Hazard detection unit
hazard_driver driver (
    .addr_A  (pA_wb_addr_i[10]),
    .addr_B  (pB_wb_addr_i[10]),
    .strobe_A(pA_wb_stb_i),
    .strobe_B(pB_wb_stb_i),
    .stall_A (pA_stall_o),
    .stall_B (pB_stall_o),
    .mux_A_1 (pA_muxA_sel_o),
    .mux_B_1 (pB_muxB_sel_o),
    .turn_i  (flip_flop_o)
);

// Mux select pipelining
reg_file #(.WIDTH(1)) mux_reg_A (
    .CLK      (clk),
    .data_in  (pA_muxA_sel_o),
    .data_out (pA_muxA_sel_b_o)
);

reg_file #(.WIDTH(1)) mux_reg_B (
    .CLK      (clk),
    .data_in  (pB_muxB_sel_o),
    .data_out (pB_muxB_sel_b_o)
);

// Flip-flop for memory retention
flip_flop mem_ret (
    .CLK     (clk),
    .stall_A (pA_stall_o),
    .stall_B (pB_stall_o),
    .flop    (flip_flop_o)
);

// Final data muxes for outputs
always_comb begin
    case (pA_muxA_sel_b_o)
        1'b0: muxA2_out_o = byte_mask_A;
        1'b1: muxA2_out_o = byte_mask_B;
        default: muxA2_out_o = 32'h00000000;
    endcase
end

always_comb begin
    case (pB_muxB_sel_b_o)
        1'b0: muxB2_out_o = byte_mask_A;
        1'b1: muxB2_out_o = byte_mask_B;
        default: muxB2_out_o = 32'h00000000;
    endcase
end

always_ff @(posedge clk) begin
    if(!pA_stall_o && pA_wb_stb_i) begin 
        pA_wb_ack_o <= 1'b1;
    end 
    else begin
        pA_wb_ack_o <= 1'b0;
    end 
    if(!pB_stall_o && pB_wb_stb_i) begin 
        pB_wb_ack_o <= 1'b1;
    end
    else begin
        pB_wb_ack_o <= 1'b0;
    end 
end 

// Drive outputs
assign pA_wb_data_o = muxA2_out_o;
assign pB_wb_data_o = muxB2_out_o;
assign pA_wb_stall_o = pA_stall_o;
assign pB_wb_stall_o = pB_stall_o;

endmodule
