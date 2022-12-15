module registers
    (
        input  logic           clk,
        input  logic           reset,

        input  logic           rd_rs1_en,
        input  logic  [4:0]    rs1_address,
        output logic  [31:0]   rs1_data,

        input  logic           rd_rs2_en,
        input  logic [4:0]     rs2_address,
        output logic [31:0]    rs2_data,

        input  logic           stall_reg_rd,
        input  logic           wr_rd_en,
        input  logic [4:0]     rd_adress,
        input  logic [31:0]    rd_data
    );

logic [31:0] registers [1:31];

always_ff (posedge clk)
    begin
        if (!stall_reg_rd)
            begin
                if (rd_rs1_en)
                    if (rs1_address == 5'h00) 
                        rs1 <= 32'h0000_0000;
                    else
                        // Forward incoming value
                        rs1_data <= (wr_rd && (rs1_address == rd_adress)) ? rd_data : registers[rs1_address];
                else                  
                    rs1 <= 32'hxxxx_xxxx;

                if (rd_rs2_en)
                    if (a_rs2 == 5'h00) 
                        rs2_data <= 32'h0000_0000;
                    else
                        //Forward incoming value
                        rs2_data <= (wr_rd_en && (rs2_address == rd_adress)) ? rd : registers[rs2_address]; 
                else                  
                    rs2 <= 32'hxxxx_xxxx;
            end

        if (wr_rd_en && (rd_adress != 5'h00)) registers[a_rd] <= rd;
        else                                  registers[a_rd] <= 32'h0;
    end

endmodule