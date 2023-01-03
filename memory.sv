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
    
    input   logic [31:0]            addr_i,
    input   logic [31:0]            ram_data_i,
    input   logic [31:0]            ex_data_i, 
    input   logic [31:0]            ex_rs2_data_i,
    output  logic [31:0]            addr_o,
    output  logic [31:0]            data_o,
    output  logic                   read_en,
    output  logic                   write_en,

    //passing signal
    input   logic [4:0]             rd_i,
    output  logic [4:0]             rd_o
);

import core_package::*;
logic [31:0] data;
logic valid;
logic prev_valid;

assign self_ready_o = next_ready_i && !stall_i && !mem_busy;

always_comb begin : load_store_width
    case (opcode_i)
        OPCODE_LOAD:    unique case (funct3_i)
                            LB:         data = {{24{ram_data_i[7]}},ram_data_i[7:0]};
                            LH:         data = {{16{ram_data_i[15]}},ram_data_i[15:0]};
                            LW:         data = ram_data_i;
                            LBU:        data = {24'b0,ram_data_i[7:0]};
                            LHU:        data = {16'b0,ram_data_i[15:0]};
                            default:    data = 32'hX;
                        endcase
        OPCODE_STORE:   unique case (funct3_i)
                            SB:         data = {24'b0,ex_rs2_data_i[7:0]};
                            SH:         data = {16'b0,ex_rs2_data_i[15:0]};
                            SW:         data = ex_rs2_data_i;
                            default:    data = 32'hX;
                        endcase
        default: data = ex_data_i;
    endcase
end

assign valid = !mem_busy && prev_valid_i;
always_ff @(posedge clk, posedge reset) begin
    self_valid_o <= valid;
    if (!mem_busy && next_ready_i)
    begin
        addr_o   <= addr_i;
        data_o   <= data;
        rd_o     <= rd_i;
        read_en  <= opcode_i == OPCODE_LOAD;
        write_en <= opcode_i == OPCODE_STORE;
    end
    else
    begin
        addr_o   <= addr_o;
        data_o   <= data_o;
        rd_o     <= rd_o;
        read_en  <= 1'b0;
        write_en <= 1'b0;
    end
end

endmodule