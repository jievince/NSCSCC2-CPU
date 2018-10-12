module Memory_System(
     input wire         clk,
     input wire         reset,
     input wire [31:0]  pc,
     input wire [31:0]  pc_next,
     input wire         pc_wren,
     input wire         complete,
     input wire         exception_inst_exchappen,
     input wire [20:0]  mem_rd_tab,
     input wire [31:0]  exe_dmm_addr,
     output wire [20:0] rd_tab,

     input wire [31:0]  mem_dmm_addr,
     input wire [2:0]   mem_lw_sw_type,
     input wire         dmm_read,
     input wire         dmm_write,
     input wire[3:0]    wen,
     input wire [31:0]        store_val,
     output[3:0]        arid,
     output[31:0]       araddr,
     output[3:0]        arlen,
     output[2:0]        arsize,
     output[1:0]        arburst,
     output[1:0]        arlock,
     output[3:0]        arcache,
     output[2:0]        arprot,
     output             arvalid,
     input              arready,
                
     input[3:0]         rid,
     input[31:0]        rdata,
     input[1:0]         rresp,
     input              rlast,
     input              rvalid,
     output             rready,
               
     output[3:0]      awid,
     output[31:0]     awaddr,
     output[3:0]      awlen,
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
     output           ready,
     output[31:0]     icache_inst,
     output[31:0]    dcache_rdata
);

    wire             I_arready;
    wire             I_rvalid;
    wire             I_rlast;
    wire[31:0]       I_rdata;
    wire             I_ready;
    wire[31:0]       I_araddr;
    wire[3:0]        I_arlen;
    wire             I_arvalid;
    wire[3:0]        I_wstrb;
    wire             D_arready;
    wire             D_awready;
    wire             D_wready;
    wire             D_rvalid;
    wire             D_rlast;
    wire[31:0]       D_rdata;
    wire             D_awvalid;
    wire             D_bvalid;
    wire             D_wvalid;
    wire[31:0]       D_araddr;
    wire[3:0]        D_arlen;
    wire             D_arvalid;
    wire[31:0]       D_awaddr;
    wire[3:0]        D_awlen;
    wire[31:0]       D_wdata;
    wire             D_wlast;
    wire             D_ready;
    wire[3:0]        D_wstrb;
    wire[34:0]       axi_to_icache;
    wire[37:0]       axi_to_dcache;
    wire[111:0]      icache_to_axi;
    wire[111:0]      dcache_to_axi;
    wire[111:0]      axi_input;
    wire[2:0]        I_state;
    wire[3:0]        D_state;
    wire            not_ifetch_idle;
    wire            not_ifetch_end;
    wire            not_dfetch_idle;
    
    assign arid =4'b0;
    assign arsize = 3'b010;
    assign arburst = 2'b01;
    assign arlock = 2'b00;
    assign arcache = 4'b0000;
    assign arprot = 3'b000;
    assign rready =1'b1;
    assign awid = 4'b0000;
    assign awsize =3'b010;
    assign awburst =2'b01;
    assign awlock =2'b00;
    assign awcache = 4'b0000;
    assign awprot = 3'b000;
    assign wid= 4'b0000;
    assign bready =1'b1;
    assign I_wstrb = 4'b1111;
    Icache IC(
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .pc_next(pc_next),
        .pc_wren(pc_wren),
        .complete(complete),
        .D_ready(D_ready),
        .arready(I_arready),
        .rvalid(I_rvalid),
        .rlast(I_rlast),
        .rdata(I_rdata),

        .icache_inst(icache_inst),
        .ready(I_ready),
        .araddr(I_araddr),
        .arlen(I_arlen),
        .arvalid(I_arvalid),
        .state(I_state),
        .not_ifetch_idle(not_ifetch_idle),
        .not_ifetch_end(not_ifetch_end)
    );
    Dcache DC(
        .clk(clk),
        .reset(reset),
        .complete(complete),
        .I_ready(I_ready),
        .exception_inst_exchappen(exception_inst_exchappen),
        .dmm_write(dmm_write),
        .dmm_read(dmm_read),
        .wen(wen),
        .mem_dmm_addr(mem_dmm_addr),
        .mem_lw_sw_type(mem_lw_sw_type),
        .dmm_data(store_val),
        .arready(D_arready),
        .awready(D_awready),
        .wready(D_wready),
        .rvalid(D_rvalid),
        .rlast(D_rlast),
        .rdata(D_rdata),
        .bvalid(D_bvalid),
        .mem_rd_tab(mem_rd_tab),
        .exe_dmm_addr(exe_dmm_addr),
        
        .rd_tab(rd_tab),
        .araddr(D_araddr),
        .arlen(D_arlen),
        .arvalid(D_arvalid),
        .awaddr(D_awaddr),
        .awlen(D_awlen),
        .awvalid(D_awvalid),
        .wdata(D_wdata),
        .wlast(D_wlast),
        .wvalid(D_wvalid),
        .wstrb(D_wstrb),
        .ready(D_ready),
        .state(D_state),
        .dcache_rdata(dcache_rdata),
        .not_dfetch_idle(not_dfetch_idle)
    );
    assign ready = I_ready&&D_ready;

    assign {I_arready,I_rdata,I_rlast,I_rvalid} = axi_to_icache;
    assign {D_arready,D_rdata,D_rlast,D_rvalid,D_awready,D_wready,D_bvalid} = axi_to_dcache;
    assign axi_to_icache = (not_ifetch_idle && not_ifetch_end) ? {arready,rdata,rlast,rvalid} : 0;
    
    assign axi_to_dcache =  not_dfetch_idle &&(!not_ifetch_idle || !not_ifetch_end) ? {arready,rdata,rlast,rvalid,awready,wready,bvalid} :0;
    assign icache_to_axi = {I_araddr,I_arlen,I_arvalid,I_wstrb,71'b0};
    assign dcache_to_axi = {D_araddr,D_arlen,D_arvalid,D_wstrb,D_awaddr,D_awlen,D_awvalid,D_wdata,D_wlast,D_wvalid};
    assign {araddr,arlen,arvalid,wstrb,awaddr,awlen,awvalid,wdata,wlast,wvalid} = axi_input;
    assign axi_input = ( not_ifetch_idle  && not_ifetch_end ) ? icache_to_axi  :  dcache_to_axi;

endmodule



 