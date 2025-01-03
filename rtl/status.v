

module status 
(
    // BRAM
    input clk, rstn,
    input [63:0] dout,
    output reg [31:0] din,
    output [1:0] addr,
    output wen,
    
    // PL side outputs
    output reg in_data_valid,
    input out_data_valid
);

assign addr = 0;
assign wen = 1;

reg prev_slv_reg0;
reg prev_in_data_valid;

always @( posedge clk )
begin
    if ( rstn == 1'b0 )
    begin
        din <= 0;
        in_data_valid <= 0;
        prev_in_data_valid <= 0;
    end 
    else begin
        din[0] <= out_data_valid;
        prev_slv_reg0 <= dout[63:32];
        in_data_valid <= dout[63:32] & (~prev_slv_reg0);
    end
end

// User logic ends

endmodule
