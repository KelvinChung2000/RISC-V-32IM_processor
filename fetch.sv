module fetch (
    input   logic           clk,
    input   logic           reset,
    input   logic           run,

    input   logic           branched_i,
    input   logic           stall,

    input   logic [31:0]    pc_i,
    output  logic [31:0]    pc_o,

    output  logic           fetch_vaild_o,

    input   logic [31:0]    pc_debug_i,
    input   logic           pc_wr_debug_i,
);

    logic [31:0] pc;
    logic [31:0] instr;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            pc <= 32'h0;
        end 
        else if (run) begin
            if (branched_i) begin
                pc <= pc_i;
            end else if (!stall) begin
                pc <= pc + 4;
            end else if (pc_wr_debug_i) begin
                pc <= pc_debug_i;
            end
        end
    end

    assign pc_o = pc;
    
endmodule