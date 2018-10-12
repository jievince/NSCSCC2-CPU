module mem_stage(
    input wire                  clk,
    input wire                  reset,
    input wire [31:0]           mem_pc,
    input wire                  mem_regfile_wren,
    input wire [4:0]            mem_regfile_wt_addr,
    input wire                  mem_regfile_mem2reg,
    input wire [31:0]           mem_regfile_wt_val,
    input wire                  mem_cp0_wren,
    input wire [4:0]            mem_cp0_wt_addr,
    input wire [31:0]           mem_cp0_wt_val,
    input wire [2:0]            mem_lw_sw_type,
    input wire [31:0]           mem_dmm_addr,
    input wire [3:0]            mem_dmm_byte_enable,
    input wire                  mem_exception_if_exchappen,
    input wire [31:0]           mem_exception_if_epc,
    input wire                  mem_exception_if_bd,
    input wire [31:0]           mem_exception_if_badvaddr,
    input wire [4:0]            mem_exception_if_exccode,
    input wire                  mem_exception_dec_exchappen,
    input wire [4:0]            mem_exception_dec_exccode,
    input wire                  mem_exception_exe_exchappen,
    input wire [4:0]            mem_exception_exe_exccode,
    input wire                  cp0_status_exl,
    input wire                  cp0_status_ie,
    input wire                  cp0_status_im0,
    input wire                  cp0_status_im1,
    input wire                  cp0_cause_ip0,
    input wire                  cp0_cause_ip1,
    input wire                  ready,
    input wire                  complete,
    input wire [31:0]           dmm_load_val,

	output wire [31:0]			 mem_regfile_wt_val_mux,
    output wire                 exception_inst_exchappen,
    output wire                 exception_flush,
    output wire                 exception_inst_interrupt,
    output reg                  wb_exception_inst_exchappen,
    output reg [31:0]           wb_exception_inst_epc,
    output reg                  wb_exception_inst_bd,
    output reg [31:0]           wb_exception_inst_badvaddr,
    output reg                  wb_exception_inst_badvaddr_wren,
    output reg [4:0]            wb_exception_inst_exccode,
    output reg [31:0]           wb_pc,
    output reg                  wb_regfile_wren,
    output reg [4:0]            wb_regfile_wt_addr,
    output reg                  wb_regfile_mem2reg,
    output reg [31:0]           wb_regfile_wt_val,
    output reg [31:0]           wb_dmm_load_val,
    output reg [3:0]            wb_dmm_byte_enable,
    output reg [2:0]            wb_lw_sw_type,
    output reg                  wb_cp0_wren,
    output reg [4:0]            wb_cp0_wt_addr,
    output reg [31:0]           wb_cp0_wt_val
);

    reg                   exception_mem_exchappen;
    wire [31:0]           exception_mem_badvaddr;
    reg [4:0]             exception_mem_exccode;
    wire[31:0]            exception_inst_epc;
    wire                  exception_inst_bd;
    reg [31:0]            exception_inst_badvaddr;
    reg                   exception_inst_badvaddr_wren;
    reg [4:0]             exception_inst_exccode;
    wire [4:0]            exceptions;
    wire                  flush;

	assign mem_regfile_wt_val_mux = mem_regfile_mem2reg ? dmm_load_val : mem_regfile_wt_val; 
    //exception handle
    assign exception_mem_badvaddr = mem_dmm_addr;

    always @(*)
    begin
		if (mem_lw_sw_type == 3'd6 && mem_dmm_addr[0] != 1'b0) //sh
        begin
            exception_mem_exchappen = 1;
			exception_mem_exccode = 5'd5;
        end
		else if (mem_lw_sw_type == 3'd7 && mem_dmm_addr[1:0] != 2'b00) //sw
        begin
            exception_mem_exchappen = 1;
			exception_mem_exccode = 5'd5;
        end
		else if ( (mem_lw_sw_type == 3'd2 || mem_lw_sw_type == 3'd3) && mem_dmm_addr[0] != 1'b0) // lh, lhu
        begin
            exception_mem_exchappen = 1;
			exception_mem_exccode = 5'd4;
        end
		else if (mem_lw_sw_type == 3'd4 && mem_dmm_addr[1:0] != 2'b00) //lw
        begin
            exception_mem_exchappen = 1;
			exception_mem_exccode = 5'd4;
        end
		else 
        begin
            exception_mem_exchappen = 0;
			exception_mem_exccode = 0; 
        end
    end

    // exception handle 

    assign exception_flush = exception_inst_exchappen || exception_inst_interrupt;
	assign exception_inst_interrupt = cp0_status_ie && ~cp0_status_exl ?
             ((cp0_status_im0 & cp0_cause_ip0) || (cp0_status_im1 & cp0_cause_ip1)) : 0;
    assign exceptions = {mem_exception_if_exchappen, 
            mem_exception_dec_exchappen, mem_exception_exe_exchappen, exception_mem_exchappen};
    assign exception_inst_exchappen = | exceptions;
	assign exception_inst_epc = exception_inst_interrupt ? wb_pc : mem_exception_if_epc;
	assign exception_inst_bd = mem_exception_if_bd;

	always @(*)
	casex (exceptions) // synopsys full_case parallel_case
	    4'b1xxx: 
        begin
            exception_inst_badvaddr = mem_exception_if_badvaddr;
            exception_inst_badvaddr_wren = 1;
            exception_inst_exccode = mem_exception_if_exccode;
        end        
    	4'b01xx:
		begin
            exception_inst_badvaddr = 0;
            exception_inst_badvaddr_wren = 0;
            exception_inst_exccode = mem_exception_dec_exccode;
		end
        4'b001x:
		begin
            exception_inst_badvaddr = 0;
            exception_inst_badvaddr_wren = 0;
            exception_inst_exccode = mem_exception_exe_exccode;
        end
        4'b0001:
		begin
            exception_inst_badvaddr = exception_mem_badvaddr;
            exception_inst_badvaddr_wren = 1;
            exception_inst_exccode = exception_mem_exccode;
		end
		default:
		begin
            exception_inst_badvaddr = 0;
            exception_inst_badvaddr_wren = 0;
            exception_inst_exccode = 0;
		end
	endcase

    assign flush = exception_inst_exchappen || exception_inst_interrupt;
    always @(posedge clk)
    if (reset)
    begin
        wb_exception_inst_exchappen <= 0;
        wb_regfile_wren <= 0;
        wb_regfile_wt_addr <= 0;
        wb_regfile_mem2reg <= 0;
        wb_cp0_wren <= 0;
        wb_cp0_wt_addr <= 0;
        wb_lw_sw_type <= 0;
    end
    else if (ready && complete)
    begin
        wb_exception_inst_exchappen <= exception_inst_exchappen;
        wb_regfile_wren <= flush ? 0 : mem_regfile_wren;
        wb_regfile_wt_addr <= flush ? 0 : mem_regfile_wt_addr;
        wb_regfile_mem2reg <= flush ? 0 :  mem_regfile_mem2reg;
        wb_cp0_wren <=  flush ? 0 : mem_cp0_wren;
        wb_cp0_wt_addr <= flush ? 0 : mem_cp0_wt_addr;
        wb_lw_sw_type <= flush ? 0 : mem_lw_sw_type;
    end

    always @(posedge clk)
    if (ready && complete)
    begin
        wb_exception_inst_epc <= exception_inst_epc;
        wb_exception_inst_bd <= exception_inst_bd;
        wb_exception_inst_badvaddr <= exception_inst_badvaddr;
        wb_exception_inst_badvaddr_wren <= exception_inst_badvaddr_wren;
        wb_exception_inst_exccode <= exception_inst_exccode;
        wb_pc <= flush ? 0 : mem_pc;  
        wb_regfile_wt_val <= flush ? 0 :  mem_regfile_wt_val;
        wb_dmm_load_val <= flush ? 0 : dmm_load_val;       
        wb_dmm_byte_enable <= flush ? 0 : mem_dmm_byte_enable;
        wb_cp0_wt_val <= flush ? 0 : mem_cp0_wt_val;
    end

endmodule








