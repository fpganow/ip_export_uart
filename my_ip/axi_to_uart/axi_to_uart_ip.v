`timescale 1 ns / 1 ps
(* dont_touch="true" *)
module axi_to_uart_ip #
    (
        // Parameters of Axi Slave Bus Interface S00_AXI
        parameter integer C_S00_AXI_DATA_WIDTH	= 32,
        parameter integer C_S00_AXI_ADDR_WIDTH	= 6
    )
    (
        // My Ports
        // UART
        input  wire                      uart_rxd,
        output wire                      uart_txd,
        output wire                 uart_clk_edge,
        output  reg                      uart_clk,
        output wire                   o_SM_Main_0,
        output wire                   o_SM_Main_1,
        output wire                   o_SM_Main_2,
        // Debug Lines
        output wire             dbg_uart_write_en,
        output wire              dbg_uart_writing,
        output wire [7:0]     dbg_uart_write_data,
        output wire       dbg_uart_write_finished,
        output wire [7:0]    dbg_uart_write_count,

        output wire              dbg_uart_read_en,
        output wire              dbg_uart_reading,
        output wire [7:0]      dbg_uart_read_data,
        output wire        dbg_uart_read_finished,

        output wire               dbg_o_tx_active,
        output wire               dbg_o_tx_serial,
        output wire                 dbg_o_tx_done,

		// Ports of Axi Slave Bus Interface S00_AXI
		input wire                                   s00_axi_aclk,
		input wire                                   s00_axi_aresetn,
		input wire     [C_S00_AXI_ADDR_WIDTH-1 : 0]  s00_axi_awaddr,
		input wire                          [2 : 0]  s00_axi_awprot,
		input wire                                   s00_axi_awvalid,
		output wire                                  s00_axi_awready,
		input wire     [C_S00_AXI_DATA_WIDTH-1 : 0]  s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0]  s00_axi_wstrb,
		input wire                                   s00_axi_wvalid,
		output wire                                  s00_axi_wready,
		output wire                         [1 : 0]  s00_axi_bresp,
		output wire                                  s00_axi_bvalid,
		input wire                                   s00_axi_bready,
		input wire     [C_S00_AXI_ADDR_WIDTH-1 : 0]  s00_axi_araddr,
		input wire                          [2 : 0]  s00_axi_arprot,
		input wire                                   s00_axi_arvalid,
		output wire                                  s00_axi_arready,
		output wire    [C_S00_AXI_DATA_WIDTH-1 : 0]  s00_axi_rdata,
		output wire                         [1 : 0]  s00_axi_rresp,
		output wire                                  s00_axi_rvalid,
		input wire                                   s00_axi_rready
	);

    reg [27:0] counter = 28'd0;
    // 100 MHZ
    // 100,000,000
    // 1,000 = 100,000,000 / 100,000
    reg DIVISOR = 100000'd2;
	always @(posedge s00_axi_aclk) begin
	   counter <= counter + 28'd1;
	   if(counter >= (DIVISOR-1))
	       counter <= 28'd0;
	   uart_clk <= (counter < DIVISOR / 2) ? 1'b1 : 1'b0; 
	end

    wire [2:0] o_SM_Main;
    assign o_SM_Main_0 = o_SM_Main[0];
    assign o_SM_Main_1 = o_SM_Main[1];
    assign o_SM_Main_2 = o_SM_Main[2];

// Instantiation of Axi Bus Interface S00_AXI
    axi_to_uart_S00_AXI # (
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) axi_to_uart_S00_AXI_inst (
        .S_AXI_ACLK(s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),

        // UART
        .uart_rxd(uart_rxd),
        .uart_txd(uart_txd),
        .uart_clk_edge(uart_clk_edge),
        .o_SM_Main(o_SM_Main),
        // Debug Lines
        .dbg_uart_write_en(dbg_uart_write_en),
        .dbg_uart_writing(dbg_uart_writing),
        .dbg_uart_write_data(dbg_uart_write_data),
        .dbg_uart_write_finished(dbg_uart_write_finished),
        .dbg_uart_write_count(dbg_uart_write_count),

        .dbg_uart_read_en(dbg_uart_read_en),
        .dbg_uart_reading(dbg_uart_reading),
        .dbg_uart_read_data(dbg_uart_read_data),
        .dbg_uart_read_finished(dbg_uart_read_finished),

        .dbg_o_tx_active(dbg_o_tx_active),
        .dbg_o_tx_serial(dbg_o_tx_serial),
        .dbg_o_tx_done(dbg_o_tx_done),

		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

// Add user logic here

// User logic ends

endmodule
