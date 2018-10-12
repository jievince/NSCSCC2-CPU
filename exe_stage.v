module exe_stage(
    input wire              clk,
    input wire              reset,
    input wire [31:0]       exe_pcplus4,
    input wire [31:0]       exe_pcplus8,
    input wire [31:0]       exe_pc,
    input wire              exe_regfile_wren,
    input wire [4:0]        exe_regfile_wt_addr,
    input wire              exe_regfile_mem2reg,
    input wire [31:0]       exe_regfile_rs_read_val,
    input wire [31:0]       exe_regfile_rt_read_val,
    input wire [4:0]        exe_regfile_aluctr,
    input wire [31:0]       exe_hi_read_val,
    input wire [31:0]       exe_lo_read_val,
    input wire [2:0]        exe_hilo_aluctr,
    input wire              exe_cp0_wren,
    input wire [4:0]        exe_cp0_wt_addr,
    input wire [31:0]       exe_cp0_wt_val,
    input wire [31:0]       exe_cp0_read_val,
    input wire [31:0]       exe_sign_imm32,
    input wire [31:0]       exe_unsign_imm32,
    input wire [2:0]        exe_branch,
    input wire              exe_start_div,
    input wire              exe_start_mult,
    input wire [2:0]        exe_lw_sw_type,
    input wire              exe_dmm_read,
    input wire              exe_dmm_write,
    input wire              exe_exception_if_exchappen,
    input wire [31:0]       exe_exception_if_epc,
    input wire              exe_exception_if_bd,
    input wire [31:0]       exe_exception_if_badvaddr,
    input wire [4:0]        exe_exception_if_exccode,
    input wire              exe_exception_dec_exchappen,
    input wire [4:0]        exe_exception_dec_exccode,
    input wire              ready,
    input wire              exception_flush,
    input wire [20:0]       rd_tab,
    input wire              harzard_flush_mem,

    output wire             complete,
    output wire[31:0]       addi_val,
    output reg [31:0]       regfile_wt_val,
    output reg [31:0]       hi_wt_val,
    output reg [31:0]       lo_wt_val,
    output wire [31:0]      cp0_wt_val,
    output reg [31:0]       mem_pc,
    output reg              mem_regfile_wren,
    output reg [4:0]        mem_regfile_wt_addr,
    output reg              mem_regfile_mem2reg,
    output reg [31:0]       mem_regfile_wt_val,
    output reg [31:0]       mem_regfile_rt_read_val,
    output reg              mem_cp0_wren,
    output reg [4:0]        mem_cp0_wt_addr,
    output reg [31:0]       mem_cp0_wt_val,
    output reg [2:0]        mem_lw_sw_type,
    output reg [31:0]       mem_dmm_addr,
    output reg              mem_dmm_read,
    output reg              mem_dmm_write,
    output reg [3:0]        mem_dmm_byte_enable,
    output reg [20:0]       mem_rd_tab,
    output reg              mem_exception_if_exchappen,
    output reg [31:0]       mem_exception_if_epc,
    output reg              mem_exception_if_bd,
    output reg [31:0]       mem_exception_if_badvaddr,
    output reg [4:0]        mem_exception_if_exccode,
    output reg              mem_exception_dec_exchappen,
    output reg [4:0]        mem_exception_dec_exccode,
    output reg              mem_exception_exe_exchappen,
    output reg [4:0]        mem_exception_exe_exccode          
);

    reg                          overflow;
    wire                        flush;
    wire                         exception_exe_exchappen;
    wire [4:0]                   exception_exe_exccode;
    wire [15:0]                 imm16;
    wire [31:0]                 add_val;
    wire [31:0]                 sub_val;
    wire [31:0]                 subi_val;
    wire [31:0]                 slt_val;
    wire [31:0]                 slti_val;
    wire [31:0]                 sltu_val;
    wire [31:0]                 sltiu_val;
    wire [31:0]                 and_val;
    wire [31:0]                 andi_val;
    wire [31:0]                 lui_val;
    wire [31:0]                 nor_val;
    wire [31:0]                 or_val;
    wire [31:0]                 ori_val;
    wire [31:0]                 xor_val;
    wire [31:0]                 xori_val;
    wire [31:0]                 sll_val;
    wire [31:0]                 sllv_val;
    wire [31:0]                 sra_val;
    wire [31:0]                 srav_val;
    wire [31:0]                 srl_val;
    wire [31:0]                 srlv_val;
    wire [31:0]                 al_val;
    wire [31:0]                 div_hi_wt_val;
    wire [31:0]                 div_lo_wt_val;
    wire [31:0]                 divu_hi_wt_val;
    wire [31:0]                 divu_lo_wt_val;
    wire [31:0]                 mult_hi_wt_val;
    wire [31:0]                 mult_lo_wt_val;
    wire [31:0]                 multu_hi_wt_val;
    wire [31:0]                 multu_lo_wt_val;
    wire [31:0]                 reverse_exe_regfile_rt_read_val;
    reg [5:0]                   counter;
    reg [3:0]                   byte_enable_tmp;
    reg [3:0]                   dmm_byte_enable;

    assign imm16 = exe_unsign_imm32[15:0];
    assign add_val = exe_regfile_rs_read_val + exe_regfile_rt_read_val;
    assign addi_val = exe_regfile_rs_read_val + exe_sign_imm32;
    assign sub_val = exe_regfile_rs_read_val - exe_regfile_rt_read_val;
    assign subi_val = exe_regfile_rs_read_val - exe_sign_imm32;
    assign slt_val = (exe_regfile_rs_read_val[31] ^ exe_regfile_rt_read_val[31] == 1) ? exe_regfile_rs_read_val[31]  : sub_val[31];
    assign slti_val = (exe_regfile_rs_read_val[31] ^ exe_sign_imm32[31] == 1) ? exe_regfile_rs_read_val[31]  : subi_val[31];
    assign sltu_val = (exe_regfile_rs_read_val[31] ^ exe_regfile_rt_read_val[31] == 1) ? exe_regfile_rt_read_val[31] : sub_val[31];
    assign sltiu_val = (exe_regfile_rs_read_val[31] ^ exe_sign_imm32[31] == 1) ? exe_sign_imm32[31] : subi_val[31];
    assign and_val = exe_regfile_rs_read_val & exe_regfile_rt_read_val;
    assign andi_val = exe_regfile_rs_read_val & exe_unsign_imm32;
    assign lui_val = {imm16,16'd0};
    assign nor_val = ~(exe_regfile_rs_read_val | exe_regfile_rt_read_val);
    assign or_val = exe_regfile_rs_read_val | exe_regfile_rt_read_val;
    assign ori_val = exe_regfile_rs_read_val | exe_unsign_imm32;
    assign xor_val = exe_regfile_rs_read_val ^ exe_regfile_rt_read_val;
    assign xori_val = exe_regfile_rs_read_val ^ exe_unsign_imm32;
    assign sll_val = exe_regfile_rt_read_val << exe_unsign_imm32[10:6];
    assign sllv_val = exe_regfile_rt_read_val << exe_regfile_rs_read_val[4:0];
    assign sra_val = (exe_regfile_rt_read_val >> exe_unsign_imm32[10:6])|(exe_regfile_rt_read_val[31] ? ~({32{1'b1}}>>exe_unsign_imm32[10:6]) : 32'h0);
    assign srav_val = (exe_regfile_rt_read_val>>exe_regfile_rs_read_val[4:0])|(exe_regfile_rt_read_val[31] ? ~({32{1'b1}}>>exe_regfile_rs_read_val[4:0]) : 32'h0);
    assign srl_val = exe_regfile_rt_read_val >> exe_unsign_imm32[10:6];
    assign srlv_val = exe_regfile_rt_read_val >> exe_regfile_rs_read_val[4:0];
    assign al_val = exe_pcplus8;


    always @(*)
    case (exe_regfile_aluctr) 
        5'd1: regfile_wt_val = add_val;
        5'd2: regfile_wt_val = addi_val;
        5'd3: regfile_wt_val = add_val;
        5'd4: regfile_wt_val = addi_val;
        5'd5: regfile_wt_val = sub_val;
        5'd6: regfile_wt_val = sub_val;
        5'd7: regfile_wt_val = slt_val;
        5'd8: regfile_wt_val = slti_val;
        5'd9: regfile_wt_val = sltu_val;
        5'd10: regfile_wt_val = sltiu_val;
        5'd11: regfile_wt_val = and_val;
        5'd12: regfile_wt_val = andi_val;
        5'd13: regfile_wt_val = lui_val;
        5'd14: regfile_wt_val = nor_val;
        5'd15: regfile_wt_val = or_val;
        5'd16: regfile_wt_val = ori_val;
        5'd17: regfile_wt_val = xor_val;
        5'd18: regfile_wt_val = xori_val;
        5'd19: regfile_wt_val = sll_val;
        5'd20: regfile_wt_val = sllv_val;
        5'd21: regfile_wt_val = sra_val;
        5'd22: regfile_wt_val = srav_val;
        5'd23: regfile_wt_val = srl_val;
        5'd24: regfile_wt_val = srlv_val;
        5'd25: regfile_wt_val = al_val;
        5'd26: regfile_wt_val = exe_hi_read_val;
        5'd27: regfile_wt_val = exe_lo_read_val;
        5'd28: regfile_wt_val = exe_cp0_read_val;
        default: regfile_wt_val = 0;
    endcase
    always @(*)
       case (addi_val[1:0]) 
           2'b00:  byte_enable_tmp = 4'b0001;
           2'b01:  byte_enable_tmp = 4'b0010;
           2'b10:  byte_enable_tmp = 4'b0100;
           2'b11:  byte_enable_tmp = 4'b1000;
           default:byte_enable_tmp = 4'b0000;
       endcase
   
       always @(*)
       case (exe_lw_sw_type) 
           3'd0, 3'd1, 3'd5:
               dmm_byte_enable = byte_enable_tmp;
           3'd2, 3'd3, 3'd6:                                                                 
               dmm_byte_enable = addi_val[1:0] == 2'b00 ? 4'b0011 : 4'b1100;                          
           3'd4, 3'd7:
               dmm_byte_enable = 4'b1111;
           default: 
               dmm_byte_enable = 4'b0000;
       endcase
    assign reverse_exe_regfile_rt_read_val = ~exe_regfile_rt_read_val + 1;
    always @(*)
    case (exe_regfile_aluctr)  
        5'd1: overflow = (exe_regfile_rs_read_val[31] & exe_regfile_rt_read_val[31] & ~add_val[31]) 
                | (~exe_regfile_rs_read_val[31] & ~exe_regfile_rt_read_val[31] & add_val[31]);
        5'd2: overflow = (exe_regfile_rs_read_val[31] & exe_sign_imm32[31] & ~addi_val[31]) 
                | (~exe_regfile_rs_read_val[31] & ~exe_sign_imm32[31] & addi_val[31]);
        5'd5: overflow = (exe_regfile_rs_read_val[31] & reverse_exe_regfile_rt_read_val[31] & ~sub_val[31]) 
                | (~exe_regfile_rs_read_val[31] & ~reverse_exe_regfile_rt_read_val[31] & sub_val[31]);
        default: overflow = 0;
    endcase


        
    always @(posedge clk)
        begin
            if (reset)
                counter <= 6'b0;
            else if (exe_start_div)
                counter <= 29;
            else if(exe_start_mult)
                counter <= 3;
            else if (!complete)
                counter = counter - 1;
        end
   assign complete  = ((exe_start_div == 0 && exe_start_mult == 0) && (counter == 0)) ? 1 : 0;
        
        
 mult_gen_0 multu (
          .CLK(clk),  
          .A(exe_regfile_rs_read_val),      
          .B(exe_regfile_rt_read_val),     
          .P({multu_hi_wt_val,multu_lo_wt_val})    
        );
        
 mult_gen_1 mult (
                 .CLK(clk), 
                 .A(exe_regfile_rs_read_val),      
                 .B(exe_regfile_rt_read_val),      
                 .P({mult_hi_wt_val,mult_lo_wt_val})      
               );
 div_gen_0 divu (
                 .aclk(clk),                                     
                 .s_axis_divisor_tvalid(1'b1),    
                 .s_axis_divisor_tdata(exe_regfile_rt_read_val),      
                 .s_axis_dividend_tvalid(1'b1),  
                 .s_axis_dividend_tdata(exe_regfile_rs_read_val),    
                 .m_axis_dout_tvalid(),          
                 .m_axis_dout_tdata({divu_lo_wt_val,divu_hi_wt_val})    
               );
 div_gen_1 div (
                               .aclk(clk),                                    
                               .s_axis_divisor_tvalid(1'b1),   
                               .s_axis_divisor_tdata(exe_regfile_rt_read_val),      
                               .s_axis_dividend_tvalid(1'b1),  
                               .s_axis_dividend_tdata(exe_regfile_rs_read_val),   
                               .m_axis_dout_tvalid(),         
                               .m_axis_dout_tdata({div_lo_wt_val,div_hi_wt_val})   
                               );       

    always @(*)
    case (exe_hilo_aluctr) 
        3'd1: hi_wt_val = div_hi_wt_val;
        3'd2: hi_wt_val = divu_hi_wt_val;
        3'd3: hi_wt_val = mult_hi_wt_val;
        3'd4: hi_wt_val = multu_hi_wt_val;
        3'd5: hi_wt_val = exe_regfile_rs_read_val;
        default: hi_wt_val = 0;
    endcase

    always @(*)
    case (exe_hilo_aluctr) 
        3'd1:lo_wt_val =  div_lo_wt_val;
        3'd2: lo_wt_val = divu_lo_wt_val;
        3'd3: lo_wt_val = mult_lo_wt_val;
        3'd4: lo_wt_val = multu_lo_wt_val;
        3'd6: lo_wt_val = exe_regfile_rs_read_val;
        default: lo_wt_val = 0;
    endcase
    
    assign cp0_wt_val = exe_cp0_wt_val;

    assign flush = exception_flush || harzard_flush_mem;
    always @(posedge clk)
    if (reset)
    begin
        mem_regfile_wren <= 0;
        mem_regfile_wt_addr <= 0;
        mem_regfile_mem2reg <= 0;
        mem_cp0_wren <= 0;
        mem_cp0_wt_addr <= 0;
        mem_lw_sw_type <=  0;
        mem_dmm_read <= 0;
        mem_dmm_write <= 0;
        mem_exception_if_exchappen = 0;
        mem_exception_dec_exchappen = 0;
        mem_exception_exe_exchappen = 0;
    end
    else if (ready && complete)
    begin
        mem_regfile_wren <= flush ?  0 : exe_regfile_wren;
        mem_regfile_wt_addr <= flush ?  0 : exe_regfile_wt_addr;
        mem_regfile_mem2reg <= flush ?  0 : exe_regfile_mem2reg;
        mem_cp0_wren <= flush ?  0 : exe_cp0_wren;
        mem_cp0_wt_addr <= flush ?  0 : exe_cp0_wt_addr;
        mem_lw_sw_type <= flush ?  0 : exe_lw_sw_type;
        mem_dmm_read <= flush ?  0 : exe_dmm_read;
        mem_dmm_write <= flush ?  0 : exe_dmm_write;
        mem_exception_if_exchappen = flush ?  0 : exe_exception_if_exchappen;
        mem_exception_dec_exchappen = flush ?  0 : exe_exception_dec_exchappen;
        mem_exception_exe_exchappen = flush ?  0 : exception_exe_exchappen;
    end

    always @(posedge clk)
    if (ready && complete)
    begin
        mem_pc <= flush ?  0 : exe_pc;
        mem_regfile_wt_val <= flush ?  0 : regfile_wt_val;
        mem_regfile_rt_read_val <= flush ?  0 : exe_regfile_rt_read_val;
        mem_cp0_wt_val <= flush ?  0 : exe_cp0_wt_val;       
        mem_dmm_addr <=flush ?  0 : addi_val;    
        mem_dmm_byte_enable <= flush ? 0 : dmm_byte_enable;   
        mem_rd_tab <= flush ? 0 : rd_tab;
        mem_exception_if_epc = flush ?  0 : exe_exception_if_epc;
        mem_exception_if_bd = flush ?  0 : exe_exception_if_bd;
        mem_exception_if_badvaddr =flush ?  0 :exe_exception_if_badvaddr;
        mem_exception_if_exccode = flush ?  0 : exe_exception_if_exccode;       
        mem_exception_dec_exccode = flush ?  0 : exe_exception_dec_exccode;       
        mem_exception_exe_exccode = flush ?  0 : exception_exe_exccode;
    end

    assign exception_exe_exchappen =  (overflow) ? 1 : 0;
    assign exception_exe_exccode   =  (overflow) ? 5'd12 : 0;
endmodule
    