`timescale 1ns / 1ps

module cubic(
    input clk_i ,
    input rst_i ,
    input [7:0] x_bi ,
    input start_i ,
    output busy_o ,
    output reg [2:0] y_bo,
    
    input addsub_ready,
    input [7:0] addsub_res,
    output addsub_req,
    output reg addsub_mode,
    output reg [7:0] addsub_a,
    output reg [7:0] addsub_b
    
    /*test outs*/
//    output [7:0] b_out,
//    output [7:0] x_out,
//    output [2:0] m_out,
//    output [15:0] mult_out,
//    output mult_rst_out, mult_start_out, mult_busy_out, mult_done_out
    );
    
    localparam IDLE = 3'b000;
    localparam WORK = 3'b001;
    localparam WORK_BUSY = 3'b010;
    localparam DONE = 3'b011;
    localparam WAIT_SUB = 3'b100;
    localparam WAIT_ADD = 3'b101;
    localparam READY = 3'b110;
    
    localparam N = 4'h8;
    
    reg [7:0] x;
    reg [7:0] y;
    reg [2:0] m;
    reg [2:0] state;
    
//    wire [2:0] end_step;
    wire [7:0] b;
    wire [7:0] y2;
    
    wire [7:0] inc_mask = 1'b1;
    
    reg mult_start;
    wire mult_busy;
    wire [5:0] mult_y;
    wire [7:0] mult_res = mult_y[5:0];
    
    reg mult_done;
    
//    assign end_step = ( m == 0  && mult_done == 1) ;
//    assign busy_o = (state != 1'b0);
    assign busy_o = (state != IDLE);
    assign addsub_req = (state == WAIT_SUB || (state == WAIT_ADD));
    
    assign y2 = y << 1;
    
    mult mult_inst(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .a_bi(y2[2:0]), 
        .b_bi(y2[2:0]|inc_mask[2:0]), 
        .start_i(mult_start),
        .busy_o(mult_busy),
        .y_bo(mult_y));  
        
//    assign b = ((((mult_res << 1) + mult_res)|inc_mask) << m);
    reg [7:0] addsub_res_saved;
    assign b = (((addsub_res_saved)|inc_mask) << m);
    
    always @(posedge clk_i or negedge rst_i)
        if (!rst_i) begin
            m <= N - 2; //6
            x <= 0;
            y <= 0;
            y_bo <= 0;
            mult_start <= 0;
            mult_done <= 0;
            addsub_mode <= 0;
            addsub_a <= 0;
            addsub_b <= 0;
            addsub_res_saved <= 0;
            
            state <= IDLE;
        end else begin
            case (state)
                IDLE:
                    if(start_i) begin
                        state <= WORK_BUSY;
                        mult_start <= 1;
                        mult_done <= 0;
                        m <= N - 2; //6
                        x <= x_bi;
                        y <= 0;
                    end
                WORK:
                    begin
                        if(mult_done == 1) begin
                            if(x >= b) begin
                                addsub_mode <= 0;
                                addsub_a <= x;
                                addsub_b <= b;
                                state <= WAIT_SUB;
                                
                                y <= y2 | inc_mask;
                            end else begin
                                y <= y2;
                            end
                            
                            if(m == 0) begin
                                state <= DONE;
                            end else begin
                                if(m == 6) begin m <= 3; end
                                else if(m == 3) begin m <= 0; end
                                mult_done <= 0;
                            end
                        end
                        else begin
                            state <= WORK_BUSY;
                            mult_start <= 1;
                        end
                       
                    end
                 WORK_BUSY:
                    begin
                            if(mult_start == 1) begin
                                mult_start <= 0;
                            end else begin
                                if(mult_busy == 0) begin                                    
                                    addsub_mode <= 1;
                                    addsub_a <= mult_res << 1;
                                    addsub_b <= mult_res;
                                    state <= WAIT_ADD;
                                end
                            end
                    end
                WAIT_SUB:
                    if(addsub_ready == 1) begin
                        addsub_res_saved <= addsub_res;
                        x <= addsub_res;
                        state <= WORK;
                    end
                WAIT_ADD:
                    if(addsub_ready == 1) begin
                        addsub_res_saved <= addsub_res;
                        mult_done <= 1;
                        state <= WORK;
                    end
                 DONE:
                     begin
                        state <= READY;
                        y_bo <= y[2:0];
                     end
                 READY:
                    begin
                        state <= IDLE;
                    end
            endcase
        end
endmodule
