module registers
    (
        input  logic           clk,
        input  logic           reset,
        
        // control signals
        input  logic           stall_reg_rd,
        input  logic           stall_reg_wr,

        // unit function signals
        input  logic           rd_rs1_en,
        input  logic  [4:0]    rs1_address,
        output logic  [31:0]   rs1_data,

        input  logic           rd_rs2_en,
        input  logic [4:0]     rs2_address,
        output logic [31:0]    rs2_data,

        input  logic           wr_rd_en,
        input  logic [4:0]     rd_address,
        input  logic [31:0]    rd_data
    );

logic [31:0] registers [1:31];

always_ff @(posedge clk)
    begin
        if (!stall_reg_rd)
            begin
                if (rd_rs1_en)
                    if (rs1_address == 5'h00) 
                        rs1_data <= 32'h0000_0000;
                    else
                        // Forward incoming value
                        rs1_data <= (wr_rd_en && (rs1_address == rd_address)) ? rd_data : registers[rs1_address];
                else                  
                    rs1_data <= 32'hxxxx_xxxx;

                if (rd_rs2_en)
                    if (rs2_address == 5'h00) 
                        rs2_data <= 32'h0000_0000;
                    else
                        //Forward incoming value
                        rs2_data <= (wr_rd_en && (rs2_address == rd_address)) ? rd_data : registers[rs2_address]; 
                else                  
                    rs2_data <= 32'hxxxx_xxxx;
            end

        if (wr_rd_en && (rd_address != 5'h00)) registers[rd_address] <= rd_data;
        else                                   registers[rd_address] <= 32'h0;
    
    end

endmodule