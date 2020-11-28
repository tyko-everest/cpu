`default_nettype none

`include "alu.v"
`include "cmp.v"
`include "regfile.v"
`include "ram.v"
`include "rom.v"

module cpu(
    input wire clk,
    // data bus connections
    output reg [15:0] dbus_addr, 
    output reg [31:0] dbus_write,
    input wire [31:0] dbus_read,
    output reg dbus_wen,
    // instruction bus connections
    output reg [15:0] ibus_addr,
    input wire [31:0] ibus_read
);

    localparam [31:0] NOP_INSTR = 32'h00000013;

    // used to tell the pc whether to branch and if so where to
    reg take_branch;
    reg [31:0] branch_addr;
    
    // represent the flow of instruction data along the pipeline
    reg [31:0] ir_exec, ir_wb;
    reg [31:0] pc_fetch, pc_exec;

    // break up the instruction into its components for the exec and wb stages
    wire [6:0] opcode_exec, opcode_wb, funct7;
    wire [4:0] rd, rs1, rs2;
    wire [2:0] funct3;
    wire [31:0] immI, immS, immB, immU, immJ;

    // used to select either regfile as input to alu and cmp unit
    // or if they need to be bypassed from a reg write that is yet to happen
    reg [31:0] s1, s2;

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

    initial pc_fetch = 0;

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
    always @(posedge clk) begin
        if (take_branch) begin
            pc_fetch <= branch_addr;
        end else begin
            pc_fetch <= pc_fetch + 4;
        end
    end

    // these are esentially just renamed internally
    always @(*) begin
        ir_exec <= ibus_read;
        ibus_addr <= pc_fetch;
    end

    // pass pc down the pipeline
    always @(posedge clk) begin
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
    // needed in LUI so imm directly passed through, i.e. adding to 0 
    always @(*) begin
        case (opcode_exec)
            7'b0110111: begin
                reg_s1sel <= 5'd0;
            end
            default: begin
                reg_s1sel <= rs1;
            end
        endcase
    end

    // decide if a bypass from the current write back stage is needed
    always @(*) begin
        if (reg_wen && (rs1 == rd)) begin
            s1 <= reg_d;
        end else begin
            s1 <= reg_s1;
        end
        if (reg_wen && (rs2 == rd)) begin
            s2 <= reg_d;
        end else begin
            s2 <= reg_s2;
        end
    end

    // functions handled by the alu
    always @(*) begin
        case (opcode_exec)
            // math reg
            7'b0110011: begin 
                alu_a <= s1;
                alu_b <= s2;
                // TODO likely a critical path, so far this tests the fastest
                if (funct3 == 3'b000) begin
                    // if (funct7[5]) begin
                    //     alu_mode <= 3'b010;
                    // end else begin
                    //     alu_mode <= funct3;
                    // end
                    alu_mode <= funct3 | {1'b0, funct7[5], 1'b0};
                end else if (funct3 == 3'b101) begin
                    if (funct7[5]) begin
                        alu_mode <= 3'b011;
                    end else begin
                        alu_mode <= funct3;
                    end
                    // alu_mode <= {~funct7[5], funct7[5], funct3[0]};
                end else begin
                    alu_mode <= funct3;
                end
            end
            // math imm
            7'b0010011: begin
                alu_a <= s1;
                alu_b <= immI;
                if (funct3 == 3'b101) begin
                    if (funct7[5]) begin
                        alu_mode <= 3'b011;
                    end else begin
                        alu_mode <= funct3;
                    end
                    // alu_mode <= {funct3[2:1] ^ {2{funct7[5]}}, funct3[0]};
                end else begin
                    alu_mode <= funct3;
                end
            end
            // loads
            7'b0000011: begin
                alu_a <= s1;
                alu_b <= immI;
                alu_mode <= 3'b000;
            end
            // stores
            7'b0100011: begin
                alu_a <= s1;
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
                alu_a <= s1;
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
            // 7'b1100111
            // default to ensure no latch generation
            default: begin
                alu_a <= s1;
                alu_b <= immI;
                alu_mode <= 3'b000;
            end
        endcase
    end

    // functions handled by the comparison unit
    always @(*) begin
        cmp_mode <= funct3;
        cmp_a <= s1;
        case (opcode_exec)
            // imm compares
            7'b0010011: begin
                cmp_b <= immI;
            end
            // branches and reg compares
            // only 7'b1100011, 7'b0110011, default ensures no latch generates
            default: begin
                cmp_b <= s2;
            end

        endcase
    end

    // decide if a branch or jump will be taken
    always @(*) begin
        case (opcode_exec)
            7'b1101111, 7'b1100111: begin
                take_branch <= 1;
            end
            7'b1100011: begin
                take_branch <= cmp_q;
            end
            default: begin
                take_branch <= 0;
            end
        endcase
        branch_addr <= alu_q;
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
    always @(*) begin
        // data line will only ever be from rs2
        dbus_write <= s2;
        // address from alu, result of rs1 + imm
        dbus_addr <= alu_q;

        // decide if this is a write or a read / nothing
        case (opcode_exec)
            7'b0100011: dbus_wen <= 1; 
            default: dbus_wen <= 0;
        endcase
    end

    // pass instruction down pipeline
    always @(posedge clk) begin
        ir_wb <= ir_exec;
    end


    /* WRITE BACK */
    always @(*) begin
        case (opcode_wb)
            7'b0010011, 7'b0110011, 7'b0110111, 7'b0010111: begin
                reg_wen <= 1;
                reg_d <= exec_out;
            end
            7'b0000011: begin
                reg_wen <= 1;
                reg_d <= dbus_read;
            end
            7'b1101111, 7'b1100111: begin
                reg_wen <= 1;
                // this will already have been incremented to the next instr
                reg_d <= pc_exec;
            end
            default: begin
                // need default reg_d output to avoid latch generation
                reg_d <= exec_out;
                reg_wen <= 0;
            end
        endcase
    end


endmodule