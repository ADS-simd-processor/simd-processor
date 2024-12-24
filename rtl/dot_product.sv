
module dot_product #(
    parameter PE_COUNT = 4,
    parameter DATA_WIDTH = 32
) (
    input logic clk, rstn,
    input logic [PE_COUNT-1:0][DATA_WIDTH-1:0] pe_res,
    input logic dot_prod_en,
    input logic shift,
    output logic [PE_COUNT-1:0][DATA_WIDTH-1:0] dot_out
);

    logic [DATA_WIDTH-1:0] sum;
    logic [$clog2(PE_COUNT)-1:0] idx, next_idx;
    logic [2*PE_COUNT-2:0][DATA_WIDTH-1:0] partial_sums;

    assign partial_sums[2*PE_COUNT-2:PE_COUNT-1] = pe_res;
    assign sum = partial_sums[0];
    assign next_idx = idx + 1;

    genvar i;
    generate
        for (i = 0; i < PE_COUNT-1; i = i+1) begin
            assign partial_sums[i] = partial_sums[2*i + 1] + partial_sums[2*i + 2];
        end
    endgenerate

    always_ff @(posedge clk) begin
        if (!rstn) begin
            dot_out <= 'b0;
            idx <= (1 << PE_COUNT) - 1;
        end
        else begin
            if (dot_prod_en) begin
                if (shift) begin
                    idx <= next_idx;
                    dot_out[next_idx] <= sum;
                end
                else begin
                    idx <= idx;
                    dot_out[idx] <= dot_out[idx] + sum;
                end
            end
            else begin
                idx <= idx;
                dot_out <= dot_out;
            end
        end
    end

endmodule