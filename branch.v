module branch (
    input wire [31:0]			branch_address,
	input wire [31:0]			jump_address,
	input wire [2:0]			branch, // branch and jump
	input wire         		    inst_jr,
    input wire                  inst_eret,
    input wire                  exception_happen,	
	input wire [31:0]			regfile_rs_read_val,
	input wire [31:0]			regfile_rt_read_val,
	output reg [1:0]  			PCSrc,
	output wire [31:0]			branch_target,
	output wire					branch_flush
);

	wire 						sign;
	wire						not_zero;
	wire						beq;
	wire						bgez;
	wire						bgtz;
	reg						    branch_happen;


	assign sign = regfile_rs_read_val[31];
	assign not_zero = |regfile_rs_read_val;

	assign beq = (regfile_rs_read_val == regfile_rt_read_val);
	assign bgez = ~sign;
	assign bgtz = ~sign && not_zero;
	
	always @(*)
	case (branch)  // synopsys full_case parallel_case
		//3'b000:	branch_happen = 0;
		3'b001: branch_happen = beq;
		3'b010: branch_happen = !beq;
		3'b011: branch_happen = bgez;
		3'b100: branch_happen = bgtz;
		3'b101: branch_happen = !bgtz;
		3'b110: branch_happen = !bgez;
		3'b111: branch_happen = 1;
		default:branch_happen = 0;
	endcase

	always @(*)
	casex ({branch_happen, inst_eret, exception_happen})  // synopsys full_case parallel_case
		3'bxx1: PCSrc = 3;
		3'b010: PCSrc = 2;
		3'b1x0: PCSrc = 1;
		default:PCSrc = 0;
	endcase
	assign branch_flush = PCSrc == 1;
	assign branch_target = (branch == 3'b111) ? jump_address : branch_address;

endmodule