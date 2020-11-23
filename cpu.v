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
    
    // represent the flow of instruction data along the pipeline
    reg [31:0] ir_exec, ir_wb;
    wire [31:0] pc_fetch;
    reg [31:0] pc_exec;

    // break up the instruction into its components for the exec stage
    wire [6:0] opcode_exec, opcode_wb, funct7;
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

    // execute output bus, used for input to buffer reg in write back
    reg [31:0] exec_out;

    // reg buses
    reg [31:0] reg_d;
    wire [31:0] reg_s1, reg_s2;
    reg [4:0] reg_s1sel;
    // rs2 selects always come straight from the machine code
    reg reg_wen;

    // rom buses
    wire [31:0] rom_out;
    reg [15:0] rom_addr;

    // ram buses
    reg [31:0] ram_in;
    wire [31:0] ram_out;
    reg [15:0] ram_addr;
    reg ram_wen;

    // these are used in the execution stage
    assign opcode_exec = ir_exec[6:0];
    assign rs1 = ir_exec[19:15];
    assign rs2 = ir_exec[24:20];
    assign funct3 = ir_exec[14:12];
    assign funct7 = ir_exec[31:25];

    // these are used in the write back phase
    assign opcode_wb = ir_wb[6:0];
    assign rd = ir_wb[11:7];

    // construct all possible immediates, only needed in execute
    assign immI = {{21{ir_exec[31]}}, ir_exec[30:20]};
    assign immS = {{21{ir_exec[31]}}, ir_exec[30:25], ir_exec[11:7]};
    assign immB = {{20{ir_exec[31]}}, ir_exec[7], ir_exec[30:25], ir_exec[11:8], 1'b0};
    assign immU = {ir_exec[31:12], 12'b0};
    assign immJ = {{12{ir_exec[31]}}, ir_exec[19:12], ir_exec[20], ir_exec[30:21], 1'b0};

    rom rom (
        .data(rom_out),
        .addr(pc_fetch[15:0]),
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
        .s1sel(reg_s1sel),
        .s2sel(rs2),
        .dsel(rd),
        .wen(reg_wen),
        .clk(clk)
    );


    /* FETCH */
    // increment or branch
    pc_block pc_block (
        .addr(branch_addr),
        .branch(take_branch),
        .clk(clk),
        .pc(pc_fetch)
    );

    always @(posedge clk) begin
        // get instruction from rom
        ir_exec <= rom_out;
        // pass address of instruction down pipeline
        pc_exec <= pc_fetch;
    end


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

    // decide whether rs1 is selected from opcode_exec or overriden to 0
    // needed in LUI so imm directly passed through by adding 0 
    always @(*) begin
        case (opcode_exec)
            7'b0110111: begin
                reg_s1sel <= 5'b00000;
            end
            default: begin
                reg_s1sel <= rs1;
            end
        endcase
    end

    // functions handled by the alu
    always @(*) begin
        case (opcode_exec)
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
                alu_a <= pc_exec;
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
                alu_a <= pc_exec;
                alu_b <= immU;
                alu_mode <= 3'b000;
            end
            // JAL
            7'b1101111: begin
                alu_a <= pc_exec;
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
        case (opcode_exec)
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

    // decide what to clock into the buffer register
    always @(posedge clk) begin
        casex (opcode_exec)
            7'b0?10011: begin
                casex (funct3)
                    3'b01?: exec_out <= cmp_q;
                    default: exec_out <= alu_q;
                endcase
            end
            default: begin
                exec_out <= alu_q;
            end
        endcase
    end

    // dealing with what to pass to ram
    always @(posedge clk) begin
        // data line will only ever be from rs2
        ram_in <= reg_s2;
        // address will only ever be from rs1
        ram_addr <= reg_s1;

        // decide if this is a write or a read / nothing
        case (opcode_exec)
            7'b0100011: ram_wen <= 1; 
            default: ram_wen <= 0;
        endcase
    end

    // pass instruction down pipeline
    always @(posedge clk) begin
        ir_wb <= ir_exec;
    end


    /* WRITE BACK */
    always @(posedge clk) begin
        case (opcode_wb)
            7'b0010011, 7'b0110011: begin
                reg_d <= alu_q;
            end
            7'b0000011: begin
                reg_d <= ram_out;
            end
        endcase
    end


endmodule