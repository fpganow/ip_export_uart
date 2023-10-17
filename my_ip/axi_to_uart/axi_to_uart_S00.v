`timescale 1 ns / 1 ps
(* dont_touch="true" *)
module axi_to_uart_S00 #
    (
        // Users to add parameters here
        // User parameters ends
        // Do not modify the parameters beyond this line
        // Width of S_AXI data bus
        parameter integer C_S_AXI_DATA_WIDTH	= 32,
        // Width of S_AXI address bus
        parameter integer C_S_AXI_ADDR_WIDTH	= 6
    )
    (
        // CUSTOM
        // User ports start
        // UART
        input  wire                        uart_rxd,
        output wire                        uart_txd,
        output wire                   uart_clk_edge,
        output wire  [2:0]                o_SM_Main,
        // Debug Lines
        output wire               dbg_uart_write_en,
        output wire                dbg_uart_writing,
        output wire  [7:0]      dbg_uart_write_data,
        output wire         dbg_uart_write_finished,
        output wire  [7:0]     dbg_uart_write_count,

        output wire                dbg_uart_read_en,
        output wire                dbg_uart_reading,
        output wire  [7:0]       dbg_uart_read_data,
        output wire          dbg_uart_read_finished,

        output wire                 dbg_o_tx_active,
        output wire                 dbg_o_tx_serial,
        output wire                   dbg_o_tx_done,
        // User ports end

        // Global Clock Signal
        input wire                                  S_AXI_ACLK,

        // Global Reset Signal. This Signal is Active LOW
        input wire                               S_AXI_ARESETN,

        // Write Address Channel
        input wire [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_AWADDR,
        input wire [2 : 0]                        S_AXI_AWPROT,
        input wire                               S_AXI_AWVALID,
        output wire                              S_AXI_AWREADY,

        // Write Data Channel
        input wire [C_S_AXI_DATA_WIDTH-1 : 0]      S_AXI_WDATA,
        input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0]  S_AXI_WSTRB,
        input wire                                S_AXI_WVALID,
        output wire                               S_AXI_WREADY,

        // Write Response Channel
        output wire [1 : 0]                        S_AXI_BRESP,
        output wire                               S_AXI_BVALID,
        input wire                                S_AXI_BREADY,

        // Read Address Channel
        input wire [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_ARADDR,
        input wire [2 : 0]                        S_AXI_ARPROT,
        input wire                               S_AXI_ARVALID,
        output wire                              S_AXI_ARREADY,

        // Read Data Channel
        output wire [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_RDATA,
        output wire [1 : 0]                        S_AXI_RRESP,
        output wire                               S_AXI_RVALID,
        input wire                                S_AXI_RREADY
);

    // AXI4LITE signals
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
    reg  	axi_awready;
    reg  	axi_wready;
    reg [1 : 0] 	axi_bresp;
    reg  	axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
    reg  	axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
    reg [1 : 0] 	axi_rresp;
    reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	// ADDR_LSB = 2
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 3;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 16
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg4;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg5;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg6;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg7;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg8;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg9;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg10;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg11;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg12;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg13;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg14;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg15;
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;

    // CUSTOM
    // My Signals
    // UART
    reg                uart_write_en;
    reg                 uart_writing;
    reg   [7:0]      uart_write_data;
    reg          uart_write_finished;
    reg   [7:0]     uart_write_count;
    reg                 uart_read_en;
    reg                 uart_reading;
    reg   [7:0]       uart_read_data;
    reg           uart_read_finished;

    // FIFO Signals
    reg                      fifo_wr;
    reg   [7:0]         fifo_data_in;
    reg                      fifo_rd;
    wire  [7:0]        fifo_data_out;
    wire              fifo_fifo_full;
    wire             fifo_fifo_empty;
    wire         fifo_fifo_threshold;
    wire          fifo_fifo_overflow;
    wire         fifo_fifo_underflow;

    reg                      i_Tx_DV;
    reg   [7:0]            i_Tx_Byte;
    wire                 o_Tx_Active;
    wire                 o_Tx_Serial;
    wire                   o_Tx_Done;

    // Connection my debug ports
    assign dbg_uart_write_en        =        uart_write_en;
    assign dbg_uart_writing         =         uart_writing;
    assign dbg_uart_write_data      =      uart_write_data;
    assign dbg_uart_write_finished  =  uart_write_finished;
    assign dbg_uart_write_count     =     uart_write_count;

    assign dbg_uart_read_en         =         uart_read_en;
    assign dbg_uart_reading         =         uart_reading;
    assign dbg_uart_read_data       =       uart_read_data;
    assign dbg_uart_read_finished   =   uart_read_finished;

    assign dbg_o_tx_active          =          o_Tx_Active;
    assign dbg_o_tx_serial          =          o_Tx_Serial;
    assign dbg_o_tx_done            =            o_Tx_Done;
    assign uart_txd                 =          o_Tx_Serial;

    // I/O Connections assignments
    assign S_AXI_AWREADY  =  axi_awready;
    assign S_AXI_WREADY   =   axi_wready;
    assign S_AXI_BRESP    =    axi_bresp;
    assign S_AXI_BVALID   =   axi_bvalid;
    assign S_AXI_ARREADY  =  axi_arready;
    assign S_AXI_RDATA    =    axi_rdata;
    assign S_AXI_RRESP    =    axi_rresp;
    assign S_AXI_RVALID   =   axi_rvalid;

    // Loop 1: Write Address Channel
    always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          axi_awready <= 1'b0;
          aw_en <= 1'b1;

          axi_awaddr <= 1'b0;
        end
      else
        begin
          if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
            begin
              // ACK to host that we read the Write Address
              axi_awready <= 1'b1;
              // Prevent us from re-reading Write Address
              aw_en <= 1'b0;
              // Save Write Address Here
              axi_awaddr <= S_AXI_AWADDR;
            end
          else if (S_AXI_BREADY && axi_bvalid)
            begin
              // We finished a write transaction, be ready for next one
              aw_en <= 1'b1;
              axi_awready <= 1'b0;
            end
          else
            begin
              axi_awready <= 1'b0;
            end
        end
    end

    // Loop 2: Write Data Channel
    always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          axi_wready <= 1'b0;
        end
      else
	    begin
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
              // ACK Write Data
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end
	end

	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    // Loop 3: Handle Write Data
    // I prefer this to be part of Loop 2, but it is complicated
    always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
		begin
          slv_reg0 <= 0;
          slv_reg1 <= 0;
          slv_reg2 <= 0;
          slv_reg3 <= 0;
          slv_reg4 <= 0;
          slv_reg5 <= 0;
          slv_reg6 <= 0;
          slv_reg7 <= 0;
          slv_reg8 <= 0;
          slv_reg9 <= 0;
          slv_reg10 <= 0;
          slv_reg11 <= 0;
          slv_reg12 <= 0;
          slv_reg13 <= 0;
          slv_reg14 <= 0;
          slv_reg15 <= 0;
//          uart_write_en <= 1'b0;

          fifo_wr       <=                     1'b0;
          fifo_data_in  <=             32'h00000000;
        end
      else begin
        if (slv_reg_wren)
          begin
              // OPT_MEM_ADDR_BITS = 3
              // ADDR_LSB = 2
              // 5 downto 2
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          4'h0:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          4'h1:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          4'h2:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          4'h3:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          4'h4:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          4'h5:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                slv_reg5[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          4'h6:
	            begin
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	            end
              // CUSTOM
              // SPECIAL CASE Register #7 or Write Address (0x1C)
              4'h7:
                begin
//                  uart_write_en <= 1'b1;
//                  uart_write_data <= S_AXI_WDATA[(0*8) +: 8];
                  // Add value to FIFO
                  fifo_wr       <=                     1'b1;
                  fifo_data_in  <=  S_AXI_WDATA[(0*8) +: 8];
                end
              // SPECIAL CASE Register #8 or Write Address (0x20)
              //  - Write to register and constantly just increment its value
	          4'h8:
	            begin
	              slv_reg8 <= slv_reg8 + 1;
	            end
              // SPECIAL CASE Register #9 or Write Address (0x2C)
              //  - Just write a value to make sure writing period works
	          4'h9:
	            begin
	               slv_reg9 <= 99;
	            end
	          4'hA:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                slv_reg10[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          4'hB:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                slv_reg11[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          4'hC:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                slv_reg12[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          4'hD:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                slv_reg13[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          4'hE:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                slv_reg14[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          4'hF:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                slv_reg15[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end
	          default : begin
                  fifo_wr       <=                     1'b0;
                  fifo_data_in  <=             32'h00000000;
	                      slv_reg0 <= slv_reg0;
	                      slv_reg1 <= slv_reg1;
	                      slv_reg2 <= slv_reg2;
	                      slv_reg3 <= slv_reg3;
	                      slv_reg4 <= slv_reg4;
	                      slv_reg5 <= slv_reg5;
	                      slv_reg6 <= slv_reg6;
	                      slv_reg7 <= slv_reg7;
	                      slv_reg8 <= slv_reg8;
	                      slv_reg9 <= slv_reg9;
	                      slv_reg10 <= slv_reg10;
	                      slv_reg11 <= slv_reg11;
	                      slv_reg12 <= slv_reg12;
	                      slv_reg13 <= slv_reg13;
	                      slv_reg14 <= slv_reg14;
	                      slv_reg15 <= slv_reg15;
	                    end
	        endcase
	      end
	  end
//      if (uart_write_finished)
//        begin
//            uart_write_en <= 1'b0;
//        end
	end

    // Loop 5: Write Response Channel
    always @( posedge S_AXI_ACLK )
    begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end
	  else
	    begin
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid)
	            //check if bready is asserted while bvalid is high)
	            //(there is a possibility that bready is always asserted high)
	            begin
	              axi_bvalid <= 1'b0;
	            end
	        end
	    end
    end

    // Loop 6: Read Address Latch/I2C Read Control
    always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          axi_arready <= 1'b0;
          axi_araddr  <= 32'b0;
          // Reset uart_read_en
        end
      else
        begin
          if (~axi_arready && S_AXI_ARVALID)
            begin
              // indicates that the slave has acceped the valid read address
              axi_arready <= 1'b1;
              // Read address latching
              axi_araddr  <= S_AXI_ARADDR;
//              if ( S_AXI_ARADDR == (5'b00111 << 2) )
//                begin
//                  // I2C: Read Transaction starting
//                  // Set i2c_read_en
//                  i2c_read_en <= 1'b1;
//                end
            end
          else
            begin
              axi_arready <= 1'b0;
            end
        end
        // Reset i2c_read_en
//        if (i2c_read_finished)
//          begin
//            i2c_read_en <= 1'b0;
//            i2c_reading <= 1'b0;
//          end
    end

    // Loop 7: Read Data from Register
    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
    always @(*)
    begin
      // Address decoding for reading registers
        case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
          4'h0   : reg_data_out <= slv_reg0;
          4'h1   : reg_data_out <= slv_reg1;
          4'h2   : reg_data_out <= slv_reg2;
          4'h3   : reg_data_out <= slv_reg3;
          4'h4   : reg_data_out <= slv_reg4;
          4'h5   : reg_data_out <= slv_reg5;
          4'h6   : reg_data_out <= slv_reg6;
          4'h7   : reg_data_out <= slv_reg7;
          4'h8   : reg_data_out <= slv_reg8;
          4'h9   : reg_data_out <= slv_reg9;
          4'hA   : reg_data_out <= slv_reg10;
          4'hB   : reg_data_out <= slv_reg11;
          4'hC   : reg_data_out <= slv_reg12;
          4'hD   : reg_data_out <= slv_reg13;
          4'hE   : reg_data_out <= slv_reg14;
          4'hF   : reg_data_out <= slv_reg15;
          default : reg_data_out <= 0;
        endcase
    end

    // Loop 8: FIFO Control Loop
    reg fifo_req;
    always @ (posedge S_AXI_ACLK) begin
      if ( S_AXI_ARESETN == 1'b0 ) begin
          axi_rdata      <=  0;
          axi_rvalid     <=  0;
          axi_rresp      <=  0;

          fifo_rd        <=  0;
          fifo_req       <=  0;

          i_Tx_DV        <=  0;
          i_Tx_Byte      <=  0;
      end else begin
          // UART not busy AND FIFO not empty
          if (!fifo_req && !o_Tx_Active && !fifo_fifo_empty) begin
            // Then request data item
            fifo_rd     <=  1;
            fifo_req    <=  1;
            i_Tx_DV     <=  0;
            i_Tx_Byte   <=  0;
            axi_rdata   <=  0;
            axi_rvalid  <=  0;
            axi_rresp   <=  0;
// TODO: o_Tx_Active has a delay
          // Did we request during last clock cycle?
          end if (fifo_req) begin
            // Then data should be valid.
            // Stop request
            fifo_rd   <=  0;
            fifo_req  <=  0;
            // Start uart write
            i_Tx_DV   <=  1;
            i_Tx_Byte <= fifo_data_out;
          end else begin
            i_Tx_DV     <=  0;
            i_Tx_Byte   <=  0;
          end
          // READ Section
          if(slv_reg_rden) begin
            axi_rdata   <=  reg_data_out;
            axi_rvalid  <=  1;
            axi_rresp   <=  0;
          end else begin
            axi_rdata   <=  0;
            axi_rvalid  <=  0;
            axi_rresp   <=  0;
          end
      end
    end

    fifo_mem #()
        fifo_mem_inst (
        // Clock
        .clk(S_AXI_ACLK),
        .rst_n(S_AXI_ARESETN),
        // Write to FIFO
        .wr(fifo_wr),
        .data_in(fifo_data_in),
        // Read FIFO
        .rd(fifo_rd),
        .data_out(fifo_data_out),
        // Status
        .fifo_full(fifo_fifo_full),
        .fifo_empty(fifo_fifo_empty),
        .fifo_threshold(fifo_fifo_threshold),
        .fifo_overflow(fifo_fifo_overflow),
        .fifo_underflow(fifo_fifo_underflow)
    );

    uart_tx #(.CLKS_PER_BIT(10417))
        uart_tx_inst(
        // Clock
        .i_Clock(S_AXI_ACLK),
        .i_Tx_DV(i_Tx_DV),
        .i_Tx_Byte(i_Tx_Byte),
        .o_Tx_Active(o_Tx_Active),
        .o_Tx_Serial(o_Tx_Serial),
        .o_Tx_Done(o_Tx_Done),
        .o_SM_Main(o_SM_Main),
        .uart_clk_edge(uart_clk_edge)
    );
    // User logic ends

    endmodule
