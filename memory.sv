module memory (
    input   logic                   clk,
    input   logic                   reset,

    //pipeline control
    input   logic                   next_ready_i,
    output  logic                   self_ready_o,
    input   logic                   prev_valid_i,
    output  logic                   self_valid_o, 

    //control unit signal
    input   logic                   stall_i,

    //unit function signal
    input   logic                   mem_busy,   
    input   core_package::opcode_e  opcode_i,
    input   logic [2:0]             funct3_i,
    input   logic [31:0]            data_i,
    input   logic [31:0]            addr_i,
    output  logic [31:0]            data_o,

    //passing signal
    input   logic [4:0]             rd_i,
    output  logic [4:0]             rd_o
);

import core_package::*;
logic [31:0] data;
logic valid_o;

assign valid_o = !mem_busy;
always_comb begin : load_store_width
    case (opcode_i)
        OPCODE_LOAD:    unique case (funct3_i)
                            LB:         data = {{24{data_i[7]}},data_i[7:0]};
                            LH:         data = {{16{data_i[15]}},data_i[15:0]};
                            LW:         data = data_i;
                            LBU:        data = {24'b0,data_i[7:0]};
                            LHU:        data = {16'b0,data_i[15:0]};
                            default:    data = 32'hX;
                        endcase
        OPCODE_STORE:   unique case (funct3_i)
                            SB:         data = {24'b0,data_i[7:0]};
                            SH:         data = {16'b0,data_i[15:0]};
                            SW:         data = data_i;
                            default:    data = 32'hX;
                        endcase
        default: data = data_i;
    endcase
end

always_ff @(posedge clk, posedge reset) begin
    if (!mem_busy)
    begin
        data_o  <= data;
        rd_o    <= rd_i;
    end
end

endmodule