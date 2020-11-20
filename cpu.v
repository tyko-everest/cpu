`include "alu.v"
`include "cmp.v"
`include "pc_block.v"
`include "regfile.v"
`include "ram.v"
`include "rom.v"

module cpu(
    input wire clk
);

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

    // alu buses
    reg [31:0] alu_a, alu_b;
    wire [31:0] alu_q;
    reg [2:0] alu_mode;

    // cmp buses
    reg [31:0] cmp_a, cmp_b;
    wire cmp_q;
    reg [2:0] cmp_mode;

    // reg buses
    reg [31:0] reg_d;
    wire [31:0] reg_s1, reg_s2;
    // register selects always come straight from the machine code
    reg reg_wen;

    // rom buses
    wire [31:0] rom_out;
    reg [15:0] rom_addr;

    // ram buses
    reg [31:0] ram_in;
    wire [31:0] ram_out;
    reg [15:0] ram_addr;
    reg ram_wen;


    assign opcode = ir[6:0];
    assign rd = ir[11:7];
    assign rs1 = ir[19:15];
    assign rs2 = ir[24:20];
    assign funct3 = ir[14:12];
    assign funct7 = ir[31:25];

    assign immI = {{21{ir[31]}}, ir[30:20]};
    assign immS = {{21{ir[31]}}, ir[30:25], ir[11:7]};
    assign immB = {{20{ir[31]}}, ir[7], ir[30:25], ir[11:8], 1'b0};
    assign immU = {ir[31:12], 12'b0};
    assign immJ = {{12{ir[31]}}, ir[19:12], ir[20], ir[30:21], 1'b0};


    rom rom (
        .data(rom_out),
        .addr(rom_addr),
        .clk(clk)
    );
    
    ram ram (
        .out(ram_out),
        .in(ram_in),
        .addr(ram_addr),
        .wen(ram_wen),
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
        .mode(alu_mode)
    );

    cmp cmp (
        .a(cmp_a),
        .b(cmp_b),
        .q(cmp_q),
        .mode(cmp_mode)
    );

    // functions handled by the alu
    always @(*) begin
        case (opcode)
            // math reg
            7'b0110011: begin 
                alu_a <= reg_s1;
                alu_b <= reg_s2;
                // TODO maybe optimize some of these if elses into bitshifts
                // and masks, not sure how this all gets optimized
                if (funct3 == 3'b000) begin
                    if (funct7[5]) begin
                        alu_mode <= 3'b010;
                    end else begin
                        alu_mode <= funct3;
                    end
                end else if (funct3 == 3'b101) begin
                    if (funct7[5]) begin
                        alu_mode <= 3'b011;
                    end else begin
                        alu_mode <= funct3;
                    end
                end else begin
                    alu_mode <= funct3;
                end
            end
            // math imm
            7'b0010011: begin
                alu_a <= reg_s1;
                alu_b <= immI;
                if (funct3 == 3'b101) begin
                    if (funct7[5]) begin
                        alu_mode <= 3'b011;
                    end else begin
                        alu_mode <= funct3;
                    end
                end else begin
                    alu_mode <= funct3;
                end
            end
            // loads
            7'b0000011: begin
                alu_a <= reg_s1;
                alu_b <= immI;
                alu_mode <= 3'b000;
            end
            // stores
            7'b0100011: begin
                alu_a <= reg_s1;
                alu_b <= immS;
                alu_mode <= 3'b000;
            end
            // branches
            7'b1100011: begin
                alu_a <= pc;
                alu_b <= immB;
                alu_mode <= 3'b000;
            end
            // LUI
            7'b0110111: begin
                // TODO maybe make this from x0 instead
                alu_a <= 32'b0;
                alu_b <= immU;
                alu_mode <= 3'b000;
            end
            // AUIPC
            7'b0010111: begin
                alu_a <= pc;
                alu_b <= immU;
                alu_mode <= 3'b000;
            end
            // JAL
            7'b1101111: begin
                alu_a <= pc;
                alu_b <= immJ;
                alu_mode <= 3'b000;
            end
            // JALR
            7'b1100111: begin
                alu_a <= reg_s1;
                alu_b <= immI;
                alu_mode <= 3'b000;
            end
        endcase
    end

    // functions handled by the comparison unit
    always @(*) begin
        cmp_a <= reg_s1;
        case (opcode)
            // branches and reg compares
            7'b1100011, 7'b0110011: begin
                cmp_b <= reg_s2;
            end
            // imm compares
            7'b0010011: begin
                cmp_b <= immI;
            end
        endcase
    end


    /* MEM READ/WRITE */
    // TODO all instructions load/store word for now
    // TODO ony read when necessary
    always @(posedge clk) begin
        ram_addr <= alu_q;
        case (opcode)
            7'b0100011: begin
                ram_wen <= 1;
            end
            default: begin
                ram_wen <= 0;
            end
        endcase
    end


    /* WRITE BACK */
    always @(posedge clk) begin
        
    end


endmodule