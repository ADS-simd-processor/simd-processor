`include "params.svh"

module pe #(
    parameter DATA_WIDTH = 32
) (
    input logic signed [DATA_WIDTH-1:0] a, b,
    input logic [OP_SEL_WIDTH-1:0] op,
    output logic signed [DATA_WIDTH-1:0] c
);

    always_comb begin 
        unique case (op)
            2'b00 : c = b;
            2'b01 : c = a + b;
            2'b10 : c = a - b;
            2'b11 : c = a * b;
            default: c = b;
        endcase
    end

endmodule