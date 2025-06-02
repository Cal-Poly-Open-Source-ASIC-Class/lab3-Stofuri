`timescale 1ns/1ps
`default_nettype none

module reg_file #(
    parameter WIDTH = 1  // Default to 1-bit if not specified
) (
    input  logic              CLK,
    input  logic [WIDTH-1:0]  data_in,
    output logic [WIDTH-1:0]  data_out
);

    always_ff @(posedge CLK) begin 
        data_out <= data_in;
    end 

endmodule
