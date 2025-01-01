
module status_manager (
    input logic clk, rstn, 

    // To PS side
    input logic in_data_valid,
    output logic out_data_valid,

    // To decoder
    input logic ins_done,
    output logic ins_valid
);

    always_ff @(posedge clk) begin
        if (!rstn) begin
            out_data_valid <= 0;
            ins_valid <= 0;
        end
        else begin
            out_data_valid <= (ins_done) ? 1 : ((in_data_valid) ? 0 : out_data_valid);
            ins_valid <= in_data_valid;
        end
    end

endmodule