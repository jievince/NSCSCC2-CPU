module   RegFile( 
    input wire                      clk,
    input wire                      reset,
    input wire [4:0]                regfile_rs_addr, 
    input wire [4:0]                regfile_rt_addr, 
    input wire                      wb_regfile_wren,
    input wire [4:0]                wb_regfile_wt_addr, 
    input wire [31:0]               wb_regfile_wt_val,
    input wire                      mem_regfile_wren,
    input wire [4:0]                mem_regfile_wt_addr,
    input wire [31:0]               mem_regfile_wt_val,
    input wire                      exe_regfile_wren,
    input wire [4:0]                exe_regfile_wt_addr,
    input wire [31:0]               exe_regfile_wt_val,

    output reg [31:0]               regfile_rs_read_val, 
    output reg [31:0]               regfile_rt_read_val
);
    reg [31:0]                      regfile [31:0];
    wire                            rs_forward_exe;
    wire                            rs_forward_mem;
    wire                            rs_forward_wb;
    wire                            rt_forward_exe;
    wire                            rt_forward_mem;
    wire                            rt_forward_wb;
	
	always @(posedge clk)
    if(reset)
    begin
        regfile[0]<=0;
        regfile[1]<=0;
        regfile[2]<=0;
        regfile[3]<=0;
        regfile[4]<=0;
        regfile[5]<=0;
        regfile[6]<=0;
        regfile[7]<=0;        
        regfile[8]<=0;
        regfile[9]<=0;
        regfile[10]<=0;
        regfile[11]<=0;
        regfile[12]<=0;
        regfile[13]<=0;
        regfile[14]<=0;
        regfile[15]<=0;   
        regfile[16]<=0;
        regfile[17]<=0;
        regfile[18]<=0;
        regfile[19]<=0;
        regfile[20]<=0;
        regfile[21]<=0;
        regfile[22]<=0;
        regfile[23]<=0;        
        regfile[24]<=0;
        regfile[25]<=0;
        regfile[26]<=0;
        regfile[27]<=0;
        regfile[28]<=0;
        regfile[29]<=0;
        regfile[30]<=0;
        regfile[31]<=0;   
    end
	
   else if (wb_regfile_wren && wb_regfile_wt_addr != 0)
        regfile[wb_regfile_wt_addr] <= wb_regfile_wt_val;


    // regfile bypass 
    assign rs_forward_exe = exe_regfile_wren&& exe_regfile_wt_addr == regfile_rs_addr && exe_regfile_wt_addr != 0;
    assign rs_forward_mem = mem_regfile_wren && mem_regfile_wt_addr == regfile_rs_addr && mem_regfile_wt_addr != 0;
    assign rs_forward_wb  = wb_regfile_wren  && wb_regfile_wt_addr  == regfile_rs_addr && wb_regfile_wt_addr != 0;

    assign rt_forward_exe = exe_regfile_wren && exe_regfile_wt_addr == regfile_rt_addr && exe_regfile_wt_addr != 0;
    assign rt_forward_mem = mem_regfile_wren && mem_regfile_wt_addr == regfile_rt_addr && mem_regfile_wt_addr != 0;
    assign rt_forward_wb  = wb_regfile_wren  && wb_regfile_wt_addr  == regfile_rt_addr && wb_regfile_wt_addr != 0;

    always @(*) 
    casex ({rs_forward_exe, rs_forward_mem, rs_forward_wb}) 
        3'b1xx: regfile_rs_read_val = exe_regfile_wt_val;
        3'b01x: regfile_rs_read_val = mem_regfile_wt_val;
        3'b001: regfile_rs_read_val = wb_regfile_wt_val;
        default:regfile_rs_read_val = regfile[regfile_rs_addr];
    endcase 

    always @(*)
    casex ({rt_forward_exe, rt_forward_mem, rt_forward_wb}) 
        3'b1xx: regfile_rt_read_val = exe_regfile_wt_val;
        3'b01x: regfile_rt_read_val = mem_regfile_wt_val;
        3'b001: regfile_rt_read_val = wb_regfile_wt_val;
        default:regfile_rt_read_val = regfile[regfile_rt_addr];
    endcase 

endmodule

