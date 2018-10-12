module if_stage (
    input wire              clk,
    input wire              reset,
    input wire [1:0]        PCSrc,
    input wire [31:0]       branch_target,
    input wire [31:0]       cp0_epc_val,
    input wire              pc_wren,
    input wire              dec_wren,
    input wire              ready,
    input wire              complete,
    input wire              exception_flush,
    input wire              branch_flush,
    input wire              eret_flush,
    input wire              bd,
    input wire [31:0]       icache_inst,

    output reg [31:0]       pc,
    output reg  [31:0]      pc_next,
    output reg [31:0]       dec_inst,
    output reg [31:0]       dec_pcplus4,
    output reg [31:0]       dec_pcplus8,
    output reg [31:0]       dec_pc,
    output reg              dec_exception_if_exchappen,
    output reg [31:0]       dec_exception_if_epc,
    output reg              dec_exception_if_bd,
    output reg [31:0]       dec_exception_if_badvaddr,
    output reg [4:0]        dec_exception_if_exccode          
);
    
    wire [31:0]       pcplus4;
    wire [31:0]       pcplus8;
    wire              exception_if_exchappen;
    wire [31:0]       exception_if_epc;
    wire              exception_if_bd;
    wire [31:0]       exception_if_badvaddr;
    wire [4:0]        exception_if_exccode;
    wire              flush;

 assign flush  = PCSrc != 0;

    assign pcplus4 = pc + 4;
    assign pcplus8 = pc + 8;
    always@(*)
    case(PCSrc) 
        2'b00 : pc_next = pcplus4;
        2'b01 : pc_next = branch_target;
        2'b10 : pc_next = cp0_epc_val;
        2'b11 : pc_next = 32'hbfc00380;
      default : pc_next =  pcplus4;
      endcase
    
    always @(posedge clk)
    if (reset)
        pc <= 32'hbfc00000;
    else if (pc_wren && ready && complete)
        pc <= pc_next;

    assign exception_if_epc = bd ? pc - 4 : pc;
    assign exception_if_bd = bd;
    assign exception_if_badvaddr = pc;
    assign exception_if_exchappen = (pc[1:0] != 2'b00 ) ?  1 : 0;
    assign exception_if_exccode =  (pc[1:0] != 2'b00 ) ?  5'd4 : 0;


    always@(posedge clk)
    if(reset)
    begin
        dec_inst <= 0;
        dec_exception_if_exchappen <= 0;
    end
    else if(dec_wren && ready && complete)
    begin
         dec_inst <= flush ?  0  : icache_inst;
         dec_exception_if_exchappen <=  flush ? 0 : exception_if_exchappen;
    end

    always @(posedge clk)
     if (dec_wren && ready && complete)
    begin
        dec_pcplus4 <= flush ? 0 : pcplus4;
        dec_pcplus8 <= flush ? 0 : pcplus8;
        dec_pc <= flush ? 0 : pc;
        dec_exception_if_epc <= flush ? 0 : exception_if_epc;
        dec_exception_if_bd <= flush ? 0 : exception_if_bd;
        dec_exception_if_badvaddr <= flush ? 0 : exception_if_badvaddr;
        dec_exception_if_exccode  <= flush ? 0 : exception_if_exccode;
    end
    
endmodule



