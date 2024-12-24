module fetch_store_unit #(
    ADDR_WIDTH = 10,
    DATA_WIDTH = 32,
    NUM_ELEMENTS = 4
)(
    input logic clk,
    input logic rstn,
    input logic [ADDR_WIDTH-1:0] addr_a,
    input logic [ADDR_WIDTH-1:0] addr_b,
    input logic [ADDR_WIDTH-1:0] addr_r,
    input logic wr_en,
    input logic [(DATA_WIDTH*NUM_ELEMENTS)-1:0] A, B, R,
    output logic [(DATA_WIDTH*NUM_ELEMENTS)-1:0] row_A, row_B, row_R

);

//Connect to Brams
    
endmodule