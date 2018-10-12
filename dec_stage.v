module dec_stage (
    input wire              clk,
    input wire              reset,
    input wire [31:0]       dec_inst,
    input wire [31:0]       dec_pcplus4,
    input wire [31:0]       dec_pcplus8,
    input wire [31:0]       dec_pc,
    input wire              dec_exception_if_exchappen,
    input wire [31:0]       dec_exception_if_epc,
    input wire              dec_exception_if_bd,
    input wire [31:0]       dec_exception_if_badvaddr,
    input wire [4:0]        dec_exception_if_exccode,
    input wire              ready,
    input wire              complete,
    input wire              exception_flush,
    input wire              branch_flush,
    input wire [31:0]       regfile_rs_read_val,
    input wire [31:0]       regfile_rt_read_val,
    input wire [31:0]       hi_read_val,
    input wire [31:0]       lo_read_val,
    input wire [31:0]       cp0_read_val,
    input wire [31:0]       cp0_status_val,
    input wire              mem_dmm_read,
    input wire [4:0]        mem_regfile_wt_addr,
	input wire [2:0]		mem_lw_sw_type,

    output wire             eret_flush,
    output wire             bd,
    output wire             pc_wren,
    output wire             dec_wren,
    output wire             harzard_flush_mem,
    output wire             inst_eret,
    output wire [4:0]       regfile_rs_addr,
    output wire [4:0]       regfile_rt_addr,
    output wire [4:0]       cp0_read_addr,
    output reg [31:0]       exe_pcplus4,
    output reg [31:0]       exe_pcplus8,
    output reg [31:0]       exe_pc,
    output reg              exe_regfile_wren,
    output reg [4:0]        exe_regfile_wt_addr,
    output reg              exe_regfile_mem2reg,
    output reg [31:0]       exe_regfile_rs_read_val,
    output reg [31:0]       exe_regfile_rt_read_val,
    output reg [4:0]        exe_regfile_aluctr,
    output reg              exe_hi_wren,
    output reg [31:0]       exe_hi_read_val,
    output reg              exe_lo_wren,
    output reg [31:0]       exe_lo_read_val,
    output reg [2:0]        exe_hilo_aluctr,
    output reg              exe_cp0_wren,
    output reg [4:0]        exe_cp0_wt_addr,
    output reg [31:0]       exe_cp0_wt_val,
    output reg [31:0]       exe_cp0_read_val,
    output reg [31:0]       exe_sign_imm32,
    output reg [31:0]       exe_unsign_imm32,
    output reg [2:0]        exe_branch,
    output reg              exe_inst_jr,
    output reg [31:0]       exe_branch_address,
    output reg [31:0]       exe_jump_address,
    output reg              exe_start_div,
    output reg              exe_start_mult,
    output reg [2:0]        exe_lw_sw_type,
    output reg              exe_dmm_read,
    output reg              exe_dmm_write,
    output reg              exe_exception_if_exchappen,
    output reg [31:0]       exe_exception_if_epc,
    output reg              exe_exception_if_bd,
    output reg [31:0]       exe_exception_if_badvaddr,
    output reg [4:0]        exe_exception_if_exccode,
    output reg              exe_exception_dec_exchappen,
    output reg [4:0]        exe_exception_dec_exccode
);
    // decoder
    wire                        start_div_tmp;
    wire                        start_mult_tmp;
    wire [4:0]                   regfile_rd_addr;   
    wire                         harzard_flush;
    wire                         regfile_wren;
    wire [4:0]                   regfile_wt_addr;
    wire                         regfile_mem2reg;
    wire [4:0]                   regfile_aluctr;
    wire [1:0]                   regfile_wt_addr_sel;
    wire                         hi_wren;
    wire                         lo_wren;    
    wire [2:0]                   hilo_aluctr;
    wire                         cp0_wren;
    wire [4:0]                   cp0_wt_addr;
    wire [31:0]                  cp0_wt_val;
    wire [31:0]                  unsign_imm32;
    wire                         start_div;
    wire                         start_mult;
    wire [2:0]                   lw_sw_type;
    wire                         dmm_read;
    wire                         dmm_write;
    wire                         inst_break;
    wire                         inst_syscall;
    wire                         inst_reserved;
    wire                         inst_jr;
    wire                         exception_dec_exchappen;
    wire [4:0]                   exception_dec_exccode;
    reg [30:0]                   control_code;
    wire                         flush;
    wire[31:0]                   jump_address;
    wire[31:0]                   branch_address;
    wire [31:0]                  sign_imm32;
    wire [25:0]                  imm26;
    wire [2:0]                   branch;
    assign flush = exception_flush || branch_flush || harzard_flush;

    assign regfile_rs_addr = dec_inst[25:21];
    assign regfile_rt_addr = dec_inst[20:16];
    assign regfile_rd_addr = dec_inst[15:11];
    assign imm26 = dec_inst[25:0];
    assign regfile_wt_addr = regfile_wt_addr_sel == 2'd1 ? regfile_rt_addr :
                              (regfile_wt_addr_sel == 2'd2 ? regfile_rd_addr : (regfile_wt_addr_sel == 2'd3 ? 5'd31 : 0));
    assign cp0_read_addr = regfile_rd_addr;
    assign cp0_wt_addr = inst_eret ? 5'd12 : regfile_rd_addr; //eret or mtc0
    assign cp0_wt_val = inst_eret ? {cp0_status_val[31:2], 1'b0, cp0_status_val[0]} : regfile_rt_read_val;
    assign sign_imm32 = {{16{dec_inst[15]}}, dec_inst[15:0]};
    assign unsign_imm32 = {16'b0, dec_inst[15:0]};
    assign eret_flush = inst_eret;
    assign {bd, regfile_wren, regfile_mem2reg, regfile_aluctr, regfile_wt_addr_sel, hi_wren, lo_wren, hilo_aluctr, cp0_wren, 
      branch, start_div,start_mult, lw_sw_type, dmm_read, dmm_write, inst_break, inst_syscall, inst_eret, inst_reserved, inst_jr} = control_code;
    assign branch_address = dec_pcplus4 + {sign_imm32[29:0] ,2'b0};
    assign jump_address = inst_jr? regfile_rs_read_val: ({dec_pcplus4[31:28], imm26, 2'b00});

    always @(*)
    casex (dec_inst) 
    32'b000000xxxxxxxxxxxxxxx00000100000: //add  
        control_code = 31'b0100000110000000000000000000000;
    32'b001000xxxxxxxxxxxxxxxxxxxxxxxxxx: //addi
        control_code = 31'b0100001001000000000000000000000;
    32'b000000xxxxxxxxxxxxxxx00000100001: //addu
        control_code = 31'b0100001110000000000000000000000;
    32'b001001xxxxxxxxxxxxxxxxxxxxxxxxxx: //addiu
        control_code = 31'b0100010001000000000000000000000;
    32'b000000xxxxxxxxxxxxxxx00000100010: //sub
        control_code = 31'b0100010110000000000000000000000;
    32'b000000xxxxxxxxxxxxxxx00000100011: //subu
        control_code = 31'b0100011010000000000000000000000;
    32'b000000xxxxxxxxxxxxxxx00000101010: //slt
        control_code = 31'b0100011110000000000000000000000;
    32'b001010xxxxxxxxxxxxxxxxxxxxxxxxxx: //slti
        control_code = 31'b0100100001000000000000000000000;
    32'b000000xxxxxxxxxxxxxxx00000101011: //sltu
        control_code = 31'b0100100110000000000000000000000;
    32'b001011xxxxxxxxxxxxxxxxxxxxxxxxxx: //sltiu
        control_code = 31'b0100101001000000000000000000000;
    32'b000000xxxxxxxxxx0000000000011010: //div
        control_code = 31'b0000000000110010000100000000000;
    32'b000000xxxxxxxxxx0000000000011011: //divu
        control_code = 31'b0000000000110100000100000000000;
    32'b000000xxxxxxxxxx0000000000011000: //mult
        control_code = 31'b0000000000110110000010000000000;
    32'b000000xxxxxxxxxx0000000000011001: //multu
        control_code = 31'b0000000000111000000010000000000;
    32'b000000xxxxxxxxxxxxxxx00000100100: //and
        control_code = 31'b0100101110000000000000000000000;
    32'b001100xxxxxxxxxxxxxxxxxxxxxxxxxx: //andi
        control_code = 31'b0100110001000000000000000000000;
    32'b00111100000xxxxxxxxxxxxxxxxxxxxx: //lui
        control_code = 31'b0100110101000000000000000000000;
    32'b000000xxxxxxxxxxxxxxx00000100111: //nor
        control_code = 31'b0100111010000000000000000000000;
    32'b000000xxxxxxxxxxxxxxx00000100101: //or
        control_code = 31'b0100111110000000000000000000000;
    32'b001101xxxxxxxxxxxxxxxxxxxxxxxxxx: //ori
        control_code = 31'b0101000001000000000000000000000;
    32'b000000xxxxxxxxxxxxxxx00000100110: //xor
        control_code = 31'b0101000110000000000000000000000;
    32'b001110xxxxxxxxxxxxxxxxxxxxxxxxxx: //xori
        control_code = 31'b0101001001000000000000000000000;
    32'b000000xxxxxxxxxxxxxxx00000000100: //sllv
        control_code = 31'b0101010010000000000000000000000;
    32'b00000000000xxxxxxxxxxxxxxx000000: //sll
        control_code = 31'b0101001110000000000000000000000;
    32'b000000xxxxxxxxxxxxxxx00000000111: //srav
        control_code = 31'b0101011010000000000000000000000;
    32'b00000000000xxxxxxxxxxxxxxx000011: //sra
        control_code = 31'b0101010110000000000000000000000;
    32'b000000xxxxxxxxxxxxxxx00000000110: //srlv
        control_code = 31'b0101100010000000000000000000000;
    32'b00000000000xxxxxxxxxxxxxxx000010: //srl
        control_code = 31'b0101011110000000000000000000000;
    32'b000100xxxxxxxxxxxxxxxxxxxxxxxxxx: //beq
        control_code = 31'b1000000000000000001000000000000;
    32'b000101xxxxxxxxxxxxxxxxxxxxxxxxxx: //bne
        control_code = 31'b1000000000000000010000000000000;
    32'b000001xxxxx00001xxxxxxxxxxxxxxxx: //bgez
        control_code = 31'b1000000000000000011000000000000;
    32'b000111xxxxx00000xxxxxxxxxxxxxxxx: //bgtz
        control_code = 31'b1000000000000000100000000000000;
    32'b000110xxxxx00000xxxxxxxxxxxxxxxx: //blez
        control_code = 31'b1000000000000000101000000000000;
    32'b000001xxxxx00000xxxxxxxxxxxxxxxx: //bltz
        control_code = 31'b1000000000000000110000000000000;
    32'b000001xxxxx10001xxxxxxxxxxxxxxxx: //bgezal
        control_code = 31'b1101100111000000011000000000000;
    32'b000001xxxxx10000xxxxxxxxxxxxxxxx: //bltzal
        control_code = 31'b1101100111000000110000000000000;
    32'b000010xxxxxxxxxxxxxxxxxxxxxxxxxx: //j
        control_code = 31'b1000000000000000111000000000000;
    32'b000011xxxxxxxxxxxxxxxxxxxxxxxxxx: //jal
        control_code = 31'b1101100111000000111000000000000;
    32'b000000xxxxx000000000000000001000: //jr
        control_code = 31'b1000000000000000111000000000001;
    32'b000000xxxxx00000xxxxx00000001001: //jalr
        control_code = 31'b1101100111000000111000000000001;
    32'b0000000000000000xxxxx00000010000: //mfhi
        control_code = 31'b0101101010000000000000000000000;
    32'b0000000000000000xxxxx00000010010: //mflo
        control_code = 31'b0101101110000000000000000000000;
    32'b000000xxxxx000000000000000010001: //mthi
        control_code = 31'b0000000000101010000000000000000;
    32'b000000xxxxx000000000000000010011: //mtlo
        control_code = 31'b0000000000011100000000000000000;
    32'b000000xxxxxxxxxxxxxxxxxxxx001101: //break
        control_code = 31'b0000000000000000000000000010000;
    32'b000000xxxxxxxxxxxxxxxxxxxx001100: //syscall
        control_code = 31'b0000000000000000000000000001000;
    32'b100000xxxxxxxxxxxxxxxxxxxxxxxxxx: //lb
        control_code = 31'b0110000001000000000000001000000;
    32'b100100xxxxxxxxxxxxxxxxxxxxxxxxxx: //lbu
        control_code = 31'b0110000001000000000000011000000;
    32'b100001xxxxxxxxxxxxxxxxxxxxxxxxxx: //lh
        control_code = 31'b0110000001000000000000101000000;
    32'b100101xxxxxxxxxxxxxxxxxxxxxxxxxx: //lhu
        control_code = 31'b0110000001000000000000111000000;
    32'b100011xxxxxxxxxxxxxxxxxxxxxxxxxx: //lw
        control_code = 31'b0110000001000000000001001000000;
    32'b101000xxxxxxxxxxxxxxxxxxxxxxxxxx: //sb
        control_code = 31'b0000000000000000000001010100000;
    32'b101001xxxxxxxxxxxxxxxxxxxxxxxxxx: //sh
        control_code = 31'b0000000000000000000001100100000;
    32'b101011xxxxxxxxxxxxxxxxxxxxxxxxxx: //sw
        control_code = 31'b0000000000000000000001110100000;
    32'b01000010000000000000000000011000: //eret
        control_code = 31'b0000000000000001000000000000100;
    32'b01000000000xxxxxxxxxx00000000xxx: //mfc0
        control_code = 31'b0101110001000000000000000000000;
    32'b01000000100xxxxxxxxxx00000000xxx: //mtc0
        control_code = 31'b0000000000000001000000000000000;
    32'b01000010000000000000000000001000, //tlbp
    32'b01000010000000000000000000000001, //tlbr
    32'b01000010000000000000000000000010, //tlbwi
    32'b01000010000000000000000000000110, //tlbwr
    32'b101111xxxxxxxxxxxxxxxxxxxxxxxxxx: //cache
        control_code = 31'b00000000000000000000000000000000;  
    default:                              //reserved inst
        control_code = 31'b0000000000000000000000000000010;
endcase

    // hardzard detect
    wire harzard_detected_exe;
    wire harzard_detected_mem;
    wire exe_wren;
    assign harzard_detected_exe = !exception_flush && 
             (exe_dmm_read && (exe_regfile_wt_addr == regfile_rs_addr || exe_regfile_wt_addr == regfile_rt_addr) && exe_regfile_wt_addr != 0);
    assign harzard_detected_mem = !exception_flush &&
            (mem_dmm_read && mem_lw_sw_type[2]==1'b0 && (mem_regfile_wt_addr == regfile_rs_addr || mem_regfile_wt_addr == regfile_rt_addr) && mem_regfile_wt_addr != 0);

    assign pc_wren = (harzard_detected_exe || harzard_detected_mem) ? 0 : 1;
    assign dec_wren = ( harzard_detected_exe || harzard_detected_mem) ? 0 : 1;
    assign exe_wren = harzard_detected_mem ? 0 : 1;
    assign harzard_flush =  harzard_detected_exe ? 1 :0;
    assign harzard_flush_mem = harzard_detected_mem;


    
    assign  start_div_tmp = flush?  0 : start_div;
    assign  start_mult_tmp = flush?  0 : start_mult;

 
    always @(posedge clk)
    if (reset)
    begin
        exe_regfile_wren <= 0;
        exe_regfile_wt_addr <= 0;
        exe_regfile_mem2reg <= 0;
        exe_regfile_aluctr <= 0;
        exe_hi_wren <= 0;
        exe_lo_wren <= 0;
        exe_hilo_aluctr <= 0;
        exe_cp0_wren <= 0;
        exe_cp0_wt_addr <= 0;
        exe_branch <= 0;
        exe_inst_jr <= 0;
        exe_lw_sw_type <= 0;
        exe_dmm_read <= 0;
        exe_dmm_write <= 0;
        exe_exception_if_exchappen <= 0;
        exe_exception_dec_exchappen <= 0;
    end
    else if(ready && complete && exe_wren)
    begin
        exe_regfile_wren <= flush?  0 : regfile_wren;
        exe_regfile_wt_addr <= flush?  0 : regfile_wt_addr;
        exe_regfile_mem2reg <= flush?  0 : regfile_mem2reg;
        exe_regfile_aluctr <= flush?  0 : regfile_aluctr;
        exe_hi_wren <= flush?  0 : hi_wren;
        exe_lo_wren <= flush?  0 : lo_wren;
        exe_hilo_aluctr <= flush?  0 : hilo_aluctr;
        exe_cp0_wren <= flush?  0 : cp0_wren;
        exe_cp0_wt_addr <= flush?  0 : cp0_wt_addr;
        exe_branch <= flush?  0 : branch;
        exe_inst_jr <= flush?  0 : inst_jr;
        exe_lw_sw_type <= flush?  0 : lw_sw_type;
        exe_dmm_read <= flush?  0 :  dmm_read;
        exe_dmm_write <= flush?  0 :  dmm_write;
        exe_exception_if_exchappen <= flush?  0 : dec_exception_if_exchappen;
        exe_exception_dec_exchappen <= flush?  0 :  exception_dec_exchappen;
    end

    always @(posedge clk)
    if (ready && complete && exe_wren)
    begin
        exe_branch_address <=flush?  0 : branch_address;
        exe_jump_address <= flush?  0 :jump_address;
        exe_pcplus4 <=  flush?  0 : dec_pcplus4;
        exe_pcplus8 <=  flush?  0 :dec_pcplus8;
        exe_pc <= flush?  0 :dec_pc;
        exe_regfile_rs_read_val <= regfile_rs_read_val;
        exe_regfile_rt_read_val <=  regfile_rt_read_val;
        exe_hi_read_val <= flush?  0 : hi_read_val;
        exe_lo_read_val <= flush?  0 :  lo_read_val;
        exe_cp0_wt_val <= flush?  0 :  cp0_wt_val;
        exe_cp0_read_val <= flush?  0 :  cp0_read_val;
        exe_sign_imm32 <= flush?  0 : sign_imm32;
        exe_unsign_imm32 <= flush?  0 : unsign_imm32;
        exe_exception_if_epc <= flush?  0 : dec_exception_if_epc;
        exe_exception_if_bd <= flush?  0 : dec_exception_if_bd;
        exe_exception_if_badvaddr <= flush?  0 : dec_exception_if_badvaddr;
        exe_exception_if_exccode <= flush?  0 :  dec_exception_if_exccode;
        exe_exception_dec_exccode <= flush?  0 :exception_dec_exccode;
    end


    always @(posedge clk)
    if(reset)
        begin
        exe_start_div <= 0;
        exe_start_mult<= 0;
        end
    else if((ready && exe_wren) || !complete)
        begin
        exe_start_div<= ( complete == 1) ? start_div_tmp : 0;
        exe_start_mult<= (complete == 1 ) ? start_mult_tmp :0;
        end

    assign exception_dec_exchappen = (inst_break || inst_syscall || inst_reserved) ?  1 : 0;
    assign exception_dec_exccode =  inst_break ? 5'd9 : (inst_syscall ? 5'd8 : (inst_reserved ? 5'd10 : 0));  

endmodule
