`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.04.2022 20:28:44
// Design Name: 
// Module Name: cbrt_sum_sqrt
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cbrt_sum_sqrt(
    input clk_i ,
    input rst_i ,
    input [ 7 : 0 ] a_bi ,
    input [ 7 : 0 ] b_bi ,
    input start_i ,
    output busy_o ,
    output reg [ 4 : 0 ] y_bo
    
//    output [3:0] addsub_req,
//    output [3:0] addsub_ready,
//    output [1:0] addsub_addr

);

//    assign addsub_req[3] = 0;
    
    reg [1:0] state;
    
    localparam IDLE = 2'b00 ;
    localparam WORK = 2'b01 ;
    localparam WAIT_ADD = 2'b10 ;
    localparam READY = 2'b11;
    
    assign busy_o = (state != IDLE);
    
//    reg [1:0] n;
    
    wire [3:0] addsub_req;
    wire [3:0] addsub_ready;
    wire [1:0] addsub_addr;

    wire [7:0] addsub_res;
    wire [16:0] addsub_i0;
    wire [16:0] addsub_i1;
    wire [16:0] addsub_i2;
    addsub addsub_inst(
        .i0(addsub_i0),
        .i1(addsub_i1),
        .i2(addsub_i2),
        .addr(addsub_addr),
        .out(addsub_res));
        
    ec4_2 ec(
        .d(addsub_req),
        .out(addsub_addr));
        
    dc2_4 dc(
        .i(addsub_addr),
        .out(addsub_ready));

    wire [2:0] cbrt_a;
    wire cbrt_busy;
    cubic cubic_inst(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .x_bi(a_bi), 
        .start_i(start_i),
        .busy_o(cbrt_busy),
        .y_bo(cbrt_a),
        
        .addsub_ready(addsub_ready[1]),
        .addsub_res(addsub_res),
        .addsub_req(addsub_req[1]),
        .addsub_mode(addsub_i1[16]),
        .addsub_a(addsub_i1[15:8]),
        .addsub_b(addsub_i1[7:0]));
        
    wire [3:0] sqrt_b;
    wire sqrt_busy;
    sqrt sqrt_inst(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .x_bi(b_bi), 
        .start_i(start_i),
        .busy_o(sqrt_busy),
        .y_bo(sqrt_b),
        
        .addsub_ready(addsub_ready[2]),
        .addsub_res(addsub_res),
        .addsub_req(addsub_req[2]),
        .addsub_mode(addsub_i2[16]),
        .addsub_a(addsub_i2[15:8]),
        .addsub_b(addsub_i2[7:0]));  
        
    assign addsub_req[0] = sqrt_busy == 0 && cbrt_busy == 0;
    assign addsub_req[3] = 0;
    assign addsub_i0[16] = 1;
    assign addsub_i0[15:8] = cbrt_a;
    assign addsub_i0[7:0] = sqrt_b;
    
    always @(posedge clk_i or negedge rst_i)
        if (!rst_i) begin
            y_bo <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE:
                    if(start_i) begin
                        state <= WORK;
//                        $display("start calc with %d %d",a_bi,b_bi);
                    end 
                WORK:
                    if(addsub_ready[0] && addsub_req[0]) begin // && addsub_req[0]
                        state <= WAIT_ADD;
                    end
                WAIT_ADD:
                    begin
                        y_bo <= addsub_res;
                        state <= READY;
                    end
                READY:
                    begin
//                        $display("BLOCK RES IS: %d", y_bo );
                        state <= IDLE;
                    end
            endcase
        end
endmodule
