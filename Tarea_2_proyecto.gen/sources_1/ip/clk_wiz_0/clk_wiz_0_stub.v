// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.1 (win64) Build 6140274 Thu May 22 00:12:29 MDT 2025
// Date        : Fri Mar 20 01:27:28 2026
// Host        : BastiPC running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub {d:/Xilinx/git tarea
//               4/T4-IPD432-Bastian-Rivas/Tarea_2_proyecto.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_stub.v}
// Design      : clk_wiz_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* CORE_GENERATION_INFO = "clk_wiz_0,clk_wiz_v6_0_16_0_0,{component_name=clk_wiz_0,use_phase_alignment=true,use_min_o_jitter=false,use_max_i_jitter=false,use_dyn_phase_shift=false,use_inclk_switchover=false,use_dyn_reconfig=false,enable_axi=0,feedback_source=FDBK_AUTO,PRIMITIVE=MMCM,num_out_clk=3,clkin1_period=10.000,clkin2_period=10.000,use_power_down=false,use_reset=true,use_locked=false,use_inclk_stopped=false,feedback_type=SINGLE,CLOCK_MGR_TYPE=NA,manual_override=false}" *) 
module clk_wiz_0(input_domain_clk, ctrl_domain_clk, 
  output_domain_clk, reset, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="reset,clk_in1" */
/* synthesis syn_force_seq_prim="input_domain_clk" */
/* synthesis syn_force_seq_prim="ctrl_domain_clk" */
/* synthesis syn_force_seq_prim="output_domain_clk" */;
  output input_domain_clk /* synthesis syn_isclock = 1 */;
  output ctrl_domain_clk /* synthesis syn_isclock = 1 */;
  output output_domain_clk /* synthesis syn_isclock = 1 */;
  input reset;
  input clk_in1;
endmodule
