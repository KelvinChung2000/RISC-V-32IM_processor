module fetch (
    input   logic           clk,
    input   logic           reset,
    input   logic           run,

    //pipeline control
    input   logic           next_ready_i,
    output  logic           self_ready_o,
    input   logic           prev_valid_i,
    output  logic           self_valid_o, 
    
    //control signals
    input   logic           stall_i,
    input   logic           branched_i,
    input   logic           pc_wr_debug_i,

    //unit functiion signals
    input   logic [31:0]    pc_i,
    output  logic [31:0]    pc_o,
    output  logic           fetch_en_o
);

    logic [31:0] pc = 32'h0;
    logic new_out;
    logic branched = 1'b0;
    logic valid;
    logic first_cycle = 1'b1;
    assign self_ready_o = !stall_i;
    assign fetch_en_o = (!stall_i && prev_valid_i && next_ready_i);
    assign pc_o = pc;
    assign new_out = branched_i || pc_wr_debug_i;
    assign valid = prev_valid_i && !stall_i && !new_out;
    
    //when notice branched need to redo fetch
    always_ff @(posedge clk) begin
        if (run) begin
            if (branched_i || pc_wr_debug_i) begin
                pc <= pc_i;
                branched <= 1'b1;
            end /* else if (first_cycle) begin
                pc <= pc;
                first_cycle <= 1'b0;
            end */ else if (!stall_i && next_ready_i && !branched) begin
                pc <= pc + 4;
            end else if (branched) begin
                pc <= pc;
                branched <= 1'b0;
            end
            self_valid_o <= valid;
        end
    end
    
endmodule