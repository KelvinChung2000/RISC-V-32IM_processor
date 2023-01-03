module execute (
    input   logic                       clk,
    input   logic                       reset,
    
    //pipeline control
    input   logic                       next_ready_i,
    output  logic                       self_ready_o,
    input   logic                       prev_valid_i,
    output  logic                       self_valid_o, 
    
    //control unit signal
    input   logic                       stall_i,

    //unit function signal
    input   core_package::opcode_e      opcode_i,
    input   core_package::alu_op_e      alu_op_i,
    input   core_package::instr_type_e  instr_type_i,
    input   logic [2:0]                 funct3_i,
    input   logic [6:0]                 funct7_i,
    input   logic [31:0]                rs1_i,
    input   logic [31:0]                rs2_i,
    input   logic [31:0]                imm_i,
    input   logic [31:0]                shamt_i,
    input   logic [31:0]                zimm_i,
    input   logic [31:0]                pc_i,
    input   core_package::csr_e         csr_i,
    input   logic [31:0]                mepc_i,
    input   logic [4:0]                 rd_i,
    input   logic [4:0]                 rs1_addr,  

    output  logic [31:0]                result_o,
    output  logic [31:0]                pc_o,
    output  logic                       branched_o,
    output  logic [31:0]                rs2_data_o,

    //forwarding signal
    input   logic                       fwd_en_rs1_i,
    input   logic [31:0]                fwd_data_rs1_i,
    input   logic                       fwd_en_rs2_i,
    input   logic [31:0]                fwd_data_rs2_i,

    //csr signal
    input   logic [31:0]                csr_data_i,
    output  logic                       csr_w_en_o,

    //passing signal
    output  logic [4:0]                 rd_o                        
);
    import core_package::*;
    logic [31:0] operand_A;
    logic [31:0] operand_B;
    logic [31:0] result;
    logic [31:0] old_csr;
    logic [31:0] csr_result;
    logic [31:0] brench_save;
    logic [31:0] pc;
    logic valid;
    logic [4:0] rd;
    logic prev_valid;
    logic [31:0] result_save;
    

    assign self_ready_o = next_ready_i;
    assign rd = rd_i;

    always_comb begin : opreand_selection
        case (instr_type_i)
            INSTR_TYPE_R: begin
                operand_A = (fwd_en_rs1_i) ? fwd_data_rs1_i : rs1_i;
                operand_B = (fwd_en_rs2_i) ? fwd_data_rs2_i : rs2_i;
            end
            INSTR_TYPE_I: begin
                operand_A = (fwd_en_rs1_i) ? fwd_data_rs1_i : rs1_i;
                operand_B = (funct3_i == SLLI || funct3_i == SR_LA_I) ? shamt_i : imm_i;
            end
            INSTR_TYPE_S: begin
                operand_A = (fwd_en_rs1_i) ? fwd_data_rs1_i : rs1_i;
                operand_B = imm_i;
            end
            INSTR_TYPE_B: begin
                operand_A = (fwd_en_rs1_i) ? fwd_data_rs1_i : rs1_i;
                operand_B = (fwd_en_rs2_i) ? fwd_data_rs2_i : rs2_i;
            end
            INSTR_TYPE_U: begin
                operand_A = (opcode_i == OPCODE_AUIPC) ? pc_i : 32'b0;
                operand_B = imm_i;
            end
            INSTR_TYPE_J: begin
                operand_A = (fwd_en_rs1_i) ? fwd_data_rs1_i : rs1_i;
                operand_B = imm_i;
            end
            INSTR_TYPE_SYSTEM: begin
                operand_A = (funct3_i == CSRRW || funct3_i == CSRRS || funct3_i == CSRRC) ?
                            (fwd_en_rs1_i) ? fwd_data_rs1_i : rs1_i : zimm_i;
                operand_B = 32'b0;
            end
            default: begin
                operand_A = 32'bX;
                operand_B = 32'bX;
            end
        endcase
    end
      
    always_comb begin : pc_cal
        unique case (instr_type_i)
            INSTR_TYPE_B:       begin 
                                    pc = (result == 32'b1) ? pc_i + imm_i : pc_i; 
                                    branched_o = (result == 32'b1);
                                end
            INSTR_TYPE_J:       begin 
                                    pc = result; 
                                    brench_save = pc_i + 32'd4; 
                                    branched_o = 1'b1;
                                end
            INSTR_TYPE_I:       begin 
                                    if (opcode_i == OPCODE_JALR)
                                    begin
                                        pc = result; 
                                        brench_save = pc_i + 32'd4; 
                                        branched_o = 1'b1;
                                    end
                                end
            INSTR_TYPE_SYSTEM:  begin 
                                    if (csr_i == SM_RET) 
                                    begin
                                        pc = mepc_i; 
                                        branched_o = 1'b1;
                                    end
                                end
            default: pc = pc_i;
        endcase
    end

    ALU ALU(
        .opcode_i(alu_op_i),
        .operand_A_i(operand_A),
        .operand_B_i(operand_B),
        .result_o(result)
    );

    csr csr(
        .clk(clk),
        .reset(reset),

        .funct3(funct3_i),
        .rd(rd_i),
        .rs1(rs1_addr),
        .rs1_data_i(rs1_i),
        .csr_i(csr_i),
        .csr_data_i(csr_data_i),

        .new_csr_data_o(csr_result),
        .old_csr_data_o(old_csr)
    );

    assign valid = prev_valid_i && !stall_i;

    always_ff @(posedge clk, posedge reset)
        begin
            if (reset) begin
                result_o <= 32'b0;
                pc_o <= 32'b0;
            end
            else
                begin
                    pc_o <= pc;
                    self_valid_o <= valid;
                    if (valid && next_ready_i)
                    begin
                        result_o <= ((instr_type_i == INSTR_TYPE_I && opcode_i == OPCODE_JALR) || 
                                     instr_type_i == INSTR_TYPE_J)      ?   brench_save :
                                    (instr_type_i == INSTR_TYPE_SYSTEM) ?   old_csr : 
                                                                            result;
                        rd_o <= rd;
                        csr_w_en_o <= (instr_type_i == INSTR_TYPE_SYSTEM);
                    end
                    else
                    begin
                        result_o <= result_o;
                        rd_o <= rd_o;
                        csr_w_en_o <= csr_w_en_o;
                    end
                end
        end

endmodule