module program_counter #(
    parameter ADDR_WIDTH = 10
)(
    input logic clk,     
    input logic rst,
    input logic half_clk,
    output logic [ADDR_WIDTH-1:0] ins_addr //To instruction mem
);

   always @(posedge clk) begin
        if (!rst)
            ins_addr <= 32'b0;
        else if (half_clk) begin
            ins_addr <= ins_addr + 1; 
        end
	end

endmodule
