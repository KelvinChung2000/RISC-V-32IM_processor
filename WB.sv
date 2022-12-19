module WB (
    input   logic                   clk,
    input   logic                   reset,

    //pipeline control
    input   logic                   next_ready_i,
    output  logic                   self_ready_o,
    input   logic                   prev_valid_i,
    output  logic                   self_valid_o,

    //control unit signal
    input   logic                   stall_i,

    //unit function sigal 
    input   logic [4:0]             rd_addr_i,
    input   logic [31:0]            rd_data_i,
    output  logic                   rd_en,
    output  logic [4:0]             rd_addr_o,
    output  logic [31:0]            rd_data_o
);

logic valid_o;
logic self_ready;
logic self_valid;

assign valid_o = !stall_i && prev_valid_i && next_ready_i;
assign self_ready = !stall_i && prev_valid_i && next_ready_i;
assign self_valid = !stall_i && prev_valid_i && next_ready_i;

assign rd_addr_o = rd_addr_i;
assign rd_data_o = rd_data_i;

always_ff @(posedge clk ) begin : write_back
    if (reset) begin
        self_ready_o <= 1'b0;
        self_valid_o <= 1'b0;
        rd_en <= 1'b0;
    end 
    else if (valid_o) 
    begin
        rd_en <= 1'b1;
    end
    else
    begin
        rd_en <= 1'b0;
    end
end
    
endmodule