module mycpu_top (
     input[5:0]  int,   //high active

     input aclk,
     input aresetn,   //low active

     output[3:0]      arid,
     output[31:0]     araddr,
     output[7:0]      arlen,
     output[2:0]      arsize,
     output[1:0]      arburst,
     output[1:0]      arlock,
     output[3:0]      arcache,
     output[2:0]      arprot,
     output           arvalid,
     input            arready,
                
     input[3:0]       rid,
     input[31:0]      rdata,
     input[1:0]       rresp,
     input            rlast,
     input            rvalid,
     output           rready,
               
     output[3:0]      awid,
     output[31:0]     awaddr,
     output[7:0]      awlen,
     output[2:0]      awsize,
     output[1:0]      awburst,
     output[1:0]      awlock,
     output[3:0]      awcache,
     output[2:0]      awprot,
     output           awvalid,
     input            awready,
    
     output[3:0]      wid,
     output[31:0]     wdata,
     output[3:0]      wstrb,
     output           wlast,
     output           wvalid,
     input            wready,
    
     input[3:0]       bid,
     input[1:0]       bresp,
     input            bvalid,
     output           bready,

    //debug interface
     output[31:0]     debug_wb_pc,
     output [3:0]     debug_wb_rf_wen,
     output [4:0]     debug_wb_rf_wnum,
     output[31:0]     debug_wb_rf_wdata 
);
    wire 	          reset;
    assign reset = ~aresetn;
    wire [31:0]       pc;
    wire [31:0]       pc_next;
    wire [31:0]       dec_inst;
    wire [31:0]       dec_pcplus4;
    wire [31:0]       dec_pcplus8;
    wire [31:0]       dec_pc;
    wire              dec_exception_if_exchappen;
    wire [31:0]       dec_exception_if_epc;
    wire              dec_exception_if_bd;
    wire [31:0]       dec_exception_if_badvaddr;
    wire [4:0]        dec_exception_if_exccode;   

    wire              eret_flush;
    wire              bd;
    wire              pc_wren;
    wire              dec_wren;
    wire              harzard_flush_mem;
    wire              inst_jr;
    wire [31:0]       sign_imm32;
    wire [25:0]       imm26;
    wire [2:0]        branch;
    wire              inst_eret;
    wire  [4:0]       regfile_rs_addr;
    wire  [4:0]       regfile_rt_addr;
    wire  [4:0]       cp0_read_addr;
    wire [31:0]       exe_pcplus4;
    wire [31:0]       exe_pcplus8;
    wire [31:0]       exe_pc;
    wire              exe_regfile_wren;
    wire [4:0]        exe_regfile_wt_addr;
    wire              exe_regfile_mem2reg;
    wire [31:0]       exe_regfile_rs_read_val;
    wire [31:0]       exe_regfile_rt_read_val;
    wire [4:0]        exe_regfile_aluctr;
    wire [31:0]       exe_sra_left;
    wire [31:0]       exe_sra_right;
    wire [31:0]       exe_srav_left;
    wire [31:0]       exe_srav_right;
    wire [31:0]       exe_add_val;
    wire [31:0]       exe_addi_val;
    wire [31:0]       exe_sub_val;
    wire [31:0]       exe_subi_val;
    wire              exe_hi_wren;
    wire [31:0]       exe_hi_read_val;
    wire              exe_lo_wren;
    wire [31:0]       exe_lo_read_val;
    wire [2:0]        exe_hilo_aluctr;
    wire              exe_cp0_wren;
    wire [4:0]        exe_cp0_wt_addr;
    wire [31:0]       exe_cp0_wt_val;
    wire [31:0]       exe_cp0_read_val;
    wire [31:0]       exe_sign_imm32;
    wire [31:0]       exe_unsign_imm32;
    wire [2:0]        exe_branch;
    wire              exe_inst_jr;
    wire [31:0]       exe_branch_address;
    wire [31:0]       exe_jump_address;
    wire              exe_start_div;
    wire              exe_start_mult;
    wire [2:0]        exe_lw_sw_type;
    wire              exe_dmm_read;
    wire              exe_dmm_write;
    wire              exe_exception_if_exchappen;
    wire [31:0]       exe_exception_if_epc;
    wire              exe_exception_if_bd;
    wire [31:0]       exe_exception_if_badvaddr;
    wire [4:0]        exe_exception_if_exccode;
    wire              exe_exception_dec_exchappen;
    wire [4:0]        exe_exception_dec_exccode;

    wire              complete;
    wire [31:0]       regfile_wt_val;
    wire [31:0]       hi_wt_val;
    wire [31:0]       lo_wt_val;
    wire [31:0]       cp0_wt_val;
    wire [31:0]       mem_pc;
    wire              mem_regfile_wren;
    wire [4:0]        mem_regfile_wt_addr;
    wire              mem_regfile_mem2reg;
    wire [31:0]       mem_regfile_wt_val;
	wire [31:0]		  mem_regfile_wt_val_mux;
    wire [31:0]       mem_regfile_rt_read_val;
    wire              mem_cp0_wren;
    wire [4:0]        mem_cp0_wt_addr;
    wire [31:0]       mem_cp0_wt_val;
    wire [2:0]        mem_lw_sw_type;
    wire [31:0]       mem_dmm_addr;
    wire              mem_dmm_read;
    wire              mem_dmm_write;
    wire [3:0]        mem_dmm_byte_enable;
    wire              mem_exception_if_exchappen;
    wire [31:0]       mem_exception_if_epc;
    wire              mem_exception_if_bd;
    wire [31:0]       mem_exception_if_badvaddr;
    wire [4:0]        mem_exception_if_exccode;
    wire              mem_exception_dec_exchappen;
    wire [4:0]        mem_exception_dec_exccode;
    wire              mem_exception_exe_exchappen;
    wire [4:0]        mem_exception_exe_exccode;

    wire                  confreg_valid;
    wire                  dcache_valid;
    wire [31:0]           dmm_addr;
    wire [31:0]           dmm_store_val;
    wire [3:0]            dmm_byte_enable;
    wire                  exception_flush;
    wire                  exception_inst_interrupt;
    wire                  wb_exception_inst_exchappen;
    wire [31:0]           wb_exception_inst_epc;
    wire                  wb_exception_inst_bd;
    wire [31:0]           wb_exception_inst_badvaddr;
    wire                  wb_exception_inst_badvaddr_wren;
    wire [4:0]            wb_exception_inst_exccode;
    wire [31:0]           wb_pc;
    wire                  wb_regfile_wren;
    wire [4:0]            wb_regfile_wt_addr;
    wire [31:0]           wb_regfile_wt_val_mux;
    wire                  wb_regfile_mem2reg;
    wire [31:0]           wb_regfile_wt_val;
    wire [31:0]           wb_dmm_load_val;
    wire [3:0]            wb_dmm_byte_enable;
    wire [2:0]            wb_lw_sw_type;
    wire                  wb_cp0_wren;
    wire [4:0]            wb_cp0_wt_addr;
    wire [31:0]           wb_cp0_wt_val;

    wire [31:0]           wb_refile_wt_val_mux;

    wire [1:0]  	       PCSrc;
    wire [31:0]	           branch_target;
    wire                   branch_flush;
    
    wire [31:0]           hi_read_val;
    wire [31:0]           lo_read_val;

    wire [31:0]           cp0_read_val;
    wire [31:0]           cp0_status_val;
    wire [31:0]           cp0_epc_val;
    wire                  cp0_status_ie;
    wire                  cp0_status_exl;
    wire                  cp0_status_im0;
    wire                  cp0_status_im1;
    wire                  cp0_cause_ip0;
    wire                  cp0_cause_ip1;

    wire [20:0]           rd_tab;
    wire [20:0]           mem_rd_tab;
wire valid;
wire        ready;
wire [31:0] icache_inst;
wire [31:0] dmm_load_val;
wire [3:0]  arlen_tmp;
assign arlen = {4'b0, arlen_tmp};

wire        write_confreg;
wire        confreg_ready;
wire[31:0]  mem_rdata_C;
wire[31:0]  mem_rdata_D;
wire        exception_inst_exchappen;


 wire [31:0]              regfile_rs_read_val; 
 wire [31:0]              regfile_rt_read_val;


if_stage IF(
         .clk(aclk),
         .reset(reset),
         .PCSrc(PCSrc),
         .branch_target(branch_target),
         .cp0_epc_val(cp0_epc_val),
         .pc_wren(pc_wren),
         .dec_wren(dec_wren),
         .ready(ready),
         .complete(complete),
         .exception_flush(exception_flush),
         .branch_flush(branch_flush),
         .eret_flush(eret_flush),
         .bd(bd),
         .icache_inst(icache_inst),

         .pc(pc),
         .pc_next(pc_next),
         .dec_inst(dec_inst),
         .dec_pcplus4(dec_pcplus4),
         .dec_pcplus8(dec_pcplus8),
         .dec_pc(dec_pc),
         .dec_exception_if_exchappen(dec_exception_if_exchappen),
         .dec_exception_if_epc(dec_exception_if_epc),
         .dec_exception_if_bd(dec_exception_if_bd),
         .dec_exception_if_badvaddr(dec_exception_if_badvaddr),
         .dec_exception_if_exccode(dec_exception_if_exccode)  
);

 dec_stage DEC (
       .clk(aclk),
       .reset(reset),
       .dec_inst(dec_inst),
       .dec_pcplus4(dec_pcplus4),
       .dec_pcplus8(dec_pcplus8),
       .dec_pc(dec_pc),
       .dec_exception_if_exchappen(dec_exception_if_exchappen),
       .dec_exception_if_epc(dec_exception_if_epc),
       .dec_exception_if_bd(dec_exception_if_bd),
       .dec_exception_if_badvaddr(dec_exception_if_badvaddr),
       .dec_exception_if_exccode(dec_exception_if_exccode),
       .ready(ready),
       .complete(complete),
       .exception_flush(exception_flush),
       .branch_flush(1'b0),
       .regfile_rs_read_val(regfile_rs_read_val),
       .regfile_rt_read_val(regfile_rt_read_val),
       .hi_read_val(hi_read_val),
       .lo_read_val(lo_read_val),
       .cp0_read_val(cp0_read_val),
       .cp0_status_val(cp0_status_val),
       .mem_dmm_read(mem_dmm_read),
       .mem_regfile_wt_addr(mem_regfile_wt_addr),
	   .mem_lw_sw_type(mem_lw_sw_type),

       .eret_flush(eret_flush),
       .bd(bd),
       .pc_wren(pc_wren),
       .dec_wren(dec_wren),
       .harzard_flush_mem(harzard_flush_mem),
       .inst_eret(inst_eret),
       .regfile_rs_addr(regfile_rs_addr),
       .regfile_rt_addr(regfile_rt_addr),
       .cp0_read_addr(cp0_read_addr),
       .exe_pcplus4(exe_pcplus4),
       .exe_pcplus8(exe_pcplus8),
       .exe_pc(exe_pc),
       .exe_regfile_wren(exe_regfile_wren),
       .exe_regfile_wt_addr(exe_regfile_wt_addr),
       .exe_regfile_mem2reg(exe_regfile_mem2reg),
       .exe_regfile_rs_read_val(exe_regfile_rs_read_val),
       .exe_regfile_rt_read_val(exe_regfile_rt_read_val),
       .exe_regfile_aluctr(exe_regfile_aluctr),
//       .exe_sra_left(exe_sra_left),
//       .exe_sra_right(exe_sra_right),
//       .exe_srav_left(exe_srav_left),
//       .exe_srav_right(exe_srav_right),
//       .exe_add_val(exe_add_val),
//       .exe_addi_val(exe_addi_val),
//       .exe_sub_val(exe_sub_val),
//       .exe_subi_val(exe_subi_val),
       .exe_hi_wren(exe_hi_wren),
       .exe_hi_read_val(exe_hi_read_val),
       .exe_lo_wren(exe_lo_wren),
       .exe_lo_read_val(exe_lo_read_val),
       .exe_hilo_aluctr(exe_hilo_aluctr),
       .exe_cp0_wren(exe_cp0_wren),
       .exe_cp0_wt_addr(exe_cp0_wt_addr),
       .exe_cp0_wt_val(exe_cp0_wt_val),
       .exe_cp0_read_val(exe_cp0_read_val),
       .exe_sign_imm32(exe_sign_imm32),
       .exe_unsign_imm32(exe_unsign_imm32),
       .exe_branch(exe_branch),
       .exe_inst_jr(exe_inst_jr),
       .exe_branch_address(exe_branch_address),
       .exe_jump_address(exe_jump_address),
       .exe_start_div(exe_start_div),
       .exe_start_mult(exe_start_mult),
       .exe_lw_sw_type(exe_lw_sw_type),
       .exe_dmm_read(exe_dmm_read),
       .exe_dmm_write(exe_dmm_write),
       .exe_exception_if_exchappen(exe_exception_if_exchappen),
       .exe_exception_if_epc(exe_exception_if_epc),
       .exe_exception_if_bd(exe_exception_if_bd),
       .exe_exception_if_badvaddr(exe_exception_if_badvaddr),
       .exe_exception_if_exccode(exe_exception_if_exccode),
       .exe_exception_dec_exchappen(exe_exception_dec_exchappen),
       .exe_exception_dec_exccode(exe_exception_dec_exccode)
);

RegFile RG( 
               .clk(aclk),
               .reset(reset),
               .regfile_rs_addr(regfile_rs_addr), 
               .regfile_rt_addr(regfile_rt_addr), 
               .wb_regfile_wren(wb_regfile_wren),
               .wb_regfile_wt_addr(wb_regfile_wt_addr), 
               .wb_regfile_wt_val(wb_regfile_wt_val_mux),
               .mem_regfile_wren(mem_regfile_wren),
               .mem_regfile_wt_addr(mem_regfile_wt_addr),
               .mem_regfile_wt_val(mem_regfile_wt_val_mux),
               .exe_regfile_wren(exe_regfile_wren),
               .exe_regfile_wt_addr(exe_regfile_wt_addr),
               .exe_regfile_wt_val(regfile_wt_val),

               .regfile_rs_read_val(regfile_rs_read_val), 
               .regfile_rt_read_val(regfile_rt_read_val)
);


HiLo HL( 
               .clk(aclk), 
               .reset(reset),
               .exe_hi_wren(exe_hi_wren),
               .exe_lo_wren(exe_lo_wren),
               .exe_hi_wt_val(hi_wt_val),
               .exe_lo_wt_val(lo_wt_val),
               .ready(ready),
               .complete(complete),
               .exception_flush(exception_flush),
 
               .hi_read_val(hi_read_val),
               .lo_read_val(lo_read_val) 
);

 CP0  cp0(
               .clk(aclk),
               .reset(reset),
               .exception_inst_interrupt(exception_inst_interrupt),
               .wb_exception_inst_exchappen(wb_exception_inst_exchappen),
               .wb_exception_inst_epc(wb_exception_inst_epc),
               .wb_exception_inst_bd(wb_exception_inst_bd),
               .wb_exception_inst_exccode(wb_exception_inst_exccode),
               .wb_exception_inst_badvaddr(wb_exception_inst_badvaddr),
               .wb_exception_inst_badvaddr_wren(wb_exception_inst_badvaddr_wren),
               .cp0_read_addr(cp0_read_addr), 
               .wb_cp0_wren(wb_cp0_wren),       
               .wb_cp0_wt_addr(wb_cp0_wt_addr), 
               .wb_cp0_wt_val(wb_cp0_wt_val), 
               .mem_cp0_wren(mem_cp0_wren),       
               .mem_cp0_wt_addr(mem_cp0_wt_addr), 
               .mem_cp0_wt_val(mem_cp0_wt_val), 
               .exe_cp0_wren(exe_cp0_wren),       
               .exe_cp0_wt_addr(exe_cp0_wt_addr), 
               .exe_cp0_wt_val(cp0_wt_val), 
               .inst_eret(inst_eret),
               .ready(ready),
               .complete(complete),
               
               .cp0_read_val(cp0_read_val),
               .cp0_epc_val(cp0_epc_val),
               .cp0_status_val(cp0_status_val),
               .cp0_status_ie(cp0_status_ie),
               .cp0_status_exl(cp0_status_exl),
               .cp0_status_im0(cp0_status_im0),
               .cp0_status_im1(cp0_status_im1),
               .cp0_cause_ip0(cp0_cause_ip0),
               .cp0_cause_ip1(cp0_cause_ip1)
);

 branch BH(
    		.branch_address(exe_branch_address),
            .jump_address(exe_jump_address),
		    .branch(exe_branch), 
	        .inst_jr(exe_inst_jr),
            .inst_eret(inst_eret),
            .exception_happen(exception_flush),	
		    .regfile_rs_read_val(exe_regfile_rs_read_val),
		    .regfile_rt_read_val(exe_regfile_rt_read_val),
		    .PCSrc(PCSrc),
		    .branch_target(branch_target),
            .branch_flush(branch_flush)
);
exe_stage EXE(
       .clk(aclk),
       .reset(reset),
       .exe_pcplus4(exe_pcplus4),
       .exe_pcplus8(exe_pcplus8),
       .exe_pc(exe_pc),
       .exe_regfile_wren(exe_regfile_wren),
       .exe_regfile_wt_addr(exe_regfile_wt_addr),
       .exe_regfile_mem2reg(exe_regfile_mem2reg),
       .exe_regfile_rs_read_val(exe_regfile_rs_read_val),
       .exe_regfile_rt_read_val(exe_regfile_rt_read_val),
       .exe_regfile_aluctr(exe_regfile_aluctr),
//       .exe_sra_left(exe_sra_left),
//       .exe_sra_right(exe_sra_right),
//       .exe_srav_left(exe_srav_left),
//       .exe_srav_right(exe_srav_right),
//       .exe_add_val(exe_add_val),
//       .exe_addi_val(exe_addi_val),
//       .exe_sub_val(exe_sub_val),
//       .exe_subi_val(exe_subi_val),
       .exe_hi_read_val(exe_hi_read_val),
       .exe_lo_read_val(exe_lo_read_val),
       .exe_hilo_aluctr(exe_hilo_aluctr),
       .exe_cp0_wren(exe_cp0_wren),
       .exe_cp0_wt_addr(exe_cp0_wt_addr),
       .exe_cp0_wt_val(exe_cp0_wt_val),
       .exe_cp0_read_val(exe_cp0_read_val),
       .exe_sign_imm32(exe_sign_imm32),
       .exe_unsign_imm32(exe_unsign_imm32),
       .exe_branch(exe_branch),
       .exe_start_div(exe_start_div),
       .exe_start_mult(exe_start_mult),
       .exe_lw_sw_type(exe_lw_sw_type),
       .exe_dmm_read(exe_dmm_read),
       .exe_dmm_write(exe_dmm_write),
       .exe_exception_if_exchappen(exe_exception_if_exchappen),
       .exe_exception_if_epc(exe_exception_if_epc),
       .exe_exception_if_bd(exe_exception_if_bd),
       .exe_exception_if_badvaddr(exe_exception_if_badvaddr),
       .exe_exception_if_exccode(exe_exception_if_exccode),
       .exe_exception_dec_exchappen(exe_exception_dec_exchappen),
       .exe_exception_dec_exccode(exe_exception_dec_exccode),
       .ready(ready),
       .exception_flush(exception_flush),
       .rd_tab(rd_tab),
       .harzard_flush_mem(harzard_flush_mem),

       .complete(complete),
       .addi_val(exe_addi_val),
       .regfile_wt_val(regfile_wt_val),
       .hi_wt_val(hi_wt_val),
       .lo_wt_val(lo_wt_val),
       .cp0_wt_val(cp0_wt_val),
       .mem_pc(mem_pc),
       .mem_regfile_wren(mem_regfile_wren),
       .mem_regfile_wt_addr(mem_regfile_wt_addr),
       .mem_regfile_mem2reg(mem_regfile_mem2reg),
       .mem_regfile_wt_val(mem_regfile_wt_val),
       .mem_regfile_rt_read_val(mem_regfile_rt_read_val),
       .mem_cp0_wren(mem_cp0_wren),
       .mem_cp0_wt_addr(mem_cp0_wt_addr),
       .mem_cp0_wt_val(mem_cp0_wt_val),
       .mem_lw_sw_type(mem_lw_sw_type),
       .mem_dmm_addr(mem_dmm_addr),
       .mem_dmm_read(mem_dmm_read),
       .mem_dmm_write(mem_dmm_write),
       .mem_dmm_byte_enable(mem_dmm_byte_enable),
       .mem_rd_tab(mem_rd_tab),
       .mem_exception_if_exchappen(mem_exception_if_exchappen),
       .mem_exception_if_epc(mem_exception_if_epc),
       .mem_exception_if_bd(mem_exception_if_bd),
       .mem_exception_if_badvaddr(mem_exception_if_badvaddr),
       .mem_exception_if_exccode(mem_exception_if_exccode),
       .mem_exception_dec_exchappen(mem_exception_dec_exchappen),
       .mem_exception_dec_exccode(mem_exception_dec_exccode),
       .mem_exception_exe_exchappen(mem_exception_exe_exchappen),
       .mem_exception_exe_exccode(mem_exception_exe_exccode)          
);

 mem_stage MEM(
           .clk(aclk),
           .reset(reset),
           .mem_pc(mem_pc),
           .mem_regfile_wren(mem_regfile_wren),
           .mem_regfile_wt_addr(mem_regfile_wt_addr),
           .mem_regfile_mem2reg(mem_regfile_mem2reg),
           .mem_regfile_wt_val(mem_regfile_wt_val),
           .mem_cp0_wren(mem_cp0_wren),
           .mem_cp0_wt_addr(mem_cp0_wt_addr),
           .mem_cp0_wt_val(mem_cp0_wt_val),
           .mem_lw_sw_type(mem_lw_sw_type),
           .mem_dmm_addr(mem_dmm_addr),
           .mem_dmm_byte_enable(mem_dmm_byte_enable),
           .mem_exception_if_exchappen(mem_exception_if_exchappen),
           .mem_exception_if_epc(mem_exception_if_epc),
           .mem_exception_if_bd(mem_exception_if_bd),
           .mem_exception_if_badvaddr(mem_exception_if_badvaddr),
           .mem_exception_if_exccode(mem_exception_if_exccode),
           .mem_exception_dec_exchappen(mem_exception_dec_exchappen),
           .mem_exception_dec_exccode(mem_exception_dec_exccode),
           .mem_exception_exe_exchappen(mem_exception_exe_exchappen),
           .mem_exception_exe_exccode(mem_exception_exe_exccode),
           .cp0_status_exl(cp0_status_exl),
           .cp0_status_ie(cp0_status_ie),
           .cp0_status_im0(cp0_status_im0),
           .cp0_status_im1(cp0_status_im1),
           .cp0_cause_ip0(cp0_cause_ip0),
           .cp0_cause_ip1(cp0_cause_ip1),
           .ready(ready),
           .complete(complete),
           .dmm_load_val(dmm_load_val),

		   .mem_regfile_wt_val_mux(mem_regfile_wt_val_mux),
           .exception_inst_exchappen(exception_inst_exchappen),
           .exception_flush(exception_flush),
           .exception_inst_interrupt(exception_inst_interrupt),
           .wb_exception_inst_exchappen(wb_exception_inst_exchappen),
           .wb_exception_inst_epc(wb_exception_inst_epc),
           .wb_exception_inst_bd(wb_exception_inst_bd),
           .wb_exception_inst_badvaddr(wb_exception_inst_badvaddr),
           .wb_exception_inst_badvaddr_wren(wb_exception_inst_badvaddr_wren),
           .wb_exception_inst_exccode(wb_exception_inst_exccode),
           .wb_pc(wb_pc),
           .wb_regfile_wren(wb_regfile_wren),
           .wb_regfile_wt_addr(wb_regfile_wt_addr),
           .wb_regfile_mem2reg(wb_regfile_mem2reg),
           .wb_regfile_wt_val(wb_regfile_wt_val),
           .wb_dmm_load_val(wb_dmm_load_val),
           .wb_dmm_byte_enable(wb_dmm_byte_enable),
           .wb_lw_sw_type(wb_lw_sw_type),
           .wb_cp0_wren(wb_cp0_wren),
           .wb_cp0_wt_addr(wb_cp0_wt_addr),
           .wb_cp0_wt_val(wb_cp0_wt_val)
);

wb_stage WB( 
              .clk(aclk),
              .wb_regfile_wren(wb_regfile_wren),
              .wb_regfile_wt_addr(wb_regfile_wt_addr),
              .wb_regfile_mem2reg(wb_regfile_mem2reg),
              .wb_regfile_wt_val(wb_regfile_wt_val),
              .wb_dmm_load_val(wb_dmm_load_val),
              .wb_dmm_byte_enable(wb_dmm_byte_enable),
              .wb_lw_sw_type(wb_lw_sw_type),
              .wb_pc(wb_pc),    
              .ready(ready),
              .complete(complete),      

              .wb_regfile_wt_val_mux(wb_regfile_wt_val_mux),
              .debug_wb_pc(debug_wb_pc),
              .debug_wb_rf_wen(debug_wb_rf_wen),
              .debug_wb_rf_wnum(debug_wb_rf_wnum),
              .debug_wb_rf_wdata(debug_wb_rf_wdata) 
);


Memory_System MS(
           .clk(aclk),
           .reset(reset),
           .pc(pc),
           .pc_next(pc_next),
           .pc_wren(pc_wren),
           .complete(complete),
           .exception_inst_exchappen(exception_inst_exchappen),
           .mem_dmm_addr(mem_dmm_addr),
           .mem_lw_sw_type(mem_lw_sw_type),
           .dmm_read(mem_dmm_read),
           .dmm_write(mem_dmm_write),
           .wen(mem_dmm_byte_enable),
           .store_val(mem_regfile_rt_read_val),
           .mem_rd_tab(mem_rd_tab),
           .exe_dmm_addr(exe_addi_val),
           
           .rd_tab(rd_tab),
           .arid(arid),
           .araddr(araddr),
           .arlen(arlen),
           .arsize(arsize),
           .arburst(arburst),
           .arlock(arlock),
           .arcache(arcache),
           .arprot(arprot),
           .arvalid(arvalid),
           .arready(arready),
     
           .rid(rid),
           .rdata(rdata),
           .rresp(rresp),
           .rlast(rlast),
           .rvalid(rvalid),
           .rready(rready),
     
           .awid(awid),
           .awaddr(awaddr),
           .awlen(awlen),
           .awsize(awsize),
           .awburst(awburst),
           .awlock(awlock),
           .awcache(awcache),
           .awprot(awprot),
           .awvalid(awvalid),
           .awready(awready),
    
           .wid(wid),
           .wdata(wdata),
           .wstrb(wstrb),
           .wlast(wlast),
           .wvalid(wvalid),
           .wready(wready),
    
           .bid(bid),
           .bresp(bresp),
           .bvalid(bvalid),
           .bready(bready),
           .ready(ready),
           .icache_inst(icache_inst),
           .dcache_rdata(dmm_load_val)
);
endmodule
