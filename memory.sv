module memory (
    input logic clk,
    input logic rst,
    input core_package:: opcode_e opcode_i,
    input logic [31:0] data_i,
    output logic [31:0] data_o
);

logic [31:0] data;
import core_package::*;

always_comb begin : load_store_width
    case (opcode_i)
        OPCODE_LOAD:    unique case (param)
                            LB:     data_o = {24{data[7]},{data_i[7:0]}};
                            LH:     data_o = {16{data[15]},{data_i[15:0]}};
                            LW:     data_o = data_i;
                            LBU:    data_o = {24'b0,data_i[7:0]};
                            LHU:    data_o = {16'b0,data_i[15:0]};
                            default: data_o = 32'hX;
                        endcase
        OPCODE_STORE:   unique case (param)
                            SB:     data_o = {24'b0,data_i[7:0]};
                            SH:     data_o = {16'b0,data_i[15:0]};
                            SW:     data_o = data_i;
                            default: data_o = 32'hX;
                        endcase
        default: data_o <= 32'hX;
    endcase
end

always_ff @(posedge clk, posedge rst) begin

end

endmodule