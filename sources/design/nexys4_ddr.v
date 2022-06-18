
module nexys4_ddr
(
    input         CLK100MHZ,
    input         CPU_RESETN,

    input         BTNC,
    input         BTNU,
    input         BTNL,
    input         BTNR,
    input         BTND,

    input  [15:0] SW, 

    output [15:0] LED,

    output        LED16_B,
    output        LED16_G,
    output        LED16_R,
//    output        LED17_B,
//    output        LED17_G,
//    output        LED17_R,

    output        CA,
    output        CB,
    output        CC,
    output        CD,
    output        CE,
    output        CF,
    output        CG,
    output        DP,

    output [ 7:0] AN,

//    inout  [12:1] JA,
//    inout  [12:1] JB,

    input         UART_TXD_IN
);

    // wires & inputs
    wire          clk;
    wire          clkIn     =  CLK100MHZ;
    wire          rst_n     =  CPU_RESETN;
    wire          romWrite  =  BTNR;
    wire          resetMem  =  BTNC;
    wire          uart_in =  UART_TXD_IN;
    wire          clkEnable =  SW [15] | BTNU;
    wire [  3:0 ] clkDevide =  SW [14:11];
    wire [  4:0 ] regAddr   =  SW [4:0];
    wire [ 10:0 ] romAddr   =  SW [10:0];
    
    wire [ 31:0 ] regData;
    wire [ 31:0 ] romData;
    
    wire romWriteLatched;
    wire resetMemBusy;

    //cores
    sm_top sm_top
    (
        .clkIn      ( clkIn     ),
        .rst_n      ( rst_n     ),
        .uart_in    ( uart_in   ),
        .romWrite_i ( romWrite  ),
        .romWrite   ( romWriteLatched),
        .resetMem   ( resetMem  ),
        .resetMemBusy( resetMemBusy  ),
        .romData    ( romData   ),
        .clkDevide  ( clkDevide ),
        .clkEnable  ( clkEnable ),
        .clk        ( clk       ),
        .regAddr    ( regAddr   ),
        .regData    ( regData   ),
        .romAddr    ( romAddr   )
    );

    //outputs
    assign LED[15]    = clk;
//    assign LED[14:13] = sm_top.rom_writer.counter;
    assign LED[14:0] = romWriteLatched ? sm_top.rom_writer.im_wa[14:0] : sm_top.imCpuAddr[14:0];

    //hex out
    wire [ 31:0 ] h7segment;
    assign h7segment = romWriteLatched ? romData : regData;
    wire clkHex;

    sm_clk_divider hex_clk_divider
    (
        .clkIn   ( clkIn  ),
        .rst_n   ( rst_n  ),
        .devide  ( 4'b1   ),
        .enable  ( 1'b1   ),
        .clkOut  ( clkHex )
    );

    sm_hex_display_8 sm_hex_display_8
    (
        .clock          ( clkHex                         ),
        .resetn         ( rst_n                          ),
        .number         ( h7segment                      ),

        .seven_segments ( { CG, CF, CE, CD, CC, CB, CA } ),
        .dot            ( DP                             ),
        .anodes         ( AN                             )
    );

    assign LED16_R = romWriteLatched ? (resetMemBusy ? 1'b0 : 1'b1) : 1'b0;
    assign LED16_B = romWriteLatched ? (resetMemBusy ? 1'b1 : 1'b0) : 1'b0;
    assign LED16_G = romWriteLatched ? 1'b0 : 1'b1;

endmodule
