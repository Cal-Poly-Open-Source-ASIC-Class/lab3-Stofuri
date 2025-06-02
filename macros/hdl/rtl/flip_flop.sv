

module flip_flop (
    input  logic CLK,
    input  logic stall_A,
    input  logic stall_B,
    output logic flop
);
    initial begin
        flop = 1'b0;
    end 

    always_ff @(posedge CLK) begin
        if (stall_B && !stall_A) begin 
            flop <= 1'b0;
        end 
        else 
        if (stall_A && !stall_B)begin 
                flop <= 1'b1;
        end 
    end 
endmodule