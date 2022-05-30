/*
 * schoolRISCV - small RISC-V CPU 
 *
 * originally based on Sarah L. Harris MIPS CPU 
 *                   & schoolMIPS project
 * 
 * Copyright(c) 2017-2020 Stanislav Zhelnio 
 *                        Aleksandr Romanov 
 */ 

//hardware top level module
module sm_top
(
    input           clkIn,
    input           rst_n,
    input           uart_rx_r,
    input           romWrite_i,
    input   [ 3:0 ] clkDevide,
    input           clkEnable,
    output          clk,
    input   [ 4:0 ] regAddr,
    output  [31:0 ] regData,
    output          romWrite,
    
//    input [31:0] romAddr,
    output [31:0] romData
);
    //metastability input filters
    wire    [ 3:0 ] devide;
    wire            enable;
    wire    [ 4:0 ] addr;
    //wire            romWrite;
    

    sm_debouncer #(.SIZE(4)) f0(clkIn, clkDevide, devide);
    sm_debouncer #(.SIZE(1)) f1(clkIn, clkEnable, enable);
    sm_debouncer #(.SIZE(5)) f2(clkIn, regAddr,   addr  );
    
    sm_active_latch          f3(clkIn, rst_n, romWrite_i, romWrite);

    //cores
    //clock devider
    wire enable_and_nowrite = enable & !romWrite;
    wire clk_temp;
    sm_clk_divider sm_clk_divider
    (
        .clkIn      ( clkIn     ),
        .rst_n      ( rst_n     ),
        .devide     ( devide    ),
        .enable     ( enable_and_nowrite    ),
        .clkOut     ( clk       )
    );
//    assign clk = clk_temp & !romWrite;
    //UART receiver
    wire          uart_v;
    wire    [7:0] uart_d;
    uart_rx uart_rx
    (
        .i_Clock     ( clkIn     ),
        .i_Rx_Serial ( uart_rx_r ),
        .o_Rx_DV     ( uart_v    ),
        .o_Rx_Byte   ( uart_d    )
     );

    //instruction memory
    wire    [31:0]  imCpuAddr;
    wire    [31:0]  imCpuData;
    
    wire    [31:0]  imAddr;
    wire    [31:0]  imData;
//    wire            imRst;
    wire    [31:0]  imWriteAddr;
    wire    [31:0]  imWriteData;
    wire            imWe;
     
    assign imAddr = romWrite ? regAddr : imCpuAddr;
    assign romData = imData;
    
    rom_writer rom_writer
     (
        .clk    ( clkIn    ),
        .rstn   ( rst_n & !romWrite_i   ),
        .enable ( romWrite ),
        .uart_v ( uart_v   ),
        .uart_d ( uart_d   ),
        .im_wa ( imWriteAddr ),
        .im_wd ( imWriteData ),
        .im_we ( imWe      )
//        .im_rst( imRst     )    
     );
    
    sm_rom reset_rom
    (
         .clk       ( clkIn         ),
//         .imRst     ( imRst         ),
         .ra        ( imAddr ),
         .wa        ( imWriteAddr   ),
         .write_e   ( imWe      ),
         .wd        ( imWriteData   ),
         .rd        ( imData )
     );

    sr_cpu sm_cpu
    (
        .clk_in     ( clk         ),
        .enable     ( !romWrite   ),
        .rst_n      ( rst_n       ),
        .regAddr    ( addr        ),
        .regData    ( regData     ),
        .imAddr     ( imCpuAddr      ),
        .imData     ( imData      )
    );

endmodule

//metastability input debouncer module
module sm_debouncer
#(
    parameter SIZE = 1
)
(
    input                      clk,
    input      [ SIZE - 1 : 0] d,
    output reg [ SIZE - 1 : 0] q
);
    reg        [ SIZE - 1 : 0] data;

    always @ (posedge clk) begin
        data <= d;
        q    <= data;
    end

endmodule

module sm_active_latch
(
    input      clk,
    input     rstn,
    input        d,
    output reg   q
);
    initial q = 0;
    always @ (posedge clk or negedge rstn) begin
        if(!rstn)   begin q <= 0; end
        else        
            if(!q) begin q <= d; end
    end
endmodule

//tunable clock devider
module sm_clk_divider
#(
    parameter shift  = 16,
              bypass = 0
)
(
    input           clkIn,
    input           rst_n,
    input   [ 3:0 ] devide,
    input           enable,
    output          clkOut
);
    wire [31:0] cntr;
    wire [31:0] cntrNext = cntr + 1;
    sm_register_we r_cntr(clkIn, rst_n, enable, cntrNext, cntr);

    assign clkOut = bypass ? clkIn 
                           : cntr[shift + devide];
endmodule
