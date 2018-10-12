module CP0(
    input                                   clk,
    input                                   reset,
    input wire                              exception_inst_interrupt,
    input wire                              wb_exception_inst_exchappen,
    input wire [31:0]                       wb_exception_inst_epc,
    input wire                              wb_exception_inst_bd,
    input wire [4:0]                        wb_exception_inst_exccode,
    input wire [31:0]                       wb_exception_inst_badvaddr,
    input wire                              wb_exception_inst_badvaddr_wren,
    input wire [4:0]                        cp0_read_addr, 
    input wire                              wb_cp0_wren,       
    input wire [4:0]                        wb_cp0_wt_addr, 
    input wire [31:0]                       wb_cp0_wt_val, 
    input wire                              mem_cp0_wren,       
    input wire [4:0]                        mem_cp0_wt_addr, 
    input wire [31:0]                       mem_cp0_wt_val, 
    input wire                              exe_cp0_wren,       
    input wire [4:0]                        exe_cp0_wt_addr, 
    input wire [31:0]                       exe_cp0_wt_val, 
    input wire                              inst_eret,
    input wire                              ready,
    input wire                              complete,
    
    output wire [31:0]                      cp0_read_val,
    output wire [31:0]                      cp0_epc_val,
    output wire [31:0]                      cp0_status_val,
    output wire                             cp0_status_ie,
    output wire                             cp0_status_exl,
    output wire                             cp0_status_im0,
    output wire                             cp0_status_im1,
    output wire                             cp0_cause_ip0,
    output wire                             cp0_cause_ip1
);

    reg [31:0]                              cp0_reg_status; //bev bit always keep 1
    reg [31:0]                              cp0_reg_cause;
    reg [31:0]                              cp0_reg_epc;
    reg [31:0]                              cp0_reg_badvaddr;

    reg [31:0]                              cp0_read_val_tmp;
    wire [31:0]                             wb_bypass_cause;
    wire [31:0]                             wb_bypass_status;
    wire [31:0]                             wb_bypass_epc;
    wire [31:0]                             mem_bypass_cause;
    wire [31:0]                             mem_bypass_status;
    wire [31:0]                             mem_bypass_epc;
    wire [31:0]                             exe_bypass_cause;
    wire [31:0]                             exe_bypass_status;
    wire [31:0]                             exe_bypass_epc;
    wire [31:0]	                            wb_bypass;
    wire [31:0]		                        mem_bypass;
    wire [31:0]		                        exe_bypass;

    always @(posedge clk)
    if(reset)
    begin
        cp0_reg_status = 32'b0000000001000000xxxxxxxx00000000;
        cp0_reg_cause  = 32'b0000000000000000000000000xxxxx00;
    end
    else if (ready && complete && exception_inst_interrupt)
    begin
        cp0_reg_status[1]    <= 1;
        cp0_reg_cause[31]    <= wb_exception_inst_bd;
        cp0_reg_cause[6:2]   <= 5'd0; 
        cp0_reg_epc          <= wb_exception_inst_epc;
      end
    else if (ready && complete && wb_exception_inst_exchappen) 
    begin
        cp0_reg_status[1]    <= 1;
        cp0_reg_cause[6:2]   <= wb_exception_inst_exccode;
        if (wb_exception_inst_badvaddr_wren)
            cp0_reg_badvaddr <= wb_exception_inst_badvaddr; 
        if (~cp0_status_exl)
        begin
            cp0_reg_cause[31]<= wb_exception_inst_bd;
            cp0_reg_epc      <= wb_exception_inst_epc;
        end
    end
    else if (ready && complete && wb_cp0_wren) //mtc0(except interrupt)
    begin
        if (wb_cp0_wt_addr == 5'd12) //wt status
        begin
            cp0_reg_status[15:8]   <= wb_cp0_wt_val[15:8];
            cp0_reg_status[1]      <= wb_cp0_wt_val[1]; 
            cp0_reg_status[0]      <= wb_cp0_wt_val[0];
        end 
        else if (wb_cp0_wt_addr == 5'd13)
            cp0_reg_cause[9:8]   <= wb_cp0_wt_val[9:8];
        else if (wb_cp0_wt_addr== 5'd14) // wt epc
            cp0_reg_epc            <= wb_cp0_wt_val;
    end

    //cp0 bypass
    always @(*)
    case (cp0_read_addr)
        5'd12: cp0_read_val_tmp = cp0_reg_status;
        5'd13: cp0_read_val_tmp = cp0_reg_cause;
        5'd14: cp0_read_val_tmp = cp0_reg_epc;
        5'd8 : cp0_read_val_tmp = cp0_reg_badvaddr;
        default: cp0_read_val_tmp = 0;
    endcase
    
    assign wb_bypass_cause = {cp0_reg_cause[31:10], wb_cp0_wt_val[9:8], cp0_reg_cause[7:0]};
    assign wb_bypass_status = {cp0_reg_status[31:16], wb_cp0_wt_val[15:8], cp0_reg_status[7:2],   wb_cp0_wt_val[1:0]};
    assign wb_bypass_epc = wb_cp0_wt_val;
    
    assign mem_bypass_cause = {cp0_reg_cause[31:10], mem_cp0_wt_val[9:8], cp0_reg_cause[7:0]};
    assign mem_bypass_status = {cp0_reg_status[31:16], mem_cp0_wt_val[15:8], cp0_reg_status[7:2], mem_cp0_wt_val[1:0]};
    assign mem_bypass_epc = mem_cp0_wt_val;
    
    assign exe_bypass_cause = {cp0_reg_cause[31:10], exe_cp0_wt_val[9:8], cp0_reg_cause[7:0]};
    assign exe_bypass_status = {cp0_reg_status[31:16], exe_cp0_wt_val[15:8], cp0_reg_status[7:2], exe_cp0_wt_val[1:0]};
    assign exe_bypass_epc = exe_cp0_wt_val;
    
    assign wb_bypass = wb_cp0_wt_addr == 5'd13 ? wb_bypass_cause  : 
                       (wb_cp0_wt_addr == 5'd12 ? wb_bypass_status : 
                       (wb_cp0_wt_addr == 5'd14 ? wb_bypass_epc    : cp0_read_val_tmp)); 
    assign mem_bypass = mem_cp0_wt_addr == 5'd13 ? mem_bypass_cause : 
                       (mem_cp0_wt_addr == 5'd12  ? mem_bypass_status : 
                       (mem_cp0_wt_addr == 5'd14  ? mem_bypass_epc : cp0_read_val_tmp)); 
    assign exe_bypass = exe_cp0_wt_addr == 5'd13 ? exe_bypass_cause : 
                       (exe_cp0_wt_addr == 5'd12  ? exe_bypass_status : 
                       (exe_cp0_wt_addr == 5'd14  ? exe_bypass_epc : cp0_read_val_tmp)); 
    assign cp0_read_val = (exe_cp0_wren && (exe_cp0_wt_addr == cp0_read_addr)) ? exe_bypass :
         ((mem_cp0_wren && (mem_cp0_wt_addr == cp0_read_addr)) ? mem_bypass : ((wb_cp0_wren && (wb_cp0_wt_addr == cp0_read_addr)) ? wb_bypass : cp0_read_val_tmp));
    assign cp0_epc_val = exe_cp0_wren && exe_cp0_wt_addr == 5'd14 ? exe_bypass_epc : 
        (mem_cp0_wren && mem_cp0_wt_addr == 5'd14 ? mem_bypass_epc : 
        (wb_cp0_wren && wb_cp0_wt_addr == 5'd14 ? wb_bypass_epc : cp0_reg_epc));
    assign cp0_status_val = exe_cp0_wren && exe_cp0_wt_addr == 5'd12 ? exe_bypass_status : 
        (mem_cp0_wren && mem_cp0_wt_addr == 5'd12 ? mem_bypass_status : 
        (wb_cp0_wren && wb_cp0_wt_addr == 5'd12 ? wb_bypass_status : cp0_reg_status));
    
    assign cp0_status_ie  = cp0_reg_status[0];
    assign cp0_status_exl = cp0_reg_status[1];
    assign cp0_status_im0 = cp0_reg_status[8];
    assign cp0_status_im1 = cp0_reg_status[9];
    assign cp0_cause_ip0  = cp0_reg_cause[8];
    assign cp0_cause_ip1  = cp0_reg_cause[9];

endmodule







