module top (
    input   logic           clk,
    input   logic           run,
    input   logic           reset,

    //debug interface
    input   logic           debug_en,

    //memory interface
    output  logic [31:0]    address_o,
    input   logic [31:0]    data_i,
    output  logic [31:0]    data_o,  

    //machine level interrupt
    input   logic           m_timer_interrupt_i,
    input   logic           m_external_interrupt_i,
    input   logic           m_software_interrupt_i,

    //supervisor level interrupt 
    input   logic           s_timer_interrupt_i,
    input   logic           s_external_interrupt_i,
    input   logic           s_software_interrupt_i
);
import core_package::*;

logic fetch_ready, decode_ready, execute_ready, memory_ready, WB_ready;
logic fetch_valid, decode_valid, execute_valid, memory_valid, WB_valid;
logic [31:0] pc_i, f_pc_o, ex_pc_o;
logic fetch_stall, decode_stall, execute_stall, memory_stall, WB_stall, reg_rd_stall, reg_wr_stall;
logic branched;
logic success_fetch;
machine_mode_e machine_mode;
logic [31:0] instr;
logic [31:0] misa, mstatus, mstatush, mie, mip;
opcode_e opcode;
alu_op_e alu_op;
inst_type_e inst_type;
logic illegal_instr;
logic [4:0] rd_addr, rs1_addr, rs2_addr;
logic [31:0] rd_data, rs1_data, rs2_data;
logic wr_rd_en, rd_rs1_en, rd_rs2_en;
logic [2:0] funct3;
logic [6:0] funct7;
logic [31:0] imm, csr, shamt, zimm;
logic [31:0] ex_result;
logic [31:0] mem_data_result;
logic [4:0] ex_rd, mem_rd;
logic [31:0] mem_result;
logic [31:0] wb_data;
logic [4:0] wb_addr;
csr_e csr_addr;
logic [31:0] csr_data;
logic csr_w_en;
logic [31:0] csr_data_o;
logic global_m_interrupt_en, global_s_interrupt_en;
logic [31:0] exception_pc, trap_cause, trap_val, trap_base_addr, medeleg;
logic [1:0] trap_mode; 
logic cycle, instret;

fetch u_fetch(
    .clk(clk),
    .reset(reset),    
    .run(run),

    //pipeline control
    .next_reday_i (decode_ready),
    .self_ready_o (fetch_ready),
    .prev_valid_i (1'b1),
    .self_valid_o (fetch_valid),

    //control unit signal
    .stall_i (fetch_stall),
    .branched_i (branched),

    //unit function signal 
    .pc_i (pc_i),
    .pc_o (f_pc_o),
    .success_fetch_o (success_fetch)
);

decode u_decode(
    .clk(clk),
    .reset(reset),

    //pipeline control
    .next_reday_i (execute_ready),
    .self_ready_o (decode_ready),
    .prev_valid_i (fetch_valid),
    .self_valid_o (decode_valid),

    //control unit signal
    .stall_i (decode_stall),

    //unit function signal
    .instr(instr),
    .machine_mode_i(machine_mode),
    .misa_i(misa),

    .opcode_o(opcode),
    .alu_op_o(alu_op),
    .inst_type_o(inst_type),
    .illegal_instr_o(illegal_instr),
    .rd_o(rd_addr),
    .rs1_o(rs1_addr),
    .rs2_o(rs2_addr),
    .funct3_o(funct3),
    .funct7_o(funct7),
    .imm_o(imm),
    .fenece_pred_o(),
    .fence_succ_o(),
    .csr_o(csr),
    .shamt_o(shamt),
    .zimm_o(zimm)
);

execute u_execute(
    .clk(clk),
    .reset(reset),

    .next_reday_i (memory_ready),
    .self_ready_o (execute_ready),
    .prev_valid_i (decode_valid),
    .self_valid_o (execute_valid),

    //control unit signal
    .stall_i (execute_stall),

    //unit function signal
    .opcode_i(opcode),
    .alu_op_i(alu_op),
    .inst_type_i(inst_type),
    .funct3_i(funct3),
    .funct7_i(funct7),
    .rs1_addr(rs1_addr),
    .rs1_i(rs1_data),
    .rs2_i(rs1_data),
    .imm_i(imm),
    .shamt_i(shamt),
    .zimm_i(zimm),
    .pc_i(pc_o),
    .csr_i(csr),
    .mepc_i(mepc),

    .pc_o(ex_pc_o),
    .result_o(ex_result),

    //csr signl
    .csr_data_i(csr_data_o),
    .csr_o(csr_addr),
    .csr_w_en_o(csr_w_en),

    //passing signal
    .rd_i(rd_addr),
    .rd_o(ex_rd)
);

memory u_memory( 
    .clk(clk),
    .reset(reset),

    //pipeline control
    .next_reday_i (WB_ready),
    .self_ready_o (memory_ready),
    .prev_valid_i (execute_valid),
    .self_valid_o (memory_valid),

    //control unit signal
    .stall_i (memory_stall),

    //unit function signal
    .mem_busy(),
    .opcode_i(opcode),
    .funct3_i(funct3),
    .addr_i(ex_result),
    .data_i(rs2_data),
    .data_o(mem_result),

    //passing signal
    .rd_i(ex_rd),
    .rd_o(mem_rd),
);

WB u_WB(
    .clk(clk),
    .reset(reset),

    //pipeline control
    .next_reday_i (1'b1),
    .self_ready_o (WB_ready),
    .prev_valid_i (memory_valid),
    .self_valid_o (WB_valid),

    //control unit signal
    .stall_i (WB_stall),

    //unit function signal
    .rd_addr_i(mem_rd),
    .rd_data_i(mem_result),
    .rd_en(wr_rd_en),
    .rd_addr_o(wb_addr),
    .rd_data_o(wb_data),
);

csrRegFile u_csrRegFile(
    .clk(clk),
    .reset(reset),
    .csr_addr(csr_addr),
    .csr_w_data(ex_result),
    .csr_w_en(csr_w_en),
    .csr_data_o(csr_data_o),

    .mhartid_i(),
    .m_external_interrupt_i(m_external_interrupt_i),
    .m_timer_interrupt_i(m_timer_interrupt_i),
    .m_software_interrupt_i(m_software_interrupt_i),

    .global_m_interrupt_en_o(global_m_interrupt_en),
    .global_s_interrupt_en_o(global_s_interrupt_en),

    .mstatus_o(mstatus),
    .mstatush_o(mstatush),  
    .misa_o(misa),

    .exception_pc_i(exception_pc),
    .trap_cause_i(trap_cause),
    .trap_val_i(trap_val),
    .trap_base_addr_o(trap_base_addr),
    .trap_mode_o(trap_mode),
    .medeleg_o(medeleg),

    .mie_o(mie),
    .mip_o(mip),

    .cycle_i(cycle),
    .instrest_i(instrest)
);

control u_control(
    .clk(clk),
    .reset(reset),

    .inst_type_i(inst_type),
    .branched_i(branched),
    .illegal_instr_i(illegal_instr),

    .mstatus(mstatus),
    .mstatush(mstatush),

    .new_pc_i(ex_pc_o),
    .pc_o(pc_o),
    
    .trap_base_addr_i(trap_base_addr),
    .trap_mode_i(trap_mode),
    .trap_cause_o(trap_cause),
    .trap_val_o(trap_val),

    .global_m_interrupt_en_i(global_m_interrupt_en),
    .mie_i(mie),
    .mip_i(mip),
    .mideleg_i(mideleg),

    .m_external_interrupt_i(m_external_interrupt_i),

    .fetch_stall(fetch_stall),
    .decode_stall(decode_stall),
    .execute_stall(execute_stall),
    .memory_stall(memory_stall),
    .WB_stall(WB_stall),
    .reg_rd_stall(reg_rd_stall),
    .reg_wr_stall(reg_wr_stall)
);

registrFile u_registrFile(
    .clk(clk),
    .reset(reset),

    // control unit signal
    .stall_reg_rd(stall_reg_rd),
    .stall_reg_wr(stall_reg_wr),
    
    //unit function signal
    .rd_rs1_en(rd_rs1_en),
    .rs1_address(rs1_addr),
    .rs1_data(rs1_data),
    .rd_rs2_en(rd_rs2_en),
    .rs2_address(rs2_addr),
    .rs2_data(rs2_data),
    .wr_rd_en(wr_rd_en),
    .rd_address(wb_addr),
    .rd_data(wb_data)
);

    
endmodule