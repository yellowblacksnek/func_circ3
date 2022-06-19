`timescale 1ns / 1ps

module cbrt_sqrt(
    input           clk_i,
    input           rst_i,
    input [7 : 0]   a_bi,
    input [7 : 0]   b_bi,
    input           start_i,
    input [7 : 0]   alu_res,
    output          done,
    output          alu_mode,
    output [7 : 0]  alu_a,
    output [7 : 0]  alu_b
);
    reg state;
    localparam IDLE = 1'b0 ;
    localparam WORK = 1'b1 ;
    
    wire start = start_i & state == IDLE;
    
    wire [3:0] addsub_req;
    wire [3:0] addsub_ready;
    wire [1:0] addsub_addr;

    wire [16:0] addsub_i0;
    wire [16:0] addsub_i1;
    wire [16:0] addsub_i2;
    
    wire [16:0] sm_as_bus;
    assign alu_mode = sm_as_bus[16];
    assign alu_a = sm_as_bus[15:8];
    assign alu_b = sm_as_bus[7:0];
    
    mux4_1 mux(
        .d0   ( addsub_i0  ),
        .d1   ( addsub_i1    ),
        .d2   ( addsub_i2     ),
        .d3   ( {17{0}}     ),
        .addr ( addsub_addr  ),
        .q    ( sm_as_bus   ));
        
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
        .start_i(start),
        .busy_o(cbrt_busy),
        .y_bo(cbrt_a),
        
        .addsub_ready(addsub_ready[1]),
        .addsub_res(alu_res),
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
        .start_i(start),
        .busy_o(sqrt_busy),
        .y_bo(sqrt_b),
        
        .addsub_ready(addsub_ready[2]),
        .addsub_res(alu_res),
        .addsub_req(addsub_req[2]),
        .addsub_mode(addsub_i2[16]),
        .addsub_a(addsub_i2[15:8]),
        .addsub_b(addsub_i2[7:0]));  
        
    wire both_done = sqrt_busy == 0 && cbrt_busy == 0;
    assign addsub_req[0] = both_done;
    assign addsub_req[3] = 0;
    assign addsub_i0[16] = 1;
    assign addsub_i0[15:8] = cbrt_a;
    assign addsub_i0[7:0] = sqrt_b;
    
    assign done = (state == WORK) & both_done;

    
    always @(posedge clk_i or negedge rst_i)
        if (!rst_i) state <= IDLE;
        else begin
            case (state)
                IDLE: if(start_i) state <= WORK;
                WORK: if(addsub_req[0]) state <= IDLE;
            endcase
        end
endmodule
