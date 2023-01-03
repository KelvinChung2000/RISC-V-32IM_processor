module csr
( 
    input   logic               clk,
    input   logic               reset,
    input   logic [2:0]         funct3,
    input   logic [4:0]         rd,
    input   logic [4:0]         rs1,
    input   logic [31:0]        rs1_data_i,
    input   core_package::csr_e csr_i,
    input   logic [31:0]        csr_data_i,

    output  logic [31:0]        new_csr_data_o,
    output  logic [31:0]        old_csr_data_o
);

import core_package::*;

logic [31:0] csr_data;
csr_e csr_addr;
logic [31:0] old_csr_data;

assign old_csr_data_o = old_csr_data;

always_comb begin : csr_instruction_handler
    unique case (funct3)
    CSRRW:  begin
                if (rd == 5'b0)
                    new_csr_data_o = 32'b0;
                else
                    new_csr_data_o = rs1_data_i;
            end
    CSRRS:  begin
                if (rs1_data_i == 32'b0 && rs1 != 5'b0) //if rs1_data is 0 then try write itself back
                    new_csr_data_o = csr_data_i;
                else
                    new_csr_data_o = csr_data_i | rs1_data_i;
            end
    CSRRC:  begin
                if (rs1_data_i == 32'b0 && rs1 != 5'b0) //if rs1_data is 0 then try write itself back
                    new_csr_data_o = csr_data_i;
                else
                    new_csr_data_o = csr_data_i & ~rs1_data_i;
            end
    CSRRWI: begin
                if (rd == 5'b0)
                    new_csr_data_o = 32'b0;
                else
                    new_csr_data_o = csr_data_i;
            end
    CSRRSI: begin
                if (rs1 != 5'b0) 
                    new_csr_data_o = csr_data_i | {27'b0, rs1};
                else
                    new_csr_data_o = csr_data_i;
            end
    CSRRCI: begin
                if (rs1 != 5'b0) 
                    new_csr_data_o = csr_data_i | {27'b0, rs1};
                else
                    new_csr_data_o = csr_data_i;
            end
    default:    begin
                    new_csr_data_o = 32'bX;
                end
    endcase 
end

always_ff @(posedge clk)
    begin
        old_csr_data <= csr_data_i;
    end

endmodule