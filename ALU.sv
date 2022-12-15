module ALU (
    input   core_package::alu_op_e      opcode_i,
    input   logic [31:0]                operand_A_i,
    input   logic [31:0]                operand_B_i,
    output  logic [31:0]                result_o
);
    import core_package::*;
    always_comb begin : calculation
        case (opcode_i)
            ALU_ADD:    result_o = operand_A_i + operand_B_i;
            ALU_SUB:    result_o = operand_A_i - operand_B_i;
            ALU_AND:    result_o = operand_A_i & operand_B_i;
            ALU_OR:     result_o = operand_A_i | operand_B_i;
            ALU_XOR:    result_o = operand_A_i ^ operand_B_i;
            ALU_SLT:    result_o = {31'b0, $signed(operand_A_i) < $signed(operand_B_i)};
            ALU_SLTU:   result_o = {31'b0, operand_A_i < operand_B_i};
            ALU_SLL:    result_o = operand_A_i << operand_B_i;
            ALU_SRL:    result_o = operand_A_i >> operand_B_i;
            ALU_SRA:    result_o = operand_A_i >>> operand_B_i;
            ALU_JALR:   begin
                            result_o = operand_A_i + operand_B_i;
                            result_o = {{result_o[31:1]}, 1'b0};
                        end
            ALU_EQ:     result_o = {31'b0, operand_A_i == operand_B_i};
            ALU_NE:     result_o = {31'b0, operand_A_i != operand_B_i};
            ALU_LT:     result_o = {31'b0, $signed(operand_A_i) < $signed(operand_B_i)};
            ALU_GE:     result_o = {31'b0, $signed(operand_A_i) >= $signed(operand_B_i)};
            ALU_LTU:    result_o = {31'b0, operand_A_i < operand_B_i};
            ALU_GEU:    result_o = {31'b0, operand_A_i >= operand_B_i};
            default: result_o = 32'hX;
        endcase
    end

endmodule