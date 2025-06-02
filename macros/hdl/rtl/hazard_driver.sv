`timescale 1ns/1ps

module hazard_driver(
    input  logic addr_A,
    input  logic addr_B,
    input  logic turn_i,
    input  logic strobe_A,
    input  logic strobe_B,
    output logic stall_A,
    output logic stall_B,
    output logic mux_A_1,
    output logic mux_B_1 
);

always_comb begin

        stall_A = 0;
        stall_B = 0;
        mux_A_1 = 0;
        mux_B_1 = 0;


    // if normal operation,
    if (addr_A == 1'b0 && addr_B == 1'b1) begin
        mux_A_1 = 1'b0;
        mux_B_1 = 1'b1;
    end 
    else if (addr_A == 1'b1 && addr_B == 1'b0) begin
        mux_A_1 = 1'b1;
        mux_B_1 = 1'b0;
    end 

    // if loading into RAM A
    //allows port A first
    if (addr_A == 1'b0 && addr_B == 1'b0 && turn_i == 0 && strobe_A == 1 && strobe_B == 1) begin
        stall_A = 1'b1;
        stall_B = 1'b0;
        mux_A_1 = 1'b1; 
        
    end 
    //allows port B second
    else if (addr_A == 1'b0 && addr_B == 1'b0 && turn_i == 1 && strobe_A == 1 && strobe_B == 1) begin
        stall_A = 1'b0;
        stall_B = 1'b1;
        mux_A_1 = 1'b0;
    end 

    // if loading into RAM B
    if (addr_A == 1'b1 && addr_B == 1'b1 && turn_i == 0) begin
        stall_A = 1'b1;
        stall_B = 1'b0;
        
    end 
    else if (addr_A == 1'b1 && addr_B == 1'b1 && turn_i == 1) begin
        stall_A = 1'b0;
        stall_B = 1'b1;
    end 

end
endmodule 
