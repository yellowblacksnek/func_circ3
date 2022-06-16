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

module sr_alu
(
    input         clk_i,
    input         rst_n,
    input         start,
    input  [31:0] srcA,
    input  [31:0] srcB,
    input  [ 2:0] oper,
    output        zero,
    output        less, //BLT
    output reg [31:0] result,
    output        busy
);  
    wire multicycle = oper == `ALU_EXT;
    
    reg [1:0] sm_state;
    localparam IDLE = 2'b00 ;
    localparam WORK = 2'b01 ;
    localparam READY = 2'b10;
    localparam DONE = 2'b11;
    
//    wire start_ext = multicycle & sm_state == IDLE;
    assign busy = sm_state != IDLE;
    
    reg  [64:0] as_bus;
    wire [31:0] as_res;

    adder_subber as(
        .add( as_bus[64]   ),
        .a  ( as_bus[63:32] ),
        .b  ( as_bus[31:0]  ),
        .res( as_res       )
    );
    
    wire [16:0] sm_as_bus;
    
    always @ (*) begin
        case (oper)
            default:    begin
                as_bus[64] = 1;
                as_bus[63:32] = srcA;
                as_bus[31:0] = srcB;
                result = as_res;
            end
            `ALU_ADD  : begin
                as_bus[64] = 1;
                as_bus[63:32] = srcA;
                as_bus[31:0] = srcB;
                result = as_res;
            end
            `ALU_OR   : result = srcA | srcB;
            `ALU_SRL  : result = srcA >> srcB [4:0];
            `ALU_SLTU : result = (srcA < srcB) ? 1 : 0;
            `ALU_SUB : begin
                as_bus[64] = 0;
                as_bus[63:32] = srcA;
                as_bus[31:0] = srcB;
                result = as_res;
            end
            `ALU_EXT : begin
                as_bus[64] = sm_as_bus[16];
                as_bus[63:40] = 0;
                as_bus[39:32] = sm_as_bus[15:8];
                as_bus[31:8] = 0;
                as_bus[7:0] = sm_as_bus[7:0];
                result = as_res;
            end
        endcase
    end
    
    assign zero   = (result == 0);
    assign less = 
        (srcA[31] == srcB[31] ? (srcA < srcB) :
        (srcA[31] == 1 ? 1 : 0));
    
    wire [2:0] cbrt_a;
    wire [3:0] sqrt_b;
    wire cbrt_busy;
    wire sqrt_busy;
    wire both_done = sqrt_busy == 0 && cbrt_busy == 0;
    
    wire [16:0] res_sum_as;
    wire [16:0] cubic_as;
    wire [16:0] sqrt_as;
    
    wire [3:0] sm_as_req;
    wire [3:0] sm_as_ready;
    wire [1:0] sm_as_addr;
    
    assign sm_as_req[0] = both_done;
    assign sm_as_req[3] = 0;
    assign res_sum_as[16] = 1;
    assign res_sum_as[15:8] = cbrt_a;
    assign res_sum_as[7:0] = sqrt_b;
    
    initial begin sm_state <= IDLE; end
    
    always @(posedge clk_i) begin
        if(multicycle) begin
            case (sm_state)
                IDLE: if(start) sm_state <= WORK;
                WORK: begin
                        if(both_done) sm_state <= IDLE;
                      end
//                READY: sm_state <= IDLE;
            endcase
        end
    end
    
    ec4_2 ec(
        .d   ( sm_as_req  ),
        .out ( sm_as_addr ));
        
    dc2_4 dc(
        .i   ( sm_as_addr   ),
        .out ( sm_as_ready ));
        
    mux4_1 mux(
        .d0   ( res_sum_as  ),
        .d1   ( cubic_as    ),
        .d2   ( sqrt_as     ),
        .d3   ( {17{0}}     ),
        .addr ( sm_as_addr  ),
        .q    ( sm_as_bus   ));
        
    
    cubic cubic(
        .clk_i(clk_i),
        .rst_i(rst_n),
        .x_bi(srcA[7:0]), 
        .start_i(start),
        .busy_o(cbrt_busy),
        .y_bo(cbrt_a),
        
        .addsub_ready(sm_as_ready[1]),
        .addsub_res(as_res[7:0]),
        .addsub_req(sm_as_req[1]),
        .addsub_mode(cubic_as[16]),
        .addsub_a(cubic_as[15:8]),
        .addsub_b(cubic_as[7:0]));
        
    
    sqrt sqrt_inst(
        .clk_i(clk_i),
        .rst_i(rst_n),
        .x_bi(srcB[7:0]), 
        .start_i(start),
        .busy_o(sqrt_busy),
        .y_bo(sqrt_b),
        
        .addsub_ready(sm_as_ready[2]),
        .addsub_res(as_res[7:0]),
        .addsub_req(sm_as_req[2]),
        .addsub_mode(sqrt_as[16]),
        .addsub_a(sqrt_as[15:8]),
        .addsub_b(sqrt_as[7:0]));  
endmodule

module adder_subber
(   
    input             add,
    input      [31:0]  a,
    input      [31:0]  b,
    output reg [31:0]  res
);
    always @ (*) begin
        if (add == 1'b1) res = a + b;
        else             res = a - b;
    end
endmodule

module mux4_1
(
    input      [16:0] d0,
    input      [16:0] d1,
    input      [16:0] d2,
    input      [16:0] d3,
    input      [1:0]  addr,
    output reg [16:0] q
);
    always @* begin
        case(addr)
        2'b00: q = d0;
        2'b01: q = d1;
        2'b10: q = d2;
        2'b11: q = d3;
        endcase
    end
endmodule