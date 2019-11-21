
################################################################
# This is a generated script based on design: zc702
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2018.3
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source zc702_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7z020clg484-1
   set_property BOARD_PART xilinx.com:zc702:part0:1.4 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name zc702

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design -bdsource SDSoC $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set DDR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]
  set FIXED_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]

  # Create ports

  # Create instance: axi_ic_ps7_M_AXI_GP0, and set properties
  set axi_ic_ps7_M_AXI_GP0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_ic_ps7_M_AXI_GP0 ]
  set_property -dict [ list \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.M01_HAS_REGSLICE {1} \
   CONFIG.M02_HAS_REGSLICE {1} \
   CONFIG.M03_HAS_REGSLICE {1} \
   CONFIG.M04_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {5} \
   CONFIG.NUM_SI {1} \
   CONFIG.S00_HAS_REGSLICE {1} \
   CONFIG.STRATEGY {2} \
 ] $axi_ic_ps7_M_AXI_GP0

  # Create instance: axi_ic_ps7_S_AXI_HP0, and set properties
  set axi_ic_ps7_S_AXI_HP0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_ic_ps7_S_AXI_HP0 ]
  set_property -dict [ list \
   CONFIG.M00_HAS_DATA_FIFO {2} \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {1} \
   CONFIG.S00_HAS_DATA_FIFO {2} \
   CONFIG.S00_HAS_REGSLICE {1} \
   CONFIG.STRATEGY {0} \
 ] $axi_ic_ps7_S_AXI_HP0

  # Create instance: axi_ic_ps7_S_AXI_HP1, and set properties
  set axi_ic_ps7_S_AXI_HP1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_ic_ps7_S_AXI_HP1 ]
  set_property -dict [ list \
   CONFIG.M00_HAS_DATA_FIFO {2} \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {1} \
   CONFIG.S00_HAS_DATA_FIFO {2} \
   CONFIG.S00_HAS_REGSLICE {1} \
   CONFIG.STRATEGY {0} \
 ] $axi_ic_ps7_S_AXI_HP1

  # Create instance: axi_ic_ps7_S_AXI_HP2, and set properties
  set axi_ic_ps7_S_AXI_HP2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_ic_ps7_S_AXI_HP2 ]
  set_property -dict [ list \
   CONFIG.M00_HAS_DATA_FIFO {2} \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {1} \
   CONFIG.S00_HAS_DATA_FIFO {2} \
   CONFIG.S00_HAS_REGSLICE {1} \
   CONFIG.STRATEGY {0} \
 ] $axi_ic_ps7_S_AXI_HP2

  # Create instance: axi_ic_ps7_S_AXI_HP3, and set properties
  set axi_ic_ps7_S_AXI_HP3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_ic_ps7_S_AXI_HP3 ]
  set_property -dict [ list \
   CONFIG.M00_HAS_DATA_FIFO {2} \
   CONFIG.M00_HAS_REGSLICE {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {1} \
   CONFIG.S00_HAS_DATA_FIFO {2} \
   CONFIG.S00_HAS_REGSLICE {1} \
   CONFIG.STRATEGY {0} \
 ] $axi_ic_ps7_S_AXI_HP3

  # Create instance: axis_dwc_dm_0_tx_0, and set properties
  set axis_dwc_dm_0_tx_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwc_dm_0_tx_0 ]
  set_property -dict [ list \
   CONFIG.M_TDATA_NUM_BYTES {1} \
   CONFIG.S_TDATA_NUM_BYTES {8} \
 ] $axis_dwc_dm_0_tx_0

  # Create instance: axis_dwc_dm_1_tx_0, and set properties
  set axis_dwc_dm_1_tx_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwc_dm_1_tx_0 ]
  set_property -dict [ list \
   CONFIG.M_TDATA_NUM_BYTES {1} \
   CONFIG.S_TDATA_NUM_BYTES {8} \
 ] $axis_dwc_dm_1_tx_0

  # Create instance: axis_dwc_dm_2_tx_0, and set properties
  set axis_dwc_dm_2_tx_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwc_dm_2_tx_0 ]
  set_property -dict [ list \
   CONFIG.M_TDATA_NUM_BYTES {4} \
   CONFIG.S_TDATA_NUM_BYTES {8} \
 ] $axis_dwc_dm_2_tx_0

  # Create instance: axis_dwc_dm_3_rx_0, and set properties
  set axis_dwc_dm_3_rx_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwc_dm_3_rx_0 ]
  set_property -dict [ list \
   CONFIG.M_TDATA_NUM_BYTES {8} \
   CONFIG.S_TDATA_NUM_BYTES {4} \
 ] $axis_dwc_dm_3_rx_0

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
  set_property -dict [ list \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100} \
   CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {142} \
   CONFIG.CLKOUT2_USED {true} \
   CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {166} \
   CONFIG.CLKOUT3_USED {true} \
   CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {200} \
   CONFIG.CLKOUT4_USED {true} \
   CONFIG.CLKOUT5_REQUESTED_OUT_FREQ {50} \
   CONFIG.CLKOUT5_USED {true} \
   CONFIG.CLKOUT6_REQUESTED_OUT_FREQ {41.66} \
   CONFIG.CLKOUT6_USED {true} \
   CONFIG.RESET_TYPE {ACTIVE_LOW} \
 ] $clk_wiz_0

  # Create instance: dm_0, and set properties
  set dm_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dm_0 ]
  set_property -dict [ list \
   CONFIG.c_dlytmr_resolution {1250} \
   CONFIG.c_include_mm2s {1} \
   CONFIG.c_include_mm2s_dre {1} \
   CONFIG.c_include_mm2s_sf {1} \
   CONFIG.c_include_s2mm {0} \
   CONFIG.c_include_sg {0} \
   CONFIG.c_m_axi_mm2s_data_width {64} \
   CONFIG.c_m_axis_mm2s_tdata_width {64} \
   CONFIG.c_mm2s_burst_size {64} \
   CONFIG.c_sg_length_width {26} \
 ] $dm_0

  # Create instance: dm_1, and set properties
  set dm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dm_1 ]
  set_property -dict [ list \
   CONFIG.c_dlytmr_resolution {1250} \
   CONFIG.c_include_mm2s {1} \
   CONFIG.c_include_mm2s_dre {1} \
   CONFIG.c_include_mm2s_sf {1} \
   CONFIG.c_include_s2mm {0} \
   CONFIG.c_include_sg {0} \
   CONFIG.c_m_axi_mm2s_data_width {64} \
   CONFIG.c_m_axis_mm2s_tdata_width {64} \
   CONFIG.c_mm2s_burst_size {64} \
   CONFIG.c_sg_length_width {26} \
 ] $dm_1

  # Create instance: dm_2, and set properties
  set dm_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dm_2 ]
  set_property -dict [ list \
   CONFIG.c_dlytmr_resolution {1250} \
   CONFIG.c_include_mm2s {1} \
   CONFIG.c_include_mm2s_dre {1} \
   CONFIG.c_include_mm2s_sf {1} \
   CONFIG.c_include_s2mm {0} \
   CONFIG.c_include_sg {0} \
   CONFIG.c_m_axi_mm2s_data_width {64} \
   CONFIG.c_m_axis_mm2s_tdata_width {64} \
   CONFIG.c_mm2s_burst_size {64} \
   CONFIG.c_sg_length_width {26} \
 ] $dm_2

  # Create instance: dm_3, and set properties
  set dm_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 dm_3 ]
  set_property -dict [ list \
   CONFIG.c_dlytmr_resolution {1250} \
   CONFIG.c_include_mm2s {0} \
   CONFIG.c_include_s2mm {1} \
   CONFIG.c_include_s2mm_dre {1} \
   CONFIG.c_include_s2mm_sf {1} \
   CONFIG.c_include_sg {0} \
   CONFIG.c_m_axi_s2mm_data_width {64} \
   CONFIG.c_s2mm_burst_size {64} \
   CONFIG.c_sg_length_width {26} \
 ] $dm_3

  # Create instance: gemm_hw_1, and set properties
  set gemm_hw_1 [ create_bd_cell -type ip -vlnv xilinx.com:hls:gemm_hw:1.0 gemm_hw_1 ]

  # Create instance: gemm_hw_1_if, and set properties
  set gemm_hw_1_if [ create_bd_cell -type ip -vlnv xilinx.com:ip:adapter_v3_0:1.0 gemm_hw_1_if ]
  set_property -dict [ list \
   CONFIG.C_INPUT_SCALAR_0_WIDTH {32} \
   CONFIG.C_INPUT_SCALAR_1_WIDTH {32} \
   CONFIG.C_INPUT_SCALAR_2_WIDTH {32} \
   CONFIG.C_INPUT_SCALAR_3_WIDTH {32} \
   CONFIG.C_INPUT_SCALAR_4_WIDTH {32} \
   CONFIG.C_INPUT_SCALAR_5_WIDTH {32} \
   CONFIG.C_INPUT_SCALAR_6_WIDTH {32} \
   CONFIG.C_INPUT_SCALAR_7_WIDTH {32} \
   CONFIG.C_INPUT_SCALAR_8_WIDTH {32} \
   CONFIG.C_NUM_INPUT_FIFOs {3} \
   CONFIG.C_NUM_OUTPUT_FIFOs {1} \
   CONFIG.C_N_INPUT_SCALARS {9} \
   CONFIG.M_AXIS_FIFO_0_BYTE_WIDTH {32} \
   CONFIG.M_AXIS_FIFO_0_DEPTH {1024} \
   CONFIG.M_AXIS_FIFO_0_DMWIDTH {32} \
   CONFIG.M_AXIS_FIFO_0_WIDTH {32} \
   CONFIG.S_AXIS_FIFO_0_BYTE_WIDTH {8} \
   CONFIG.S_AXIS_FIFO_0_DEPTH {1024} \
   CONFIG.S_AXIS_FIFO_0_DMWIDTH {8} \
   CONFIG.S_AXIS_FIFO_0_WIDTH {8} \
   CONFIG.S_AXIS_FIFO_1_BYTE_WIDTH {8} \
   CONFIG.S_AXIS_FIFO_1_DEPTH {32} \
   CONFIG.S_AXIS_FIFO_1_DMWIDTH {8} \
   CONFIG.S_AXIS_FIFO_1_WIDTH {8} \
   CONFIG.S_AXIS_FIFO_2_BYTE_WIDTH {32} \
   CONFIG.S_AXIS_FIFO_2_DEPTH {1024} \
   CONFIG.S_AXIS_FIFO_2_DMWIDTH {32} \
   CONFIG.S_AXIS_FIFO_2_WIDTH {32} \
 ] $gemm_hw_1_if

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: proc_sys_reset_1, and set properties
  set proc_sys_reset_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_1 ]

  # Create instance: proc_sys_reset_2, and set properties
  set proc_sys_reset_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_2 ]

  # Create instance: proc_sys_reset_3, and set properties
  set proc_sys_reset_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_3 ]

  # Create instance: proc_sys_reset_4, and set properties
  set proc_sys_reset_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_4 ]

  # Create instance: proc_sys_reset_5, and set properties
  set proc_sys_reset_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_5 ]

  # Create instance: ps7, and set properties
  set ps7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7 ]
  set_property -dict [ list \
   CONFIG.PCW_ACT_APU_PERIPHERAL_FREQMHZ {666.666687} \
   CONFIG.PCW_ACT_CAN_PERIPHERAL_FREQMHZ {23.809523} \
   CONFIG.PCW_ACT_DCI_PERIPHERAL_FREQMHZ {10.158730} \
   CONFIG.PCW_ACT_ENET0_PERIPHERAL_FREQMHZ {25.000000} \
   CONFIG.PCW_ACT_ENET1_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_FPGA0_PERIPHERAL_FREQMHZ {50.000000} \
   CONFIG.PCW_ACT_FPGA1_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_FPGA2_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_FPGA3_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_PCAP_PERIPHERAL_FREQMHZ {200.000000} \
   CONFIG.PCW_ACT_QSPI_PERIPHERAL_FREQMHZ {200.000000} \
   CONFIG.PCW_ACT_SDIO_PERIPHERAL_FREQMHZ {50.000000} \
   CONFIG.PCW_ACT_SMC_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_SPI_PERIPHERAL_FREQMHZ {10.000000} \
   CONFIG.PCW_ACT_TPIU_PERIPHERAL_FREQMHZ {200.000000} \
   CONFIG.PCW_ACT_TTC0_CLK0_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC0_CLK1_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC0_CLK2_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC1_CLK0_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC1_CLK1_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_TTC1_CLK2_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_ACT_UART_PERIPHERAL_FREQMHZ {50.000000} \
   CONFIG.PCW_ACT_WDT_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_APU_PERIPHERAL_FREQMHZ {666.666666} \
   CONFIG.PCW_ARMPLL_CTRL_FBDIV {40} \
   CONFIG.PCW_CAN0_CAN0_IO {MIO 46 .. 47} \
   CONFIG.PCW_CAN0_GRP_CLK_ENABLE {0} \
   CONFIG.PCW_CAN0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_CAN_PERIPHERAL_DIVISOR0 {7} \
   CONFIG.PCW_CAN_PERIPHERAL_DIVISOR1 {6} \
   CONFIG.PCW_CAN_PERIPHERAL_FREQMHZ {23.8095} \
   CONFIG.PCW_CAN_PERIPHERAL_VALID {1} \
   CONFIG.PCW_CLK0_FREQ {50000000} \
   CONFIG.PCW_CLK1_FREQ {10000000} \
   CONFIG.PCW_CLK2_FREQ {10000000} \
   CONFIG.PCW_CLK3_FREQ {10000000} \
   CONFIG.PCW_CPU_CPU_PLL_FREQMHZ {1333.333} \
   CONFIG.PCW_CPU_PERIPHERAL_DIVISOR0 {2} \
   CONFIG.PCW_DCI_PERIPHERAL_DIVISOR0 {15} \
   CONFIG.PCW_DCI_PERIPHERAL_DIVISOR1 {7} \
   CONFIG.PCW_DDRPLL_CTRL_FBDIV {32} \
   CONFIG.PCW_DDR_DDR_PLL_FREQMHZ {1066.667} \
   CONFIG.PCW_DDR_PERIPHERAL_DIVISOR0 {2} \
   CONFIG.PCW_DDR_RAM_HIGHADDR {0x3FFFFFFF} \
   CONFIG.PCW_ENET0_ENET0_IO {MIO 16 .. 27} \
   CONFIG.PCW_ENET0_GRP_MDIO_ENABLE {1} \
   CONFIG.PCW_ENET0_GRP_MDIO_IO {MIO 52 .. 53} \
   CONFIG.PCW_ENET0_PERIPHERAL_DIVISOR0 {8} \
   CONFIG.PCW_ENET0_PERIPHERAL_DIVISOR1 {5} \
   CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_ENET0_PERIPHERAL_FREQMHZ {100 Mbps} \
   CONFIG.PCW_ENET0_RESET_ENABLE {1} \
   CONFIG.PCW_ENET0_RESET_IO {MIO 11} \
   CONFIG.PCW_ENET1_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_ENET1_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_ENET1_RESET_ENABLE {0} \
   CONFIG.PCW_ENET_RESET_ENABLE {1} \
   CONFIG.PCW_ENET_RESET_SELECT {Share reset pin} \
   CONFIG.PCW_EN_CAN0 {1} \
   CONFIG.PCW_EN_EMIO_TTC0 {1} \
   CONFIG.PCW_EN_ENET0 {1} \
   CONFIG.PCW_EN_GPIO {1} \
   CONFIG.PCW_EN_I2C0 {1} \
   CONFIG.PCW_EN_QSPI {1} \
   CONFIG.PCW_EN_SDIO0 {1} \
   CONFIG.PCW_EN_TTC0 {1} \
   CONFIG.PCW_EN_UART1 {1} \
   CONFIG.PCW_EN_USB0 {1} \
   CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR0 {5} \
   CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR1 {4} \
   CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR1 {1} \
   CONFIG.PCW_FPGA_FCLK0_ENABLE {1} \
   CONFIG.PCW_FPGA_FCLK1_ENABLE {0} \
   CONFIG.PCW_FPGA_FCLK2_ENABLE {0} \
   CONFIG.PCW_FPGA_FCLK3_ENABLE {0} \
   CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {1} \
   CONFIG.PCW_GPIO_MIO_GPIO_IO {MIO} \
   CONFIG.PCW_I2C0_GRP_INT_ENABLE {0} \
   CONFIG.PCW_I2C0_I2C0_IO {MIO 50 .. 51} \
   CONFIG.PCW_I2C0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_I2C0_RESET_ENABLE {1} \
   CONFIG.PCW_I2C0_RESET_IO {MIO 13} \
   CONFIG.PCW_I2C1_RESET_ENABLE {0} \
   CONFIG.PCW_I2C_PERIPHERAL_FREQMHZ {111.111115} \
   CONFIG.PCW_I2C_RESET_ENABLE {1} \
   CONFIG.PCW_I2C_RESET_SELECT {Share reset pin} \
   CONFIG.PCW_IOPLL_CTRL_FBDIV {30} \
   CONFIG.PCW_IO_IO_PLL_FREQMHZ {1000.000} \
   CONFIG.PCW_IRQ_F2P_INTR {1} \
   CONFIG.PCW_MIO_0_DIRECTION {in} \
   CONFIG.PCW_MIO_0_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_0_PULLUP {enabled} \
   CONFIG.PCW_MIO_0_SLEW {slow} \
   CONFIG.PCW_MIO_10_DIRECTION {inout} \
   CONFIG.PCW_MIO_10_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_10_PULLUP {enabled} \
   CONFIG.PCW_MIO_10_SLEW {slow} \
   CONFIG.PCW_MIO_11_DIRECTION {out} \
   CONFIG.PCW_MIO_11_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_11_PULLUP {enabled} \
   CONFIG.PCW_MIO_11_SLEW {slow} \
   CONFIG.PCW_MIO_12_DIRECTION {inout} \
   CONFIG.PCW_MIO_12_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_12_PULLUP {enabled} \
   CONFIG.PCW_MIO_12_SLEW {slow} \
   CONFIG.PCW_MIO_13_DIRECTION {out} \
   CONFIG.PCW_MIO_13_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_13_PULLUP {enabled} \
   CONFIG.PCW_MIO_13_SLEW {slow} \
   CONFIG.PCW_MIO_14_DIRECTION {inout} \
   CONFIG.PCW_MIO_14_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_14_PULLUP {enabled} \
   CONFIG.PCW_MIO_14_SLEW {slow} \
   CONFIG.PCW_MIO_15_DIRECTION {in} \
   CONFIG.PCW_MIO_15_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_15_PULLUP {enabled} \
   CONFIG.PCW_MIO_15_SLEW {slow} \
   CONFIG.PCW_MIO_16_DIRECTION {out} \
   CONFIG.PCW_MIO_16_IOTYPE {HSTL 1.8V} \
   CONFIG.PCW_MIO_16_PULLUP {disabled} \
   CONFIG.PCW_MIO_16_SLEW {slow} \
   CONFIG.PCW_MIO_17_DIRECTION {out} \
   CONFIG.PCW_MIO_17_IOTYPE {HSTL 1.8V} \
   CONFIG.PCW_MIO_17_PULLUP {disabled} \
   CONFIG.PCW_MIO_17_SLEW {slow} \
   CONFIG.PCW_MIO_18_DIRECTION {out} \
   CONFIG.PCW_MIO_18_IOTYPE {HSTL 1.8V} \
   CONFIG.PCW_MIO_18_PULLUP {disabled} \
   CONFIG.PCW_MIO_18_SLEW {slow} \
   CONFIG.PCW_MIO_19_DIRECTION {out} \
   CONFIG.PCW_MIO_19_IOTYPE {HSTL 1.8V} \
   CONFIG.PCW_MIO_19_PULLUP {disabled} \
   CONFIG.PCW_MIO_19_SLEW {slow} \
   CONFIG.PCW_MIO_1_DIRECTION {out} \
   CONFIG.PCW_MIO_1_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_1_PULLUP {enabled} \
   CONFIG.PCW_MIO_1_SLEW {slow} \
   CONFIG.PCW_MIO_20_DIRECTION {out} \
   CONFIG.PCW_MIO_20_IOTYPE {HSTL 1.8V} \
   CONFIG.PCW_MIO_20_PULLUP {disabled} \
   CONFIG.PCW_MIO_20_SLEW {slow} \
   CONFIG.PCW_MIO_21_DIRECTION {out} \
   CONFIG.PCW_MIO_21_IOTYPE {HSTL 1.8V} \
   CONFIG.PCW_MIO_21_PULLUP {disabled} \
   CONFIG.PCW_MIO_21_SLEW {slow} \
   CONFIG.PCW_MIO_22_DIRECTION {in} \
   CONFIG.PCW_MIO_22_IOTYPE {HSTL 1.8V} \
   CONFIG.PCW_MIO_22_PULLUP {disabled} \
   CONFIG.PCW_MIO_22_SLEW {slow} \
   CONFIG.PCW_MIO_23_DIRECTION {in} \
   CONFIG.PCW_MIO_23_IOTYPE {HSTL 1.8V} \
   CONFIG.PCW_MIO_23_PULLUP {disabled} \
   CONFIG.PCW_MIO_23_SLEW {slow} \
   CONFIG.PCW_MIO_24_DIRECTION {in} \
   CONFIG.PCW_MIO_24_IOTYPE {HSTL 1.8V} \
   CONFIG.PCW_MIO_24_PULLUP {disabled} \
   CONFIG.PCW_MIO_24_SLEW {slow} \
   CONFIG.PCW_MIO_25_DIRECTION {in} \
   CONFIG.PCW_MIO_25_IOTYPE {HSTL 1.8V} \
   CONFIG.PCW_MIO_25_PULLUP {disabled} \
   CONFIG.PCW_MIO_25_SLEW {slow} \
   CONFIG.PCW_MIO_26_DIRECTION {in} \
   CONFIG.PCW_MIO_26_IOTYPE {HSTL 1.8V} \
   CONFIG.PCW_MIO_26_PULLUP {disabled} \
   CONFIG.PCW_MIO_26_SLEW {slow} \
   CONFIG.PCW_MIO_27_DIRECTION {in} \
   CONFIG.PCW_MIO_27_IOTYPE {HSTL 1.8V} \
   CONFIG.PCW_MIO_27_PULLUP {disabled} \
   CONFIG.PCW_MIO_27_SLEW {slow} \
   CONFIG.PCW_MIO_28_DIRECTION {inout} \
   CONFIG.PCW_MIO_28_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_28_PULLUP {disabled} \
   CONFIG.PCW_MIO_28_SLEW {slow} \
   CONFIG.PCW_MIO_29_DIRECTION {in} \
   CONFIG.PCW_MIO_29_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_29_PULLUP {disabled} \
   CONFIG.PCW_MIO_29_SLEW {slow} \
   CONFIG.PCW_MIO_2_DIRECTION {inout} \
   CONFIG.PCW_MIO_2_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_2_PULLUP {disabled} \
   CONFIG.PCW_MIO_2_SLEW {slow} \
   CONFIG.PCW_MIO_30_DIRECTION {out} \
   CONFIG.PCW_MIO_30_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_30_PULLUP {disabled} \
   CONFIG.PCW_MIO_30_SLEW {slow} \
   CONFIG.PCW_MIO_31_DIRECTION {in} \
   CONFIG.PCW_MIO_31_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_31_PULLUP {disabled} \
   CONFIG.PCW_MIO_31_SLEW {slow} \
   CONFIG.PCW_MIO_32_DIRECTION {inout} \
   CONFIG.PCW_MIO_32_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_32_PULLUP {disabled} \
   CONFIG.PCW_MIO_32_SLEW {slow} \
   CONFIG.PCW_MIO_33_DIRECTION {inout} \
   CONFIG.PCW_MIO_33_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_33_PULLUP {disabled} \
   CONFIG.PCW_MIO_33_SLEW {slow} \
   CONFIG.PCW_MIO_34_DIRECTION {inout} \
   CONFIG.PCW_MIO_34_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_34_PULLUP {disabled} \
   CONFIG.PCW_MIO_34_SLEW {slow} \
   CONFIG.PCW_MIO_35_DIRECTION {inout} \
   CONFIG.PCW_MIO_35_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_35_PULLUP {disabled} \
   CONFIG.PCW_MIO_35_SLEW {slow} \
   CONFIG.PCW_MIO_36_DIRECTION {in} \
   CONFIG.PCW_MIO_36_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_36_PULLUP {disabled} \
   CONFIG.PCW_MIO_36_SLEW {slow} \
   CONFIG.PCW_MIO_37_DIRECTION {inout} \
   CONFIG.PCW_MIO_37_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_37_PULLUP {disabled} \
   CONFIG.PCW_MIO_37_SLEW {slow} \
   CONFIG.PCW_MIO_38_DIRECTION {inout} \
   CONFIG.PCW_MIO_38_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_38_PULLUP {disabled} \
   CONFIG.PCW_MIO_38_SLEW {slow} \
   CONFIG.PCW_MIO_39_DIRECTION {inout} \
   CONFIG.PCW_MIO_39_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_39_PULLUP {disabled} \
   CONFIG.PCW_MIO_39_SLEW {slow} \
   CONFIG.PCW_MIO_3_DIRECTION {inout} \
   CONFIG.PCW_MIO_3_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_3_PULLUP {disabled} \
   CONFIG.PCW_MIO_3_SLEW {slow} \
   CONFIG.PCW_MIO_40_DIRECTION {inout} \
   CONFIG.PCW_MIO_40_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_40_PULLUP {disabled} \
   CONFIG.PCW_MIO_40_SLEW {slow} \
   CONFIG.PCW_MIO_41_DIRECTION {inout} \
   CONFIG.PCW_MIO_41_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_41_PULLUP {disabled} \
   CONFIG.PCW_MIO_41_SLEW {slow} \
   CONFIG.PCW_MIO_42_DIRECTION {inout} \
   CONFIG.PCW_MIO_42_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_42_PULLUP {disabled} \
   CONFIG.PCW_MIO_42_SLEW {slow} \
   CONFIG.PCW_MIO_43_DIRECTION {inout} \
   CONFIG.PCW_MIO_43_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_43_PULLUP {disabled} \
   CONFIG.PCW_MIO_43_SLEW {slow} \
   CONFIG.PCW_MIO_44_DIRECTION {inout} \
   CONFIG.PCW_MIO_44_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_44_PULLUP {disabled} \
   CONFIG.PCW_MIO_44_SLEW {slow} \
   CONFIG.PCW_MIO_45_DIRECTION {inout} \
   CONFIG.PCW_MIO_45_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_45_PULLUP {disabled} \
   CONFIG.PCW_MIO_45_SLEW {slow} \
   CONFIG.PCW_MIO_46_DIRECTION {in} \
   CONFIG.PCW_MIO_46_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_46_PULLUP {enabled} \
   CONFIG.PCW_MIO_46_SLEW {slow} \
   CONFIG.PCW_MIO_47_DIRECTION {out} \
   CONFIG.PCW_MIO_47_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_47_PULLUP {enabled} \
   CONFIG.PCW_MIO_47_SLEW {slow} \
   CONFIG.PCW_MIO_48_DIRECTION {out} \
   CONFIG.PCW_MIO_48_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_48_PULLUP {disabled} \
   CONFIG.PCW_MIO_48_SLEW {slow} \
   CONFIG.PCW_MIO_49_DIRECTION {in} \
   CONFIG.PCW_MIO_49_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_49_PULLUP {disabled} \
   CONFIG.PCW_MIO_49_SLEW {slow} \
   CONFIG.PCW_MIO_4_DIRECTION {inout} \
   CONFIG.PCW_MIO_4_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_4_PULLUP {disabled} \
   CONFIG.PCW_MIO_4_SLEW {slow} \
   CONFIG.PCW_MIO_50_DIRECTION {inout} \
   CONFIG.PCW_MIO_50_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_50_PULLUP {enabled} \
   CONFIG.PCW_MIO_50_SLEW {slow} \
   CONFIG.PCW_MIO_51_DIRECTION {inout} \
   CONFIG.PCW_MIO_51_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_51_PULLUP {enabled} \
   CONFIG.PCW_MIO_51_SLEW {slow} \
   CONFIG.PCW_MIO_52_DIRECTION {out} \
   CONFIG.PCW_MIO_52_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_52_PULLUP {disabled} \
   CONFIG.PCW_MIO_52_SLEW {slow} \
   CONFIG.PCW_MIO_53_DIRECTION {inout} \
   CONFIG.PCW_MIO_53_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_53_PULLUP {disabled} \
   CONFIG.PCW_MIO_53_SLEW {slow} \
   CONFIG.PCW_MIO_5_DIRECTION {inout} \
   CONFIG.PCW_MIO_5_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_5_PULLUP {disabled} \
   CONFIG.PCW_MIO_5_SLEW {slow} \
   CONFIG.PCW_MIO_6_DIRECTION {out} \
   CONFIG.PCW_MIO_6_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_6_PULLUP {disabled} \
   CONFIG.PCW_MIO_6_SLEW {slow} \
   CONFIG.PCW_MIO_7_DIRECTION {out} \
   CONFIG.PCW_MIO_7_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_7_PULLUP {disabled} \
   CONFIG.PCW_MIO_7_SLEW {slow} \
   CONFIG.PCW_MIO_8_DIRECTION {out} \
   CONFIG.PCW_MIO_8_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_8_PULLUP {disabled} \
   CONFIG.PCW_MIO_8_SLEW {slow} \
   CONFIG.PCW_MIO_9_DIRECTION {inout} \
   CONFIG.PCW_MIO_9_IOTYPE {LVCMOS 1.8V} \
   CONFIG.PCW_MIO_9_PULLUP {enabled} \
   CONFIG.PCW_MIO_9_SLEW {slow} \
   CONFIG.PCW_MIO_TREE_PERIPHERALS {SD 0#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#USB Reset#Quad SPI Flash#GPIO#GPIO#ENET Reset#GPIO#I2C Reset#GPIO#SD 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#CAN 0#CAN 0#UART 1#UART 1#I2C 0#I2C 0#Enet 0#Enet 0} \
   CONFIG.PCW_MIO_TREE_SIGNALS {cd#qspi0_ss_b#qspi0_io[0]#qspi0_io[1]#qspi0_io[2]#qspi0_io[3]/HOLD_B#qspi0_sclk#reset#qspi_fbclk#gpio[9]#gpio[10]#reset#gpio[12]#reset#gpio[14]#wp#tx_clk#txd[0]#txd[1]#txd[2]#txd[3]#tx_ctl#rx_clk#rxd[0]#rxd[1]#rxd[2]#rxd[3]#rx_ctl#data[4]#dir#stp#nxt#data[0]#data[1]#data[2]#data[3]#clk#data[5]#data[6]#data[7]#clk#cmd#data[0]#data[1]#data[2]#data[3]#rx#tx#tx#rx#scl#sda#mdc#mdio} \
   CONFIG.PCW_NAND_GRP_D8_ENABLE {0} \
   CONFIG.PCW_NAND_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_A25_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_CS0_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_CS1_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_SRAM_CS0_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_SRAM_CS1_ENABLE {0} \
   CONFIG.PCW_NOR_GRP_SRAM_INT_ENABLE {0} \
   CONFIG.PCW_NOR_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_PCAP_PERIPHERAL_DIVISOR0 {5} \
   CONFIG.PCW_PJTAG_PERIPHERAL_ENABLE {0} \
   CONFIG.PCW_PRESET_BANK0_VOLTAGE {LVCMOS 1.8V} \
   CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V} \
   CONFIG.PCW_QSPI_GRP_FBCLK_ENABLE {1} \
   CONFIG.PCW_QSPI_GRP_FBCLK_IO {MIO 8} \
   CONFIG.PCW_QSPI_GRP_IO1_ENABLE {0} \
   CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1} \
   CONFIG.PCW_QSPI_GRP_SINGLE_SS_IO {MIO 1 .. 6} \
   CONFIG.PCW_QSPI_GRP_SS1_ENABLE {0} \
   CONFIG.PCW_QSPI_PERIPHERAL_DIVISOR0 {5} \
   CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_QSPI_PERIPHERAL_FREQMHZ {200} \
   CONFIG.PCW_QSPI_QSPI_IO {MIO 1 .. 6} \
   CONFIG.PCW_SD0_GRP_CD_ENABLE {1} \
   CONFIG.PCW_SD0_GRP_CD_IO {MIO 0} \
   CONFIG.PCW_SD0_GRP_POW_ENABLE {0} \
   CONFIG.PCW_SD0_GRP_WP_ENABLE {1} \
   CONFIG.PCW_SD0_GRP_WP_IO {MIO 15} \
   CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_SD0_SD0_IO {MIO 40 .. 45} \
   CONFIG.PCW_SDIO_PERIPHERAL_DIVISOR0 {20} \
   CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_SDIO_PERIPHERAL_VALID {1} \
   CONFIG.PCW_SINGLE_QSPI_DATA_MODE {x4} \
   CONFIG.PCW_SMC_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_SPI_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TPIU_PERIPHERAL_DIVISOR0 {1} \
   CONFIG.PCW_TTC0_CLK0_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC0_CLK1_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC0_CLK2_PERIPHERAL_FREQMHZ {133.333333} \
   CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_TTC0_TTC0_IO {EMIO} \
   CONFIG.PCW_TTC_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_UART1_GRP_FULL_ENABLE {0} \
   CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_UART1_UART1_IO {MIO 48 .. 49} \
   CONFIG.PCW_UART_PERIPHERAL_DIVISOR0 {20} \
   CONFIG.PCW_UART_PERIPHERAL_FREQMHZ {50} \
   CONFIG.PCW_UART_PERIPHERAL_VALID {1} \
   CONFIG.PCW_UIPARAM_ACT_DDR_FREQ_MHZ {533.333374} \
   CONFIG.PCW_UIPARAM_DDR_BANK_ADDR_COUNT {3} \
   CONFIG.PCW_UIPARAM_DDR_BL {8} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY0 {0.537} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY1 {0.442} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY2 {0.464} \
   CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY3 {0.521} \
   CONFIG.PCW_UIPARAM_DDR_CL {7} \
   CONFIG.PCW_UIPARAM_DDR_COL_ADDR_COUNT {10} \
   CONFIG.PCW_UIPARAM_DDR_CWL {6} \
   CONFIG.PCW_UIPARAM_DDR_DEVICE_CAPACITY {2048 MBits} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_0 {0.217} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_1 {0.133} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_2 {0.089} \
   CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_3 {0.248} \
   CONFIG.PCW_UIPARAM_DDR_DRAM_WIDTH {8 Bits} \
   CONFIG.PCW_UIPARAM_DDR_FREQ_MHZ {533.333333} \
   CONFIG.PCW_UIPARAM_DDR_MEMORY_TYPE {DDR 3} \
   CONFIG.PCW_UIPARAM_DDR_PARTNO {MT41J256M8 HX-15E} \
   CONFIG.PCW_UIPARAM_DDR_ROW_ADDR_COUNT {15} \
   CONFIG.PCW_UIPARAM_DDR_SPEED_BIN {DDR3_1066F} \
   CONFIG.PCW_UIPARAM_DDR_TRAIN_DATA_EYE {1} \
   CONFIG.PCW_UIPARAM_DDR_TRAIN_READ_GATE {1} \
   CONFIG.PCW_UIPARAM_DDR_TRAIN_WRITE_LEVEL {1} \
   CONFIG.PCW_UIPARAM_DDR_T_FAW {30.0} \
   CONFIG.PCW_UIPARAM_DDR_T_RAS_MIN {36.0} \
   CONFIG.PCW_UIPARAM_DDR_T_RC {49.5} \
   CONFIG.PCW_UIPARAM_DDR_T_RCD {7} \
   CONFIG.PCW_UIPARAM_DDR_T_RP {7} \
   CONFIG.PCW_UIPARAM_DDR_USE_INTERNAL_VREF {1} \
   CONFIG.PCW_USB0_PERIPHERAL_ENABLE {1} \
   CONFIG.PCW_USB0_PERIPHERAL_FREQMHZ {60} \
   CONFIG.PCW_USB0_RESET_ENABLE {1} \
   CONFIG.PCW_USB0_RESET_IO {MIO 7} \
   CONFIG.PCW_USB0_USB0_IO {MIO 28 .. 39} \
   CONFIG.PCW_USB1_RESET_ENABLE {0} \
   CONFIG.PCW_USB_RESET_ENABLE {1} \
   CONFIG.PCW_USB_RESET_SELECT {Share reset pin} \
   CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
   CONFIG.PCW_USE_M_AXI_GP0 {1} \
   CONFIG.PCW_USE_S_AXI_HP0 {1} \
   CONFIG.PCW_USE_S_AXI_HP1 {1} \
   CONFIG.PCW_USE_S_AXI_HP2 {1} \
   CONFIG.PCW_USE_S_AXI_HP3 {1} \
   CONFIG.preset {ZC702} \
 ] $ps7

  # Create instance: sds_irq_const, and set properties
  set sds_irq_const [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 sds_irq_const ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {1} \
 ] $sds_irq_const

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {16} \
 ] $xlconcat_0

  # Create interface connections
  connect_bd_intf_net -intf_net axi_ic_ps7_M_AXI_GP0_M00_AXI [get_bd_intf_pins axi_ic_ps7_M_AXI_GP0/M00_AXI] [get_bd_intf_pins gemm_hw_1_if/S_AXI]
  connect_bd_intf_net -intf_net axi_ic_ps7_M_AXI_GP0_M01_AXI [get_bd_intf_pins axi_ic_ps7_M_AXI_GP0/M01_AXI] [get_bd_intf_pins dm_0/S_AXI_LITE]
  connect_bd_intf_net -intf_net axi_ic_ps7_M_AXI_GP0_M02_AXI [get_bd_intf_pins axi_ic_ps7_M_AXI_GP0/M02_AXI] [get_bd_intf_pins dm_1/S_AXI_LITE]
  connect_bd_intf_net -intf_net axi_ic_ps7_M_AXI_GP0_M03_AXI [get_bd_intf_pins axi_ic_ps7_M_AXI_GP0/M03_AXI] [get_bd_intf_pins dm_2/S_AXI_LITE]
  connect_bd_intf_net -intf_net axi_ic_ps7_M_AXI_GP0_M04_AXI [get_bd_intf_pins axi_ic_ps7_M_AXI_GP0/M04_AXI] [get_bd_intf_pins dm_3/S_AXI_LITE]
  connect_bd_intf_net -intf_net axi_ic_ps7_S_AXI_HP0_M00_AXI [get_bd_intf_pins axi_ic_ps7_S_AXI_HP0/M00_AXI] [get_bd_intf_pins ps7/S_AXI_HP0]
  connect_bd_intf_net -intf_net axi_ic_ps7_S_AXI_HP1_M00_AXI [get_bd_intf_pins axi_ic_ps7_S_AXI_HP1/M00_AXI] [get_bd_intf_pins ps7/S_AXI_HP1]
  connect_bd_intf_net -intf_net axi_ic_ps7_S_AXI_HP2_M00_AXI [get_bd_intf_pins axi_ic_ps7_S_AXI_HP2/M00_AXI] [get_bd_intf_pins ps7/S_AXI_HP2]
  connect_bd_intf_net -intf_net axi_ic_ps7_S_AXI_HP3_M00_AXI [get_bd_intf_pins axi_ic_ps7_S_AXI_HP3/M00_AXI] [get_bd_intf_pins ps7/S_AXI_HP3]
  connect_bd_intf_net -intf_net axis_dwc_dm_0_tx_0_M_AXIS [get_bd_intf_pins axis_dwc_dm_0_tx_0/M_AXIS] [get_bd_intf_pins gemm_hw_1_if/S_AXIS_FIFO_0]
  connect_bd_intf_net -intf_net axis_dwc_dm_1_tx_0_M_AXIS [get_bd_intf_pins axis_dwc_dm_1_tx_0/M_AXIS] [get_bd_intf_pins gemm_hw_1_if/S_AXIS_FIFO_1]
  connect_bd_intf_net -intf_net axis_dwc_dm_2_tx_0_M_AXIS [get_bd_intf_pins axis_dwc_dm_2_tx_0/M_AXIS] [get_bd_intf_pins gemm_hw_1_if/S_AXIS_FIFO_2]
  connect_bd_intf_net -intf_net axis_dwc_dm_3_rx_0_M_AXIS [get_bd_intf_pins axis_dwc_dm_3_rx_0/M_AXIS] [get_bd_intf_pins dm_3/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net dm_0_M_AXIS_MM2S [get_bd_intf_pins axis_dwc_dm_0_tx_0/S_AXIS] [get_bd_intf_pins dm_0/M_AXIS_MM2S]
  connect_bd_intf_net -intf_net dm_0_M_AXI_MM2S [get_bd_intf_pins axi_ic_ps7_S_AXI_HP2/S00_AXI] [get_bd_intf_pins dm_0/M_AXI_MM2S]
  connect_bd_intf_net -intf_net dm_1_M_AXIS_MM2S [get_bd_intf_pins axis_dwc_dm_1_tx_0/S_AXIS] [get_bd_intf_pins dm_1/M_AXIS_MM2S]
  connect_bd_intf_net -intf_net dm_1_M_AXI_MM2S [get_bd_intf_pins axi_ic_ps7_S_AXI_HP1/S00_AXI] [get_bd_intf_pins dm_1/M_AXI_MM2S]
  connect_bd_intf_net -intf_net dm_2_M_AXIS_MM2S [get_bd_intf_pins axis_dwc_dm_2_tx_0/S_AXIS] [get_bd_intf_pins dm_2/M_AXIS_MM2S]
  connect_bd_intf_net -intf_net dm_2_M_AXI_MM2S [get_bd_intf_pins axi_ic_ps7_S_AXI_HP0/S00_AXI] [get_bd_intf_pins dm_2/M_AXI_MM2S]
  connect_bd_intf_net -intf_net dm_3_M_AXI_S2MM [get_bd_intf_pins axi_ic_ps7_S_AXI_HP3/S00_AXI] [get_bd_intf_pins dm_3/M_AXI_S2MM]
  connect_bd_intf_net -intf_net gemm_hw_1_A [get_bd_intf_pins gemm_hw_1/A] [get_bd_intf_pins gemm_hw_1_if/AP_FIFO_IARG_0]
  connect_bd_intf_net -intf_net gemm_hw_1_B [get_bd_intf_pins gemm_hw_1/B] [get_bd_intf_pins gemm_hw_1_if/AP_FIFO_IARG_1]
  connect_bd_intf_net -intf_net gemm_hw_1_C [get_bd_intf_pins gemm_hw_1/C] [get_bd_intf_pins gemm_hw_1_if/AP_FIFO_OARG_0]
  connect_bd_intf_net -intf_net gemm_hw_1_bscale [get_bd_intf_pins gemm_hw_1/bscale] [get_bd_intf_pins gemm_hw_1_if/AP_FIFO_IARG_2]
  connect_bd_intf_net -intf_net gemm_hw_1_if_M_AXIS_FIFO_0 [get_bd_intf_pins axis_dwc_dm_3_rx_0/S_AXIS] [get_bd_intf_pins gemm_hw_1_if/M_AXIS_FIFO_0]
  connect_bd_intf_net -intf_net gemm_hw_1_if_ap_ctrl [get_bd_intf_pins gemm_hw_1/ap_ctrl] [get_bd_intf_pins gemm_hw_1_if/ap_ctrl]
  connect_bd_intf_net -intf_net ps7_DDR [get_bd_intf_ports DDR] [get_bd_intf_pins ps7/DDR]
  connect_bd_intf_net -intf_net ps7_FIXED_IO [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins ps7/FIXED_IO]
  connect_bd_intf_net -intf_net ps7_M_AXI_GP0 [get_bd_intf_pins axi_ic_ps7_M_AXI_GP0/S00_AXI] [get_bd_intf_pins ps7/M_AXI_GP0]

  # Create port connections
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins axi_ic_ps7_M_AXI_GP0/ACLK] [get_bd_pins axi_ic_ps7_M_AXI_GP0/M00_ACLK] [get_bd_pins axi_ic_ps7_M_AXI_GP0/M01_ACLK] [get_bd_pins axi_ic_ps7_M_AXI_GP0/M02_ACLK] [get_bd_pins axi_ic_ps7_M_AXI_GP0/M03_ACLK] [get_bd_pins axi_ic_ps7_M_AXI_GP0/M04_ACLK] [get_bd_pins axi_ic_ps7_M_AXI_GP0/S00_ACLK] [get_bd_pins axi_ic_ps7_S_AXI_HP0/ACLK] [get_bd_pins axi_ic_ps7_S_AXI_HP0/M00_ACLK] [get_bd_pins axi_ic_ps7_S_AXI_HP0/S00_ACLK] [get_bd_pins axi_ic_ps7_S_AXI_HP1/ACLK] [get_bd_pins axi_ic_ps7_S_AXI_HP1/M00_ACLK] [get_bd_pins axi_ic_ps7_S_AXI_HP1/S00_ACLK] [get_bd_pins axi_ic_ps7_S_AXI_HP2/ACLK] [get_bd_pins axi_ic_ps7_S_AXI_HP2/M00_ACLK] [get_bd_pins axi_ic_ps7_S_AXI_HP2/S00_ACLK] [get_bd_pins axi_ic_ps7_S_AXI_HP3/ACLK] [get_bd_pins axi_ic_ps7_S_AXI_HP3/M00_ACLK] [get_bd_pins axi_ic_ps7_S_AXI_HP3/S00_ACLK] [get_bd_pins axis_dwc_dm_0_tx_0/aclk] [get_bd_pins axis_dwc_dm_1_tx_0/aclk] [get_bd_pins axis_dwc_dm_2_tx_0/aclk] [get_bd_pins axis_dwc_dm_3_rx_0/aclk] [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins dm_0/m_axi_mm2s_aclk] [get_bd_pins dm_0/s_axi_lite_aclk] [get_bd_pins dm_1/m_axi_mm2s_aclk] [get_bd_pins dm_1/s_axi_lite_aclk] [get_bd_pins dm_2/m_axi_mm2s_aclk] [get_bd_pins dm_2/s_axi_lite_aclk] [get_bd_pins dm_3/m_axi_s2mm_aclk] [get_bd_pins dm_3/s_axi_lite_aclk] [get_bd_pins gemm_hw_1_if/acc_aclk] [get_bd_pins gemm_hw_1_if/m_axis_fifo_0_aclk] [get_bd_pins gemm_hw_1_if/s_axi_aclk] [get_bd_pins gemm_hw_1_if/s_axis_fifo_0_aclk] [get_bd_pins gemm_hw_1_if/s_axis_fifo_1_aclk] [get_bd_pins gemm_hw_1_if/s_axis_fifo_2_aclk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins ps7/M_AXI_GP0_ACLK] [get_bd_pins ps7/S_AXI_HP0_ACLK] [get_bd_pins ps7/S_AXI_HP1_ACLK] [get_bd_pins ps7/S_AXI_HP2_ACLK] [get_bd_pins ps7/S_AXI_HP3_ACLK]
  connect_bd_net -net clk_wiz_0_clk_out2 [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins proc_sys_reset_1/slowest_sync_clk]
  connect_bd_net -net clk_wiz_0_clk_out3 [get_bd_pins clk_wiz_0/clk_out3] [get_bd_pins proc_sys_reset_2/slowest_sync_clk]
  connect_bd_net -net clk_wiz_0_clk_out4 [get_bd_pins clk_wiz_0/clk_out4] [get_bd_pins proc_sys_reset_3/slowest_sync_clk]
  connect_bd_net -net clk_wiz_0_clk_out5 [get_bd_pins clk_wiz_0/clk_out5] [get_bd_pins proc_sys_reset_4/slowest_sync_clk]
  connect_bd_net -net clk_wiz_0_clk_out6 [get_bd_pins clk_wiz_0/clk_out6] [get_bd_pins proc_sys_reset_5/slowest_sync_clk]
  connect_bd_net -net clk_wiz_0_locked [get_bd_pins clk_wiz_0/locked] [get_bd_pins proc_sys_reset_0/dcm_locked] [get_bd_pins proc_sys_reset_1/dcm_locked] [get_bd_pins proc_sys_reset_2/dcm_locked] [get_bd_pins proc_sys_reset_3/dcm_locked] [get_bd_pins proc_sys_reset_4/dcm_locked] [get_bd_pins proc_sys_reset_5/dcm_locked]
  connect_bd_net -net gemm_hw_1_if_ap_clk [get_bd_pins gemm_hw_1/ap_clk] [get_bd_pins gemm_hw_1_if/ap_clk]
  connect_bd_net -net gemm_hw_1_if_ap_iscalar_0_dout [get_bd_pins gemm_hw_1/arow] [get_bd_pins gemm_hw_1_if/ap_iscalar_0_dout]
  connect_bd_net -net gemm_hw_1_if_ap_iscalar_1_dout [get_bd_pins gemm_hw_1/brow] [get_bd_pins gemm_hw_1_if/ap_iscalar_1_dout]
  connect_bd_net -net gemm_hw_1_if_ap_iscalar_2_dout [get_bd_pins gemm_hw_1/ccol] [get_bd_pins gemm_hw_1_if/ap_iscalar_2_dout]
  connect_bd_net -net gemm_hw_1_if_ap_iscalar_3_dout [get_bd_pins gemm_hw_1/acopy] [get_bd_pins gemm_hw_1_if/ap_iscalar_3_dout]
  connect_bd_net -net gemm_hw_1_if_ap_iscalar_4_dout [get_bd_pins gemm_hw_1/batch] [get_bd_pins gemm_hw_1_if/ap_iscalar_4_dout]
  connect_bd_net -net gemm_hw_1_if_ap_iscalar_5_dout [get_bd_pins gemm_hw_1/ctrl] [get_bd_pins gemm_hw_1_if/ap_iscalar_5_dout]
  connect_bd_net -net gemm_hw_1_if_ap_iscalar_6_dout [get_bd_pins gemm_hw_1/TAw] [get_bd_pins gemm_hw_1_if/ap_iscalar_6_dout]
  connect_bd_net -net gemm_hw_1_if_ap_iscalar_7_dout [get_bd_pins gemm_hw_1/TAr] [get_bd_pins gemm_hw_1_if/ap_iscalar_7_dout]
  connect_bd_net -net gemm_hw_1_if_ap_iscalar_8_dout [get_bd_pins gemm_hw_1/ascale] [get_bd_pins gemm_hw_1_if/ap_iscalar_8_dout]
  connect_bd_net -net gemm_hw_1_if_ap_resetn [get_bd_pins gemm_hw_1/ap_rst_n] [get_bd_pins gemm_hw_1_if/ap_resetn]
  connect_bd_net -net proc_sys_reset_0_interconnect_aresetn [get_bd_pins axi_ic_ps7_M_AXI_GP0/ARESETN] [get_bd_pins axi_ic_ps7_M_AXI_GP0/M00_ARESETN] [get_bd_pins axi_ic_ps7_M_AXI_GP0/M01_ARESETN] [get_bd_pins axi_ic_ps7_M_AXI_GP0/M02_ARESETN] [get_bd_pins axi_ic_ps7_M_AXI_GP0/M03_ARESETN] [get_bd_pins axi_ic_ps7_M_AXI_GP0/M04_ARESETN] [get_bd_pins axi_ic_ps7_M_AXI_GP0/S00_ARESETN] [get_bd_pins axi_ic_ps7_S_AXI_HP0/ARESETN] [get_bd_pins axi_ic_ps7_S_AXI_HP0/M00_ARESETN] [get_bd_pins axi_ic_ps7_S_AXI_HP0/S00_ARESETN] [get_bd_pins axi_ic_ps7_S_AXI_HP1/ARESETN] [get_bd_pins axi_ic_ps7_S_AXI_HP1/M00_ARESETN] [get_bd_pins axi_ic_ps7_S_AXI_HP1/S00_ARESETN] [get_bd_pins axi_ic_ps7_S_AXI_HP2/ARESETN] [get_bd_pins axi_ic_ps7_S_AXI_HP2/M00_ARESETN] [get_bd_pins axi_ic_ps7_S_AXI_HP2/S00_ARESETN] [get_bd_pins axi_ic_ps7_S_AXI_HP3/ARESETN] [get_bd_pins axi_ic_ps7_S_AXI_HP3/M00_ARESETN] [get_bd_pins axi_ic_ps7_S_AXI_HP3/S00_ARESETN] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins axis_dwc_dm_0_tx_0/aresetn] [get_bd_pins axis_dwc_dm_1_tx_0/aresetn] [get_bd_pins axis_dwc_dm_2_tx_0/aresetn] [get_bd_pins axis_dwc_dm_3_rx_0/aresetn] [get_bd_pins dm_0/axi_resetn] [get_bd_pins dm_1/axi_resetn] [get_bd_pins dm_2/axi_resetn] [get_bd_pins dm_3/axi_resetn] [get_bd_pins gemm_hw_1_if/acc_aresetn] [get_bd_pins gemm_hw_1_if/m_axis_fifo_0_aresetn] [get_bd_pins gemm_hw_1_if/s_axi_aresetn] [get_bd_pins gemm_hw_1_if/s_axis_fifo_0_aresetn] [get_bd_pins gemm_hw_1_if/s_axis_fifo_1_aresetn] [get_bd_pins gemm_hw_1_if/s_axis_fifo_2_aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
  connect_bd_net -net ps7_FCLK_CLK0 [get_bd_pins clk_wiz_0/clk_in1] [get_bd_pins ps7/FCLK_CLK0]
  connect_bd_net -net ps7_FCLK_RESET0_N [get_bd_pins clk_wiz_0/resetn] [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins proc_sys_reset_1/ext_reset_in] [get_bd_pins proc_sys_reset_2/ext_reset_in] [get_bd_pins proc_sys_reset_3/ext_reset_in] [get_bd_pins proc_sys_reset_4/ext_reset_in] [get_bd_pins proc_sys_reset_5/ext_reset_in] [get_bd_pins ps7/FCLK_RESET0_N]
  connect_bd_net -net sds_irq_const_dout [get_bd_pins sds_irq_const/dout] [get_bd_pins xlconcat_0/In0] [get_bd_pins xlconcat_0/In1] [get_bd_pins xlconcat_0/In2] [get_bd_pins xlconcat_0/In3] [get_bd_pins xlconcat_0/In4] [get_bd_pins xlconcat_0/In5] [get_bd_pins xlconcat_0/In6] [get_bd_pins xlconcat_0/In7] [get_bd_pins xlconcat_0/In8] [get_bd_pins xlconcat_0/In9] [get_bd_pins xlconcat_0/In10] [get_bd_pins xlconcat_0/In11] [get_bd_pins xlconcat_0/In12] [get_bd_pins xlconcat_0/In13] [get_bd_pins xlconcat_0/In14] [get_bd_pins xlconcat_0/In15]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins ps7/IRQ_F2P] [get_bd_pins xlconcat_0/dout]

  # Create address segments
  create_bd_addr_seg -range 0x40000000 -offset 0x00000000 [get_bd_addr_spaces dm_0/Data_MM2S] [get_bd_addr_segs ps7/S_AXI_HP2/HP2_DDR_LOWOCM] SEG_ps7_HP2_DDR_LOWOCM
  create_bd_addr_seg -range 0x40000000 -offset 0x00000000 [get_bd_addr_spaces dm_1/Data_MM2S] [get_bd_addr_segs ps7/S_AXI_HP1/HP1_DDR_LOWOCM] SEG_ps7_HP1_DDR_LOWOCM
  create_bd_addr_seg -range 0x40000000 -offset 0x00000000 [get_bd_addr_spaces dm_2/Data_MM2S] [get_bd_addr_segs ps7/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_ps7_HP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x40000000 -offset 0x00000000 [get_bd_addr_spaces dm_3/Data_S2MM] [get_bd_addr_segs ps7/S_AXI_HP3/HP3_DDR_LOWOCM] SEG_ps7_HP3_DDR_LOWOCM
  create_bd_addr_seg -range 0x00010000 -offset 0x40400000 [get_bd_addr_spaces ps7/Data] [get_bd_addr_segs dm_0/S_AXI_LITE/Reg] SEG_dm_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40410000 [get_bd_addr_spaces ps7/Data] [get_bd_addr_segs dm_1/S_AXI_LITE/Reg] SEG_dm_1_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40420000 [get_bd_addr_spaces ps7/Data] [get_bd_addr_segs dm_2/S_AXI_LITE/Reg] SEG_dm_2_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40430000 [get_bd_addr_spaces ps7/Data] [get_bd_addr_segs dm_3/S_AXI_LITE/Reg] SEG_dm_3_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x43C00000 [get_bd_addr_spaces ps7/Data] [get_bd_addr_segs gemm_hw_1_if/S_AXI/reg0] SEG_gemm_hw_1_if_reg0


  # Restore current instance
  current_bd_instance $oldCurInst

  # Create PFM attributes
  set_property PFM_NAME {xilinx.com:zc702:zc702:1.0} [get_files [current_bd_design].bd]
  set_property PFM.CLOCK {  clk_out1 {id "2" is_default "true" proc_sys_reset "proc_sys_reset_0" }  clk_out2 {id "1" is_default "false" proc_sys_reset "proc_sys_reset_1" }  clk_out3 {id "0" is_default "false" proc_sys_reset "proc_sys_reset_2" }  clk_out4 {id "3" is_default "false" proc_sys_reset "proc_sys_reset_3" }  clk_out5 {id "4" is_default "false" proc_sys_reset "proc_sys_reset_4" }  clk_out6 {id "5" is_default "false" proc_sys_reset "proc_sys_reset_5" }  } [get_bd_cells /clk_wiz_0]
  set_property PFM.AXI_PORT {  M_AXI_GP0 {memport "M_AXI_GP" sptag "GP"}  M_AXI_GP1 {memport "M_AXI_GP" sptag "GP"}  S_AXI_ACP {memport "S_AXI_ACP" sptag "ACP" memory "ps7 ACP_DDR_LOWOCM"}  S_AXI_HP0 {memport "S_AXI_HP" sptag "HP" memory "ps7 HP0_DDR_LOWOCM"}  S_AXI_HP1 {memport "S_AXI_HP" sptag "HP" memory "ps7 HP1_DDR_LOWOCM"}  S_AXI_HP2 {memport "S_AXI_HP" sptag "HP" memory "ps7 HP2_DDR_LOWOCM"}  S_AXI_HP3 {memport "S_AXI_HP" sptag "HP" memory "ps7 HP3_DDR_LOWOCM"}  } [get_bd_cells /ps7]
  set_property PFM.IRQ {In0 {} In1 {} In2 {} In3 {} In4 {} In5 {} In6 {} In7 {} In8 {} In9 {} In10 {} In11 {} In12 {} In13 {} In14 {} In15 {}} [get_bd_cells /xlconcat_0]


  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


