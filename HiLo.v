module HiLo( 
    input wire                      clk,
    input wire                      reset,
    input wire                      exe_hi_wren,
    input wire                      exe_lo_wren,
    input wire [31:0]               exe_hi_wt_val,
    input wire [31:0]               exe_lo_wt_val,
    input wire                      ready,
    input wire                      complete,
    input wire                      exception_flush,
 
    output wire [31:0]              hi_read_val,
    output wire [31:0]              lo_read_val 
);

    reg [31:0]      				hi = 0;
    reg [31:0]                      lo = 0;

	always @(posedge clk)
	if(reset)
	   hi<= 0;

    else if (exe_hi_wren && ready && complete && !exception_flush)
        hi <= exe_hi_wt_val;

    always @(posedge clk)
    if(reset)
        lo<= 0;
     else if (exe_lo_wren && ready && complete && !exception_flush)
        lo <= exe_lo_wt_val;

    // hilo bypass
    assign hi_read_val = exe_hi_wren ? exe_hi_wt_val : hi;
    assign lo_read_val = exe_lo_wren ? exe_lo_wt_val : lo;

endmodule

