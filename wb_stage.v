module wb_stage( 
    input wire                  clk,
    input wire                  wb_regfile_wren,
    input wire [4:0]            wb_regfile_wt_addr,
    input wire                  wb_regfile_mem2reg,
    input wire [31:0]           wb_regfile_wt_val,
    input wire [31:0]           wb_dmm_load_val,
    input wire [3:0]            wb_dmm_byte_enable,
    input wire [2:0]            wb_lw_sw_type,
    input wire [31:0]           wb_pc,    
    input wire                  ready,
    input wire                  complete,      
               
    output wire [31:0]          wb_regfile_wt_val_mux,
    output wire[31:0]           debug_wb_pc,
    output wire[3:0]            debug_wb_rf_wen,
    output wire[4:0]            debug_wb_rf_wnum,
    output wire[31:0]           debug_wb_rf_wdata 
);
    reg                         trace_flag;
    reg [31:0]                  lb_val;
    reg [31:0]                  lbu_val;
    reg [31:0]                  lh_val;
    reg [31:0]                  lhu_val;
    reg [31:0]                  dmm_datOut;
    always @(posedge clk)
    if (ready && complete)
        trace_flag <= 1;
    else 
        trace_flag <= 0;

    always @(*)
    case (wb_dmm_byte_enable) 
        4'b0001: lb_val = {{24{wb_dmm_load_val[7]}}, wb_dmm_load_val[7:0]};
        4'b0010: lb_val = {{24{wb_dmm_load_val[15]}},wb_dmm_load_val[15:8]};
        4'b0100: lb_val = {{24{wb_dmm_load_val[23]}},wb_dmm_load_val[23:16]};
        4'b1000: lb_val = {{24{wb_dmm_load_val[31]}},wb_dmm_load_val[31:24]};
        default: lb_val = 32'b0;
    endcase

    always @(*)
    case (wb_dmm_byte_enable) 
        4'b0001: lbu_val = {24'd0, wb_dmm_load_val[7:0]};
        4'b0010: lbu_val = {24'd0,wb_dmm_load_val[15:8]};
        4'b0100: lbu_val = {24'd0,wb_dmm_load_val[23:16]};
        4'b1000: lbu_val = {24'd0,wb_dmm_load_val[31:24]};
        default: lbu_val = 32'b0;
    endcase

    always @(*)
    case (wb_dmm_byte_enable) 
        4'b0011: lh_val = {{16{wb_dmm_load_val[15]}}, wb_dmm_load_val[15:0]};
        4'b1100: lh_val = {{16{wb_dmm_load_val[31]}}, wb_dmm_load_val[31:16]};
        default: lh_val = 32'b0;
    endcase

    always @(*)
    case (wb_dmm_byte_enable) 
        4'b0011: lhu_val = {16'd0, wb_dmm_load_val[15:0]};
        4'b1100: lhu_val = {16'd0, wb_dmm_load_val[31:16]};
        default: lhu_val = 32'b0;
    endcase

    
    always @(*)
    case (wb_lw_sw_type) 
        3'b000: dmm_datOut = lb_val;
        3'b001: dmm_datOut = lbu_val;
        3'b010: dmm_datOut = lh_val;
        3'b011: dmm_datOut = lhu_val;
        3'b100: dmm_datOut = wb_dmm_load_val;
        default: dmm_datOut = 32'b0;
    endcase
	assign wb_regfile_wt_val_mux = wb_regfile_mem2reg ?  dmm_datOut : wb_regfile_wt_val;
	
	assign debug_wb_pc       = trace_flag ? wb_pc : 0;
	assign debug_wb_rf_wen   = trace_flag ? {4{wb_regfile_wren}} : 0;
	assign debug_wb_rf_wnum  = trace_flag ? wb_regfile_wt_addr: 0;
	assign debug_wb_rf_wdata = trace_flag ? wb_regfile_wt_val_mux :0;
endmodule