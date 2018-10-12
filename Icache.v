module Icache(
    input wire              clk,
    input wire              reset,
    input wire [31:0]       pc,
    input wire [31:0]       pc_next,
    input wire              pc_wren,
    input wire              complete,
    input wire              D_ready,
    input wire              arready,
    input wire              rvalid,
    input wire              rlast,
    input wire [31:0]       rdata,

    output wire [31:0]      icache_inst,
    output wire             ready,
    output reg [31:0]       araddr,
    output reg [3:0]        arlen,
    output reg              arvalid,
    output wire[2:0]        state,
    output wire             not_ifetch_idle,
    output wire             not_ifetch_end
);

    wire        direct_access;
    wire        hit;
    wire [31:0] icache_addr;
    reg [3:0]  wr_off;
    reg [6:0] counter;
    wire[6:0] tab_addr;
    wire[19:0] tab_wrdata;
    wire[19:0] rd_tab;
    wire[3:0] word_shift;
    wire[31:0] icache_rdata;
    reg [19:0] pre_rd_tab;
    assign icache_addr =  (pc[31:29] == 3'b100 || pc[31:29] == 3'b101) ? {3'b000, pc[28:0]} : pc;
    assign direct_access = 0;
    
    always @(posedge clk)
    if (reset)
        pre_rd_tab <= 0;
    else if (pc_wren && complete &&D_ready&&ready)
        pre_rd_tab <= rd_tab;

always@(posedge clk)
begin
    if(reset)
        wr_off<= 0;
    else if (!direct_access)
        if(rlast&&rvalid)
            wr_off <= 0;
        else if(rvalid)
            wr_off <= wr_off + 1;
end

always @(posedge clk)
 if(~reset)
  counter <= 0;
 else
    if(reset && counter != 7'b1111111)
    counter =counter +1;
 
 assign tab_addr = reset ? counter : icache_addr[12:6];
 assign tab_wrdata = reset ? 20'b0 : {icache_addr[31:13],1'b1} ;
 

        dist_mem_gen_1 tab (
          .a(tab_addr),        
          .d(tab_wrdata),       
          .dpra(pc_next[12:6]),  
          .clk(clk),   
          .we(rvalid&&rlast&&!direct_access || reset),     
          .dpo(rd_tab)   
        );
assign word_shift = rvalid ? wr_off : pc[5:2];

dist_mem_gen_0 data (
  .a({icache_addr[12:6],word_shift}),      
  .d(rdata),     
  .clk(clk),  
  .we(rvalid && !direct_access),    
  .spo(icache_rdata) 
);


    reg [31:0] direct_data;
        always @(posedge clk)
        if(reset)
     direct_data <= 0;
    else if(rvalid && rlast)
        direct_data<= rdata;
assign icache_inst = direct_access ? direct_data : icache_rdata;

assign hit = (icache_addr[31:13] == pre_rd_tab[19:1]) && pre_rd_tab[0];

parameter  [2:0]   // synopsys enum code
                     IFETCH_IDLE = 3'd0,
                     ICACHE_MEMREAD_FIRST = 3'd1,
                     ICACHE_MEMREAD = 3'd2,
                     IDIRECT_MEMREAD_FIRST = 3'd3,
                     IDIRECT_MEMREAD = 3'd4,
                     IDIRECT_END = 3'd5,
                     ICACHE_END = 3'd6;
                    
// synopsys state_vector state
                     reg     [2:0]   // synopsys enum code
                                     CS, NS;
always @(posedge clk)
if (reset)
    CS <= IFETCH_IDLE;
else 
    CS <= NS;

always @(*)
begin
    NS = IFETCH_IDLE;      // synopsys full_case parallel_case
    case (CS)
        IFETCH_IDLE: 
        if (!direct_access && !hit)
            NS = ICACHE_MEMREAD_FIRST;
        else if (direct_access)
            NS = IDIRECT_MEMREAD_FIRST;
        else 
            NS = IFETCH_IDLE;
        ICACHE_MEMREAD_FIRST: 
        if (arready)
            NS = ICACHE_MEMREAD;
        else 
            NS = ICACHE_MEMREAD_FIRST;
        ICACHE_MEMREAD:
        if (rvalid && rlast)
            
            NS = ICACHE_END;
        else 
            NS = ICACHE_MEMREAD;
        IDIRECT_MEMREAD_FIRST:
        if (arready)
            NS = IDIRECT_MEMREAD;
        else 
            NS = IDIRECT_MEMREAD_FIRST;
        IDIRECT_MEMREAD:
        if (rvalid && rlast)
            NS = IDIRECT_END;
        else 
            NS = IDIRECT_MEMREAD;
        IDIRECT_END:
        if (pc_wren && complete &&D_ready)
            NS = IFETCH_IDLE;
        else 
            NS = IDIRECT_END;
       ICACHE_END:
       if (pc_wren && complete &&D_ready)
                   NS = IFETCH_IDLE;
               else 
                   NS = ICACHE_END;
       default: 
            NS = IFETCH_IDLE;
    endcase
end

always @(posedge clk)
if (reset)
begin
    araddr <= 0;
    arlen <= 0;
    arvalid <= 0;
end
else 
begin
    case (NS) 
        ICACHE_MEMREAD_FIRST:
        begin
            araddr <= {icache_addr[31:6], 6'd0 }; 
            arlen  <= 4'b1111;
            arvalid <= 1'b1;
        end
        ICACHE_MEMREAD:
        begin 
            araddr <= 0;
            arlen  <= 0;
            arvalid <= 1'b0;
        end
        IDIRECT_MEMREAD_FIRST:
        begin 
            araddr <= icache_addr;
            arlen  <= 4'b0000;
            arvalid <= 1'b1;
        end
        IDIRECT_MEMREAD:
        begin
            araddr <= 0;
            arlen  <= 0;
            arvalid <= 1'b0;
        end
        default:
        begin 
            araddr <= 0;
            arlen <= 0;
            arvalid <= 0;
        end
    endcase
end

assign ready = direct_access ? CS == IDIRECT_END : (hit || CS == ICACHE_END);
assign state = CS;
assign not_ifetch_idle = state != IFETCH_IDLE;
assign not_ifetch_end = state != IDIRECT_END &&  state != ICACHE_END;
endmodule





