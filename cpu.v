`include "alu.v"
`include "cmp.v"
`include "pc_block.v"
`include "regfile.v"
`include "rom.v"
module cpu(
    input wire clk
);

    reg [31:0] mar, mdr;

    // used to tell the pc whether to branch and if so where to
    wire take_branch;
    reg [31:0] branch_addr;
    
    reg [31:0] ir;
    wire [31:0] pc;

    // break up the instruction into its components
    wire [6:0] opcode, funct7;
    wire [4:0] rd, rs1, rs2;
    wire [2:0] funct3;
    wire [31:0] immI, immS, immB, immU, immJ;

    assign opcode = ir[6:0];
    assign rd = ir[11:7];
    assign rs1 = ir[19:15];
    assign rs2 = ir[24:20];
    assign funct3 = ir[14:12];
    assign funct7 = ir[31:25];

    assign immI = {{21{ir[31]}}, ir[30:20]};
    assign immS = {{21{ir[31]}}, ir[30:25], ir[11:7]};
    assign immB = {{20{ir[31]}}, ir[7], ir[30:25], ir[11:8], 1'b0};
    assign immU = {{13{ir[31]}}, ir[30:12]};
    assign immJ = {{12{ir[31]}}, ir[19:12], ir[20], ir[30:21], 1'b0};


    // alu buses
    reg [31:0] alu_a, alu_b;
    reg [2:0] alu_funct3;
    wire [31:0] alu_q;
    // cmp buses
    wire cmp_q;
    // reg buses
    wire [31:0] reg_s1, reg_s2, reg_d;
    wire reg_wen;


    // eventually this will be outside the cpu
    wire [31:0] rom_out;
    rom rom (
        .q(rom_out),
        .a(pc[15:0]),
        .clk(clk)
    );


    regfile regfile (
        .d(reg_d),
        .s1(reg_s1),
        .s2(reg_s2),
        .s1sel(rs1),
        .s2sel(rs2),
        .dsel(rd),
        .wen(reg_wen),
        .clk(clk)
    );


    /* FETCH */
    // load ir
    always @(posedge clk) begin
        ir <= rom_out;
    end

    // increment or branch
    pc_block pc_block (
        .addr(branch_addr),
        .branch(take_branch),
        .clk(clk),
        .pc(pc)
    );


    /* EXECUTE */
    alu alu (
        .a(alu_a),
        .b(alu_b),
        .q(alu_q),
        .opcode(opcode),
        .funct3(alu_funct3),
        .funct7(funct7)
    );

    cmp cmp (
        .a(reg_s1),
        .b(reg_s2),
        .q(cmp_q),
        .mode(funct3)
    );

    // functions handled by the alu
    always @(*) begin
        case (opcode)
            // math reg
            7'b0110011: begin 
                alu_a <= reg_s1;
                alu_b <= reg_s2;
                alu_funct3 <= funct3;
            end
            // math imm and stores
            7'b0010011, 7'b0000011: begin
                alu_a <= reg_s1;
                alu_b <= immI;
                alu_funct3 <= funct3;
            end
            // loads
            7'b0100011: begin
                alu_a <= reg_s1;
                alu_b <= immS;
            end
            // branches
            7'b1100011: begin
                alu_a <= pc;
                alu_b <= immB;
            end
        endcase
    end

    // functions handled by the comparison unit (branches)
    always @(*) begin
        
    end


endmodule