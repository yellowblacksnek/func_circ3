/*
 * schoolRISCV - small RISC-V CPU 
 *
 * originally based on Sarah L. Harris MIPS CPU 
 *                   & schoolMIPS project
 * 
 * Copyright(c) 2017-2020 Stanislav Zhelnio 
 *                        Aleksandr Romanov 
 */ 

`include "sr_cpu.vh"

module sr_cpu
(
    input           clk_in,        // clock
    input           enable,     // enable
    input           rst_n,      // reset
    input   [ 4:0]  regAddr,    // debug access reg address
    output  [31:0]  regData,    // debug access reg data
    output  [31:0]  imAddr,     // instruction memory address
    input   [31:0]  imData     // instruction memory data
);

    wire clk = clk_in & enable;
    //control wires
    wire        aluZero;
    wire        aluLess; //BLT
    wire        pcSrc;
    wire        pcE; //multicycle
    wire        regWrite;
    wire        regWriteExt;
    wire        aluSrc;
    wire  [1:0] wdSrc; //multicycle
    wire  [2:0] aluControl;
    wire        aluBusy;

    //instruction decode wires
    wire [ 6:0] cmdOp;
    wire [ 4:0] rd;
    wire [ 2:0] cmdF3;
    wire [ 4:0] rs1;
    wire [ 4:0] rs2;
    wire [ 6:0] cmdF7;
    wire [31:0] immI;
    wire [31:0] immB;
    wire [31:0] immU;

    //program counter
    wire [31:0] pc;
    wire [31:0] pcBranch = pc + immB;
    wire [31:0] pcPlus4  = pc + 4;
    wire [31:0] pcNext   = pcSrc ? pcBranch : pcPlus4;
    sm_register_we r_pc(clk ,rst_n, pcE, pcNext, pc); //multicycle

    //program memory access
    assign imAddr = pc >> 2;
    wire [31:0] instr = imData;

    //instruction decode
    sr_decode id (
        .instr      ( instr        ),
        .cmdOp      ( cmdOp        ),
        .rd         ( rd           ),
        .cmdF3      ( cmdF3        ),
        .rs1        ( rs1          ),
        .rs2        ( rs2          ),
        .cmdF7      ( cmdF7        ),
        .immI       ( immI         ),
        .immB       ( immB         ),
        .immU       ( immU         ) 
    );

    //register file
    wire [31:0] rd0;
    wire [31:0] rd1;
    wire [31:0] rd2;
    wire [31:0] wd3;

    sm_register_file rf (
        .clk        ( clk          ),
        .a0         ( regAddr      ),
        .a1         ( rs1          ),
        .a2         ( rs2          ),
        .a3         ( rd           ),
        .rd0        ( rd0          ),
        .rd1        ( rd1          ),
        .rd2        ( rd2          ),
        .wd3        ( wd3          ),
        .we3        ( regWrite | regWriteExt )
    );

    //debug register access
    assign regData = (regAddr != 0) ? rd0 : imAddr;

    //alu
    wire [31:0] srcB = aluSrc ? immI : rd2;
    wire [31:0] aluResult;
    wire aluStart;

    sr_alu alu (
        .clk_i      ( clk          ),
        .rst_n      ( rst_n        ),
        .start      ( aluStart     ),
        .srcA       ( rd1          ),
        .srcB       ( srcB         ),
        .oper       ( aluControl   ),
        .zero       ( aluZero      ),
        .less       ( aluLess      ), //BLT
        .result     ( aluResult    ),
        .busy       ( aluBusy      )
    );
    
    //ext block
//    wire [31:0] extResult; 
//    assign extResult[31:5] = 27'b0;
//    wire       extReq;
//    wire       extBusy;
//    cbrt_sum_sqrt func_block (
//        .clk_i      ( clk            ),
//        .rst_i      ( rst_n          ),
//        .start_i    ( extReq         ),
//        .a_bi       ( rd1[7:0]       ),
//        .b_bi       ( rd2[7:0]      ),
//        .busy_o     ( extBusy        ),
//        .y_bo       ( extResult[4:0] )
//    );

    //assign wd3 = wdSrc == `WDSRC_IMMU ? immU : (wdSrc == `WDSRC_ALU ? aluResult : extResult);
    assign wd3 = wdSrc == `WDSRC_IMMU ? immU : aluResult;
    
    wire multicycle;
    //control
    sr_control sm_control (
        .cmdOp      ( cmdOp        ),
        .cmdF3      ( cmdF3        ),
        .cmdF7      ( cmdF7        ),
        .aluZero    ( aluZero      ),
        .aluLess    ( aluLess      ), //BLT
        .pcSrc      ( pcSrc        ),
        .regWrite   ( regWrite     ),
        .aluSrc     ( aluSrc       ),
        .wdSrc      ( wdSrc        ),
        .aluControl ( aluControl   ),
        .multicycle ( multicycle   )
    );   
    
    sm_control_multicycle sm_control_multicycle
    (
        .clk        ( clk          ),
        .rst_n      ( rst_n        ),
        .aluBusy    ( aluBusy      ),
        .aluStart   ( aluStart     ),
        .pcE        ( pcE          ),
        .multicycle ( multicycle   ),
        .regWrite   ( regWriteExt  )
    );

endmodule

module sr_decode
(
    input      [31:0] instr,
    output     [ 6:0] cmdOp,
    output     [ 4:0] rd,
    output     [ 2:0] cmdF3,
    output     [ 4:0] rs1,
    output     [ 4:0] rs2,
    output     [ 6:0] cmdF7,
    output reg [31:0] immI,
    output reg [31:0] immB,
    output reg [31:0] immU 
);
    assign cmdOp = instr[ 6: 0];
    assign rd    = instr[11: 7];
    assign cmdF3 = instr[14:12];
    assign rs1   = instr[19:15];
    assign rs2   = instr[24:20];
    assign cmdF7 = instr[31:25];

    // I-immediate
    always @ (*) begin
        immI[10: 0] = instr[30:20];
        immI[31:11] = { 21 {instr[31]} };
    end

    // B-immediate
    always @ (*) begin
        immB[    0] = 1'b0;
        immB[ 4: 1] = instr[11:8];
        immB[10: 5] = instr[30:25];
        immB[   11] = instr[7];
        immB[31:12] = { 20 {instr[31]} };
    end

    // U-immediate
    always @ (*) begin
        immU[11: 0] = 12'b0;
        immU[31:12] = instr[31:12];
    end

endmodule

module sr_control
(
//    input            clk,
//    input            rst_n,
    input     [ 6:0] cmdOp,
    input     [ 2:0] cmdF3,
    input     [ 6:0] cmdF7,
    input            aluZero,
    input            aluLess, //BLT
    output           pcSrc, 
    output reg       regWrite, 
    output reg       aluSrc,
    output reg [1:0] wdSrc,
    output reg [2:0] aluControl,
    output reg       multicycle
);    
    reg          branch;
    reg          condZero;
    reg          condLess;
    assign pcSrc = (branch & ((aluZero == condZero) & (aluLess == condLess)));
    
    always @ (*) begin
        branch      = 1'b0;
        condZero    = 1'b0;
        condLess    = 1'b0; //BLT
        regWrite    = 1'b0;
        aluSrc      = 1'b0;
        wdSrc       = `WDSRC_ALU;
        aluControl  = `ALU_ADD;
        multicycle  = 1'b0;

        casez( {cmdF7, cmdF3, cmdOp} )
            { `RVF7_ADD,  `RVF3_ADD,  `RVOP_ADD  } : begin regWrite = 1'b1; aluControl = `ALU_ADD;  end
            { `RVF7_OR,   `RVF3_OR,   `RVOP_OR   } : begin regWrite = 1'b1; aluControl = `ALU_OR;   end
            { `RVF7_SRL,  `RVF3_SRL,  `RVOP_SRL  } : begin regWrite = 1'b1; aluControl = `ALU_SRL;  end
            { `RVF7_SLTU, `RVF3_SLTU, `RVOP_SLTU } : begin regWrite = 1'b1; aluControl = `ALU_SLTU; end
            { `RVF7_SUB,  `RVF3_SUB,  `RVOP_SUB  } : begin regWrite = 1'b1; aluControl = `ALU_SUB;  end

            { `RVF7_ANY,  `RVF3_ADDI, `RVOP_ADDI } : begin regWrite = 1'b1; aluSrc = 1'b1; aluControl = `ALU_ADD; end
            { `RVF7_ANY,  `RVF3_ANY,  `RVOP_LUI  } : begin regWrite = 1'b1; wdSrc  = `WDSRC_IMMU; end

            { `RVF7_ANY,  `RVF3_BEQ,  `RVOP_BEQ  } : begin branch = 1'b1; condZero = 1'b1; aluControl = `ALU_SUB; end
            { `RVF7_ANY,  `RVF3_BNE,  `RVOP_BNE  } : begin branch = 1'b1; aluControl = `ALU_SUB; end
            { `RVF7_ANY,  `RVF3_BLT,  `RVOP_BLT  } : begin branch = 1'b1; condLess = 1'b1; aluControl = `ALU_SUB; end //BLT
            
            { `RVF7_MUL,  `RVF3_MUL,  `RVOP_MUL  } : begin multicycle  = 1'b1; aluControl  = `ALU_EXT; end

        endcase
    end
    
    
endmodule

module sm_control_multicycle
(
    input   clk,
    input   rst_n,
    input   multicycle,
    input   aluBusy,
    output  aluStart, 
    output  pcE,
    output  reg regWrite
);
    localparam MC_IDLE      = 2'b00;
    localparam MC_WORK_PREP = 2'b01;
    localparam MC_WORK      = 2'b10;
    localparam MC_DONE      = 2'b11;
    reg    [1:0] multicycle_state;
    
    assign pcE = !(multicycle & multicycle_state != MC_DONE);
    assign aluStart = multicycle & multicycle_state == MC_IDLE;
        
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            multicycle_state <= MC_IDLE;
            regWrite <= 0;
        end
        else begin
            case (multicycle_state)
                MC_IDLE: 
                    begin
                        if(multicycle) multicycle_state <= MC_WORK;
                    end      
                MC_WORK:
                    begin
                        if(!aluBusy) begin
                            multicycle_state <= MC_DONE;
                            regWrite <= 1;
                        end
                    end
                MC_DONE:
                    begin
                        multicycle_state <= MC_IDLE;
                        regWrite <= 0;
                    end
            endcase
        end
    end

endmodule

//module sr_alu
//(
//    input         clk_i,
//    input         rst_n,
//    input  [31:0] srcA,
//    input  [31:0] srcB,
//    input  [ 2:0] oper,
//    output        zero,
//    output        less, //BLT
//    output reg [31:0] result, //BLT (extra bit)
//    output reg    res_done
//);
//    wire [2:0] cbrt_a;
//    wire [3:0] sqrt_b;

//    reg start_ext;
//    reg [1:0] ext_state;
    
//    always @ (*) begin
//        case (oper)
//            default   : result = srcA + srcB;
//            `ALU_ADD  : result = srcA + srcB;
//            `ALU_OR   : result = srcA | srcB;
//            `ALU_SRL  : result = srcA >> srcB [4:0];
//            `ALU_SLTU : result = (srcA < srcB) ? 1 : 0;
//            `ALU_SUB : result = srcA - srcB;
//            `ALU_EXT : result = cbrt_a + sqrt_b;
//        endcase
//    end
    
//    always @(posedge clk_i) begin
//        if(oper == `ALU_EXT) begin
//            case (ext_state)
//                2'b00: begin
                
//                end
//            endcase
//        end
//    end
    
    

//    assign zero   = (result == 0);
//    assign less = 
//        (srcA[31] == srcB[31] ? (srcA < srcB) :
//        (srcA[31] == 1 ? 1 : 0));
        
//    wire cbrt_busy;
//    wire [16:0] cubic_as;
//    wire [7:0] cubic_as_res;
//    assign cubic_as_res = cubic_as[16] ? cubic_as[15:8] + cubic_as[7:0] : cubic_as[15:8] - cubic_as[7:0];
//    cubic cubic(
//        .clk_i(clk_i),
//        .rst_i(rst_n),
//        .x_bi(srcA), 
//        .start_i(start_ext),
//        .busy_o(cbrt_busy),
//        .y_bo(cbrt_a),
        
//        .addsub_ready(1'b1),
//        .addsub_res(cubic_as_res),
////        .addsub_req(addsub_req[1]),
//        .addsub_mode(cubic_as[16]),
//        .addsub_a(cubic_as[15:8]),
//        .addsub_b(cubic_as[7:0]));
        
//    wire sqrt_busy;
//    wire [16:0] sqrt_as;
//    wire [7:0] sqrt_as_res;
//    assign sqrt_as_res = sqrt_as[16] ? sqrt_as[15:8] + sqrt_as[7:0] : sqrt_as[15:8] - sqrt_as[7:0];
//    sqrt sqrt_inst(
//        .clk_i(clk_i),
//        .rst_i(rst_n),
//        .x_bi(srcB), 
//        .start_i(start_ext),
//        .busy_o(sqrt_busy),
//        .y_bo(sqrt_b),
        
//        .addsub_ready(1'b1),
//        .addsub_res(sqrt_as_res),
////        .addsub_req(addsub_req[2]),
//        .addsub_mode(sqrt_as[16]),
//        .addsub_a(sqrt_as[15:8]),
//        .addsub_b(sqrt_as[7:0]));  
//endmodule

module sm_register_file
(
    input         clk,
    input  [ 4:0] a0,
    input  [ 4:0] a1,
    input  [ 4:0] a2,
    input  [ 4:0] a3,
    output [31:0] rd0,
    output [31:0] rd1,
    output [31:0] rd2,
    input  [31:0] wd3,
    input         we3
);
    reg [31:0] rf [31:0];

    assign rd0 = (a0 != 0) ? rf [a0] : 32'b0;
    assign rd1 = (a1 != 0) ? rf [a1] : 32'b0;
    assign rd2 = (a2 != 0) ? rf [a2] : 32'b0;

    always @ (posedge clk)
        if(we3) rf [a3] <= wd3;
endmodule
