`define VENDOR_ID 32'h00000000
`define ARCH_ID   32'h00000000
`define IMPLEMENTATION_ID 32'h00000000
`define CONFIG_PTR 32'h00000000

module csrRegFile
(   
    input   logic                   clk,
    input   logic                   reset,
    input   core_package::csr_e     csr_addr, 
    input   logic [31:0]            csr_w_data,
    input   logic                   csr_w_en,
    output  logic [31:0]            csr_data_o,

    input   logic [31:0]            mhartid_i,
    input   logic                   m_external_interrupt_i,
    input   logic                   m_timer_interrupt_i,
    input   logic                   m_software_interrupt_i,

    output  logic                   global_m_interrupt_en_o,
    output  logic                   global_s_interrupt_en_o,

    //machine status
    output  logic [31:0]            mstatus_o,
    output  logic [31:0]            mstatush_o,
    output  logic [31:0]            misa_o,
    
    //exception and trap
    input   logic [31:0]            exception_pc_i,
    input   logic [31:0]            trap_cause_i,
    input   logic [31:0]            trap_val_i,
    output  logic [31:0]            trap_base_addr_o,
    output  logic [1:0]             trap_mode_o,
    output  logic [31:0]            medeleg_o,
    output  logic [31:0]            mideleg_o,

    //interrupt
    output  logic [31:0]            mie_o,
    output  logic [31:0]            mip_o,
    
    //performance counter
    input  logic                    cycle_i,
    input  logic                    instret_i,
    output logic                    cycle_en_o,
    output logic                    instret_en_o,
    output logic                    time_en_o
);
import core_package::*;

logic [31:0] misa_reg;
logic [63:0] mstatus_reg;
logic [31:0] medeleg_reg;
logic [31:0] mideleg_reg;
logic [31:0] mip_reg = 32'h00000000;
logic [31:0] mie_reg = 32'h00000000; 
logic [63:0] mcycle_reg = 64'h0;
logic [63:0] minstret_reg = 64'h0;
logic [31:0] mcounteren_reg = 32'h00000000;
logic [31:0] mcountinhibit_reg = 32'h00000000;
logic [31:0] mscratch_reg = 32'h00000000;
logic [31:0] mepc_reg;
logic [31:0] mcause_reg;
logic [31:0] mtval_reg = 32'h00000000;
logic [31:0] mtvec_reg = 32'h00000000;
logic [31:0] mtinst_reg = 32'h00000000;
logic [31:0] mtval2_reg = 32'h00000000;
logic [63:0] menvcfg_reg = 64'h0;
logic [63:0] mseccfg_reg = 64'h0;
logic [31:0] tselect_reg = 32'h00000000;
logic [31:0] tdata1_reg = 32'h00000000;
logic [31:0] tdata2_reg = 32'h00000000;
logic [31:0] tdata3_reg = 32'h00000000;
logic [31:0] mcontext_reg = 32'h00000000;
logic [31:0] dcsr_reg = 32'h00000000;
logic [31:0] dpc_reg = 32'h00000000;
logic [31:0] dscratch_reg = 32'h00000000;
logic [31:0] dscratch1_reg = 32'h00000000;


assign misa_reg =     (0                 <<  0)  // A - Atomic Instructions extension
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
                    | (32'b01            << 30); // M-XLEN (2'b01 = RV32)

assign global_m_interrupt_en_o = mstatus_reg[MIE];
assign global_s_interrupt_en_o = mstatus_reg[SIE];

assign cycle_en_o = mcounteren_reg[CY];
assign instret_en_o = mcounteren_reg[IR];
assign time_en_o = mcounteren_reg[TM];

assign mie_o = mie_reg;
assign mip_o = mip_reg;

assign mideleg_o = mideleg_reg;
assign medeleg_o = medeleg_reg;

assign trap_base_addr_o = {mtvec_reg[31:2], 2'b00};
assign trap_mode_o = mtvec_reg[1:0];

//performcance counter block
always_ff @(posedge clk)
begin
    if (reset)
    begin
        mcycle_reg <= 64'h0;
        minstret_reg <= 64'h0;
    end
    else
    begin
        if (!mcountinhibit_reg[CY])
            mcycle_reg <= mcycle_reg + 64'(cycle_i);
        if (!mcountinhibit_reg[IR])
            minstret_reg <= minstret_reg + 64'(instret_i);
    end
end

//read logic
always_comb
begin
    case (csr_addr)
        cycle:          csr_data_o = mcycle_reg[31:0];  
        utime:          csr_data_o = mcycle_reg[31:0];
        instret:        csr_data_o = minstret_reg[31:0];
        cycleh:         csr_data_o = mcycle_reg[63:32];
        timeh:          csr_data_o = mcycle_reg[63:32];
        instreth:       csr_data_o = minstret_reg[63:32];

        mvenderid:      csr_data_o = `VENDOR_ID;
        marchid:        csr_data_o = `ARCH_ID;
        mimpid:         csr_data_o = `IMPLEMENTATION_ID;
        mhartid:        csr_data_o = mhartid_i;
        mconfigptr:     csr_data_o = `CONFIG_PTR;

        mstatus:        csr_data_o = mstatus_reg[31:0];
        misa:           csr_data_o = misa_reg;
        medeleg:        csr_data_o = medeleg_reg;
        mideleg:        csr_data_o = mideleg_reg;
        mie:            csr_data_o = mie_reg;
        mtvec:          csr_data_o = mtvec_reg;
        mcounteren:     csr_data_o = mcounteren_reg;
        mstatush:       csr_data_o = mstatus_reg[63:32];

        mscratch:       csr_data_o = mscratch_reg;
        mepc:           csr_data_o = mepc_reg;
        mcause:         csr_data_o = mcause_reg;
        mtval:          csr_data_o = mtval_reg;
        mip:            csr_data_o = mip_reg;
        mtinst:         csr_data_o = mtinst_reg;
        mtval2:         csr_data_o = mtval2_reg;

        menvcfg:        csr_data_o = menvcfg_reg[31:0];
        menvcfgh:       csr_data_o = menvcfg_reg[63:32];
        mseccfg:        csr_data_o = mseccfg_reg[31:0];
        mseccfgh:       csr_data_o = mseccfg_reg[63:32];

        mcycle:         csr_data_o = mcycle_reg[31:0];
        minstret:       csr_data_o = minstret_reg[31:0];
        mcycleh:        csr_data_o = mcycle_reg[63:32]; 
        minstreth:      csr_data_o = minstret_reg[63:32];

        tselect:        csr_data_o = tselect_reg;
        tdata1:         csr_data_o = tdata1_reg;
        tdata2:         csr_data_o = tdata2_reg;
        tdata3:         csr_data_o = tdata3_reg;
        mcontext:       csr_data_o = mcontext_reg;

        dcsr:           csr_data_o = dcsr_reg;
        dpc:            csr_data_o = dpc_reg;
        dscratch:       csr_data_o = dscratch_reg;
        dscratch1:      csr_data_o = dscratch1_reg;
        default:        csr_data_o = 32'hX;
    endcase
end

//write logic
always_ff @(posedge clk)
begin
    if (csr_w_en)
    begin
        case (csr_addr)
            cycle:          mcycle_reg[31:0] <= csr_w_data;
            utime:          mcycle_reg[31:0] <= csr_w_data;
            instret:        minstret_reg[31:0] <= csr_w_data;
            cycleh:         mcycle_reg[63:32] <= csr_w_data;
            timeh:          mcycle_reg[63:32] <= csr_w_data;
            instreth:       minstret_reg[63:32] <= csr_w_data;

            mstatus:        mstatus_reg[31:0] <= csr_w_data;
            misa:           misa_reg <= csr_w_data;
            medeleg:        medeleg_reg <= csr_w_data;
            mideleg:        mideleg_reg <= csr_w_data;
            mie:            mie_reg <= csr_w_data;
            mtvec:          mtvec_reg <= csr_w_data;
            mcounteren:     mcounteren_reg <= csr_w_data;
            mstatush:       mstatus_reg[63:32] <= csr_w_data;
            
            mscratch:       mscratch_reg <= csr_w_data;
            mepc:           mepc_reg <= csr_w_data;
            mcause:         mcause_reg <= csr_w_data;
            mtval:          mtval_reg <= csr_w_data;
            mip:            mip_reg <= csr_w_data;
            mtinst:         mtinst_reg <= csr_w_data;

            menvcfg:        menvcfg_reg[31:0] <= csr_w_data;
            menvcfgh:       menvcfg_reg[63:32] <= csr_w_data;
            mseccfg:        mseccfg_reg[31:0] <= csr_w_data;
            mseccfgh:       mseccfg_reg[63:32] <= csr_w_data;

            mcycle:         mcycle_reg[31:0] <= csr_w_data;
            minstret:       minstret_reg[31:0] <= csr_w_data;
            mcycleh:        mcycle_reg[63:32] <= csr_w_data;
            minstreth:      minstret_reg[63:32] <= csr_w_data;

            tselect:        tselect_reg <= csr_w_data;
            tdata1:         tdata1_reg <= csr_w_data;
            tdata2:         tdata2_reg <= csr_w_data;
            tdata3:         tdata3_reg <= csr_w_data;
            mcontext:       mcontext_reg <= csr_w_data;

            dcsr:           dcsr_reg <= csr_w_data;
            dpc:            dpc_reg <= csr_w_data;
            dscratch:       dscratch_reg <= csr_w_data;
            dscratch1:      dscratch1_reg <= csr_w_data;
            default:        csr_data_o = 32'hX;
        endcase
    end
    else
    begin
        mepc_reg <= exception_pc_i & 32'hFFFFFFFE;
        mcause_reg <= trap_cause_i;
        mtval_reg <= trap_val_i;
        mip_reg[MEIP] <= m_external_interrupt_i;
        mip_reg[MTIP] <= m_timer_interrupt_i;
        mip_reg[MSIP] <= m_software_interrupt_i;
        if (reset) begin
            mstatus_reg[MPRV] <= 1'b0;
            mstatus_reg[MIE] <= 1'b0;
            mstatus_reg[MBE] <= 1'b0;
        end
        else
            mstatus_reg <= mstatus_reg;
    end
end

endmodule