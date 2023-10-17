`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// 
// Create Date: 07/16/2023 01:13:34 PM
// Module Name: test_bench
// 
///////////////////////////////////////////////////////////////////////////////


module axi_to_uart_S00_tb ();

    // Global Reset Signal.
    reg axi_aresetn;

    // Write Address Channel
    reg   [ 5:0]   axi_awaddr;
    reg   [ 2:0]   axi_awprot;
    reg           axi_awvalid;
    wire          axi_awready; // output

    // Write Data Channel
    reg   [31:0]    axi_wdata;
    reg   [ 3:0]    axi_wstrb;
    reg            axi_wvalid;
    wire           axi_wready; // output

    // Write Response Channel
    wire  [ 1:0]    axi_bresp; // output
    wire           axi_bvalid; // output
    reg            axi_bready;

    // Read Address Channel
    reg   [ 5:0]   axi_araddr;
    reg   [ 2:0]   axi_arprot;
    reg           axi_arvalid;
    wire          axi_arready; // output

    // Read Data Channel
    wire  [31:0]    axi_rdata; // output
    wire  [ 1:0]    axi_rresp; // output
    wire           axi_rvalid; // output
    reg            axi_rready;

    // Clock Signal 100MHz
    // Rising Edge is at 5ns, 15ns
    // Change signals 6ns to 14ns
    reg clk;
    initial begin
        clk = 0;
        forever #(5) clk = !clk;  // 100MHz clock
    end

    task reset_all_signals;
        begin
            axi_aresetn = 1;

            // Address Write
            axi_awaddr   =  0;
            axi_awprot   =  0;
            axi_awvalid  =  0;
            // Write
            axi_wdata    =  0;
            axi_wstrb    =  0;
            axi_wvalid   =  0;
            // Write Response
            axi_bready   =  0;
            // Read Address
            axi_araddr   =  0;
            axi_arprot   =  0;
            axi_arvalid  =  0;
            // Read Data
            axi_rready   =  0;
        end
    endtask

    string vcd_file = "axi_to_uart.vcd";
    // Run Tests Here
    initial begin
        $timeformat(-9, 2, " ns", 20);
        $display("Saving output to file:\n\t%s", vcd_file);
        $dumpfile(vcd_file);
        $dumpvars(0, axi_to_uart_S00_tb);

        // Initialize default values
        $display(" + Setting default values");
        reset_all_signals;

        // Wait 1 clock cycle
        #10;

        // Reset IP
        $display(" + Resetting IP");
        #10;
        // Trigger reset
        axi_aresetn = 0;
        #20;
        axi_aresetn = 1;

        $display("Test #1 - Write to Reg #1 Value 0xDEADBEEF");
        // Current time is 30ns (falling edge)
        axi_awvalid = 1;
        axi_awaddr = 6'b000100;
        axi_wvalid = 1;
        axi_wstrb = 4'b1111;
        axi_wdata = 32'hDEADBEEF;
        axi_bready = 1;
        @(posedge clk); // Slave has just read the values from the master
        @(posedge clk); // Slave has set responses to AW and W
        assert (axi_awready == 1) $display (" + Address Write Asserted.");
            else $error(" - Failed Address Write Assertion.");
        assert (axi_wready == 1) $display (" + Write Asserted.");
            else $error(" - Failed Write Assertion.");
        @(posedge clk); // Slave has ack'd the Write Reponse
        assert (axi_bready == 1) $display (" + Write Response Asserted.");
            else $error(" - Failed Write Response Assertion.");
        reset_all_signals;

        $display("Test #2 - Read value written to Reg #1 Back");
        axi_araddr = 6'b000100;
        axi_arvalid = 1'b1;
        axi_rready = 1'b1;
        @(posedge clk); // Slave has just read Read Request
        @(posedge clk); // Slave has just asserted read address Request
        assert (axi_arready == 1) $display (" + Read Address Asserted.");
            else $error(" - Failed Read Address Assertion.");
        axi_arvalid = 1'b0;
        axi_araddr = 0;
        @(posedge clk); // Slave should have responded with data
        assert (axi_rvalid == 1) $display (" + Read Data Valid.");
            else $error(" - Failed Read Data Valid.");
        assert (axi_rdata == 32'hdeadbeef) $display (" + Read Data .");
            else $error(" - Failed Read Data .");

        $display("Test #3 - Initiate a UART Write");
        axi_awvalid = 1;
        axi_awaddr = 6'h1C;
        axi_wvalid = 1;
        axi_wstrb = 4'b1111;
        axi_wdata = 32'hDEADBEEF;
        axi_bready = 1;
        @(posedge clk);

        wait(dbg_o_tx_active == 1);
        // 1-0 @ 155 ns
        wait (dbg_o_tx_serial == 0);
        // 0-1 @ 104325 ns
        wait (dbg_o_tx_serial == 1);
        // 1-0 @ 521005 ns
        wait (dbg_o_tx_serial == 0);
        // 0-1 @ 625175 ns
        wait (dbg_o_tx_serial == 1);
        // 1-0 @ 1041885 ns
        wait (dbg_o_tx_serial == 0);
        wait(dbg_o_tx_done == 1);
        // 1041730 / 9 =  115,747 / 10417 = 11
        // Can I test FIFO Read?

        $display("Simulation Finished");
        $finish();
    end

    wire                             uart_rxd;
    wire                             uart_txd;

    wire                        uart_clk_edge;
    wire   [2:0]                    o_SM_Main;
    wire                    dbg_uart_write_en;
    wire                     dbg_uart_writing;
    wire   [7:0]          dbg_uart_write_data;
    wire              dbg_uart_write_finished;
    wire                       dbg_uart_count;
    wire   [7:0]         dbg_uart_write_count;

    axi_to_uart_S00 #(
        .C_S_AXI_DATA_WIDTH(32),
        .C_S_AXI_ADDR_WIDTH(6)
    )
        axi_uart_to_S00_dut(
            // UART
            .uart_rxd                (                uart_rxd),
            .uart_txd                (                uart_txd),
            .uart_clk_edge           (           uart_clk_edge),
            .o_SM_Main               (               o_SM_Main),
            // Debug Lines
            .dbg_uart_write_en       (       dbg_uart_write_en),
            .dbg_uart_writing        (        dbg_uart_writing),
            .dbg_uart_write_data     (     dbg_uart_write_data),
            .dbg_uart_write_finished ( dbg_uart_write_finished),
            .dbg_uart_write_count    (    dbg_uart_write_count),

            .dbg_o_tx_active         (         dbg_o_tx_active),
            .dbg_o_tx_serial         (         dbg_o_tx_serial),
            .dbg_o_tx_done           (           dbg_o_tx_done),

            // Global Clock Signal
            .S_AXI_ACLK(clk),

             //Global Reset Signal.
            .S_AXI_ARESETN(axi_aresetn),

            // Write Address Channel
            .S_AXI_AWADDR(axi_awaddr),
            .S_AXI_AWPROT(axi_awprot),
            .S_AXI_AWVALID(axi_awvalid),
            .S_AXI_AWREADY(axi_awready), // output

            // Write Data Channel
            .S_AXI_WDATA(axi_wdata),
            .S_AXI_WSTRB(axi_wstrb),
            .S_AXI_WVALID(axi_wvalid),
            .S_AXI_WREADY(axi_wready), // output

            // Write Response Channel
            .S_AXI_BRESP(axi_bresp), // output
            .S_AXI_BVALID(axi_bvalid), // output
            .S_AXI_BREADY(axi_bready),

            // Read Address Channel
            .S_AXI_ARADDR(axi_araddr),
            .S_AXI_ARPROT(axi_arprot),
            .S_AXI_ARVALID(axi_arvalid),
            .S_AXI_ARREADY(axi_arready),

            // Read Data Channel
            .S_AXI_RDATA(axi_rdata),
            .S_AXI_RRESP(axi_rresp),
            .S_AXI_RVALID(axi_rvalid),
            .S_AXI_RREADY(axi_rready)
        );
endmodule
