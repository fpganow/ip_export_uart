`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 09/18/2023
//
// Module Name: uart_tx_tb.v
//
/////////////////////////////////////////////////////////////////////////////////

module uart_tx_tb();

    // Clock Signal 100MHz
    reg clk;
    initial begin
        clk = 0;
        forever #(5) clk = !clk; // 100 MHz clock
    end

    wire i_Clock;
    reg i_Tx_DV;
    reg[7:0] i_Tx_Byte;
    wire o_Tx_Active;
    wire o_Tx_Serial;
    wire o_Tx_Done;
    wire [2:0] o_SM_Main;
    wire uart_clk_edge;

    assign i_Clock = clk;
    initial begin
        $timeformat(-9, 2, " ns", 20);
        i_Tx_DV = 1'b0;
        i_Tx_Byte = 8'b0000000;

        $display("Test #1 Write 'c'");
        #50;
        i_Tx_DV = 1'b1;
        // 0110 0001
        i_Tx_Byte = 8'h61;

        #50;
        i_Tx_DV = 1'b0;
        i_Tx_Byte = 8'h61;
       
        $display("waiting for o_Tx_Active");
        wait (o_Tx_Active == 1'b0);
        $finish();
    end

// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of i_Clock)/(Frequency of UART)
// Example: 10 MHz Clock, 115200 baud UART
// (10000000)/(115200) = 87
// (10_000_000)/(115_200) = 87
// 100 MHz Clock, 9600 baud UART
// 100_000_000 / (9600) = 10,426.667
// 100 MHz Clock, 115_200 baud UART
// 100_000_000 / (115_200) = 868

    uart_tx
        #(.CLKS_PER_BIT(87)) 
        dut
    (
        .i_Clock(i_Clock),
        .i_Tx_DV(i_Tx_DV),
        .i_Tx_Byte(i_Tx_Byte),
        .o_Tx_Active(o_Tx_Active),
        .o_Tx_Serial(o_Tx_Serial),
        .o_Tx_Done(o_Tx_Done),
        .o_SM_Main(o_SM_Main),
        .uart_clk_edge(uart_clk_edge)
    );
endmodule
