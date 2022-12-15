`define VENDOR_ID 32'h00000000
`define ARCH_ID   32'h00000000
`define IMPLEMENTATION_ID 32'h00000000

module csrRegFile
(   
    input   logic                   clk,
    input   logic                   reset,
    input   core_package::csr_e     csr_addr, 
    input   logic [31:0]            csr_w_data,
    input   logic                   csr_w_en,
    output  logic [31:0]            csr_data_o,

    input   logic [31:0]            mhartid_i,
    input   logic                   external_interrupt_i,
    input   logic                   timer_interrupt_i,
    input   logic                   software_interrupt_i,

    output  logic                   global_m_interrupt_en_o,
    output  logic                   global_s_interrupt_en_o,

    
    input   logic [31:0]            exception_pc_i,
    input   logic [31:0]            trap_casue_i,
    input   logic [31:0]            trap_val_i,
    
    //exception and trap
    input   logic                   exception_pc_i,
    output  logic [31:0]            trap_base_addr_o,
    output  logic [1:0]             trap_mode_o,
    output  logic [31:0]            mscratch_o,
    output  logic [31:0]            exception_pc_o,
    output  logic [31:0]            trap_cause_o,
    output  logic [31:0]            trap_val_o,
    output  logic [31:0]            medeleg_o,

    //interrupt
    output  logic [31:0]            mie_o,
    output  logic [31:0]            mip_o,
    output  logic [31:0]            mideleg_o,     
    
    //performance counter
    input  logic                    cycle_i,
    input  logic                    instret_i, 

);
import core_package::*;

logic [31:0] misa;
logic [31:0] mstatus;
logic [31:0] mstatush;
logic [31:0] medeleg;
logic [31:0] mideleg;
logic [31:0] mip = 32'h00000000;
logic [31:0] mie = 32'h00000000; 
logic [31:0] mcycle = 32'h00000000;
logic [31:0] minstret = 32'h00000000;
logic [31:0] mcounteren = 32'h00000000;
logic [31:0] mcountinhibit = 32'h00000000;
logic [31:0] mscratch = 32'h00000000;
logic [31:0] mepc = 32'h00000000;
logic [31:0] mcause = 32'h00000000;
logic [31:0] mtval = 32'h00000000;

assign misa =     (0                 <<  0)  // A - Atomic Instructions extension
                | (0                 <<  1)  // B - Bit-Manipulation extension
                | (1                 <<  2)  // C - Compressed extension
                | (0                 <<  3)  // D - Double precision floating-point extension
                | (0                 <<  4)  // E - RV32E base ISA
                | (0                 <<  5)  // F - Single precision floating-point extension
                | (1                 <<  8)  // I - RV32I/64I/128I base ISA
                | (0                 << 12)  // M - Integer Multiply/Divide extension
                | (0                 << 13)  // N - User level interrupts supported
                | (0                 << 18)  // S - Supervisor mode implemented
                | (1                 << 20)  // U - User mode implemented
                | (0                 << 23)  // X - Non-standard extensions present
                | (2'b01             << 30); // M-XLEN (2'b01 = RV32)

assign global_m_interrupt_en_o = mstatus[MIE];
assign global_s_interrupt_en_o = mstatus[SIE];
assign mips[MEIP] = external_interrupt_i;
assign mips[MTIP] = timer_interrupt_i;
assign mips[MSIP] = software_interrupt_i;
assign cycle_en = mcounteren[CY];
assign instret_en = mcounteren[IR];
assign time_en = mcounteren[TM];
assign mscratch_o = mscratch;
assign mepc = exception_pc_i;
assign exception_pc_o = mepc & 32'hFFFFFFFE;
assign trap_cause_o = mcause;
assign mtval = trap_val_i;
assign trap_val_o = mtval;
assign mie_o = mie;
assign mip_o = mip;
assign mideleg_o = mideleg;
assign medeleg_o = medeleg;
assign trap_base_addr_o = {mtvec[31:2], 2'b00};
assign trap_mode_o = mtvec[1:0];

//performcance counter block
always_ff @(posedge clk)
begin
    if (reset)
    begin
        mcycle <= 32'h00000000;
        minstret <= 32'h00000000;
    end
    else
    begin
        if (!mcountinhibit[CY])
            mcycle <= mcycle + cycle_i;
        if (!mcountinhibit[IR])
            minstret <= minstret + instret_i;
    end
end

//machine mode setting and reset block
always_ff @(posedge reset)
begin
    mstatus[MPRV] = 1'b0;
    mstatus[MIE] = 1'b0;
    mstatus[MBE] = 1'b0;
end

//read logic
always_comb
begin
    case (csr_addr)
        CSR_MISA:       csr_data_o = misa;
        CSR_MVENDORID:  csr_data_o = `VENDOR_ID;
        CSR_MARCHID:    csr_data_o = `ARCH_ID;
        CSR_MIMPLID:    csr_data_o = `IMPLEMENTATION_ID;
        CSR_MHARTID:    csr_data_o = mhartid_i;
        CSR_MSTATUS:    csr_data_o = mstatus;
        CSR_MSTATUSH:   csr_data_o = mstatush;
        CSR_MEDELEG:    csr_data_o = medeleg;
        CSR_MIDELEG:    csr_data_o = mideleg;
        CSR_MIP:        csr_data_o = mip;
        CSR_MIE:        csr_data_o = mie;
        CSR_MCYCLE:     csr_data_o = mcycle;
        CSR_MINSTRET:   csr_data_o = minstret;
        default:        csr_data_o = 32'hX;
    endcase
end

endmodule