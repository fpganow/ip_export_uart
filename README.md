# ip_export_uart
How to use LabVIEW FPGA (via IP Export) to write a UART tranceiver and export to a Vivado design

## Pure Verilog Implementation (Baseline)

## axi_to_uart
Verilog code to connect a MicroBlaze of Zynq based processor with the UART transmit and receive IP. For the verilog implementation I have inserted a FIFO in between the AXI interface and the UART IP to buffer all communications to prevent any packet loss.  For the LabVIEW version, the IP has been included as part of the LabVIEW Implementation.

# fifo_now

# uart_now
axi_to_uart
fifo_now
uart_now

## LabVIEW FPGA Implementation


