module execute (
    input   logic                       clk,
    input   logic                       reset,
    input   logic                       flush_i,
    input   logic                       stall_i,
    input   logic                       valid_i,
    input   logic                       next_ready_i,
    output  logic                       valid_o,
    output  logic                       ready_o,

    input   core_package::alu_op_e      alu_op_i,
    input   core_package::opcode_e      opcode_i,
    input   core_package::inst_type_e   inst_type_i,
    input   logic [2:0]                 funct3_i,
    input   logic [6:0]                 funct7_i,
    input   logic [31:0]                rs1_i,
    input   logic [31:0]                rs2_i,
    input   logic [31:0]                imm_i,
    input   logic [31:0]                pc_i,
    input   core_package::csr_e         csr_i,
    output  logic [31:0]                ALU_result_o,
    output  logic [31:0]                pc_o
    input   logic [31:0]                mepc, 

    output  core_package::csr_e         csr_o,
    output  logic[31:0]                 new_csr_data_o,
    output  
);
    import core_package::*;
    logic [31:0] operand_A;
    logic [31:0] operand_B;
    logic [31:0] result;
    logic [31:0] brench_save;
    logic [31:0] pc;
     
    always_comb begin : opreand_selection
        case (inst_type_i)
            INST_TYPE_R: begin
                operand_A = rs1_i;
                operand_B = rs2_i;
            end
            INST_TYPE_I: begin
                operand_A = rs1_i;
                operand_B = imm_i;
            end
            INST_TYPE_S: begin
                operand_A = rs1_i;
                operand_B = imm_i;
            end
            INST_TYPE_B: begin
                operand_A = rs1_i;
                operand_B = rs2_i;
            end
            INST_TYPE_U: begin
                operand_A = (opcode_i == OPCODE_AUIPC) ? pc_i : 32'b0;
                operand_B = imm_i;
            end
            INST_TYPE_J: begin
                operand_A = rs1_i;
                operand_B = imm_i;
            end
            INST_TYPE_SYSTEM: begin
                operand_A = 32'b0;
                operand_B = 32'b0;
            end
            default: begin
                operand_A = 32'bX;
                operand_B = 32'bX;
            end
        endcase
    end
      
    always_comb begin : pc_cal
        unique case (inst_type_i)
            INST_TYPE_B: pc = (result == 32'b1) ? pc_i + imm_i : pc_i;
            INST_TYPE_J: begin pc = result; brench_save = pc_i + 32'd4; end
            INST_TYPE_I: begin pc = result; brench_save = pc_i + 32'd4; end
            INST_TYPE_SYSTEM: begin if (csr_i == SRET || csr_i == MRET) pc = mepc; end
            default: pc = pc_i;
        endcase
    end

    ALU ALU(
        .opcode_i(alu_op_i),
        .operand_A_i(operand_A),
        .operand_B_i(operand_B),
        .result_o(result)
    );

    CSR CSR(

    );

    always_ff @(posedge clk, posedge reset)
        begin
            if (reset) begin
                ALU_result_o <= 32'b0;
                pc_o <= 32'b0;
            end
            else
                begin
                    pc_o <= pc;
                    valid_o <= !flush_i && !stall_i;
                    if (next_ready_i)
                        ALU_result_o <= (inst_type_i == INST_TYPE_I || 
                                         inst_type_i == INST_TYPE_J) ? brench_save : result;
                    else
                        ALU_result_o <= ALU_result_o;
                end
        end

endmodule