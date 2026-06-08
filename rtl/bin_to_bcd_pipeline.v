//=====================================================================================
//			Pipelined Bin to BCD Converter  Module
//
//			Parameters:
//				INPUT_WIDTH - input (binary) data width
//				OUTPUT_WIDTH - output (BCD) data width
//
//			Control Signals:
//				clk - clock signal
//				rst_n – reset (Active-Low)
//				in_valid - signal to start calculating the BCD
//
//			Data:
//				bin_in - input (binary) data
//				bcd_out - output (BCD) data
//				out_valid - BCD ready signal				
//=====================================================================================

module bin_to_bcd_pipeline
#(
	parameter INPUT_WIDTH = 16,
	parameter OUTPUT_WIDTH = ((INPUT_WIDTH * 302) / 1000 + 1) * 4 // OUTPUT_WIDTH = floor(INPUT_WIDTH * log10(2)) + 1
)
(
	input clk, // Clock
	input rst_n, // Reset
	input in_valid, // Start calculating the BCD
	input [INPUT_WIDTH - 1:0] bin_in, // Input (binary) data
	output [OUTPUT_WIDTH - 1:0] bcd_out, // Output (BCD) data
	output out_valid // BCD ready
);

reg [INPUT_WIDTH - 1:0] bin_pipe [0:INPUT_WIDTH]; // Binary data pipeline
reg [OUTPUT_WIDTH - 1:0] bcd_pipe [0:INPUT_WIDTH]; // BCD data pipeline
reg valid_pipe [0:INPUT_WIDTH]; // Valid pipeline

//=====================================================================================
// Writing data to the first register of the pipeline
//=====================================================================================
always @ (posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		valid_pipe[0] <= 1'b0;
		bin_pipe[0] <= 0;
		bcd_pipe[0] <= 0;
	end
	else begin
		valid_pipe[0] <= in_valid;
		bin_pipe[0] <= bin_in;
		bcd_pipe[0] <= 0;
	end
end

//=====================================================================================
// Pipeline and Calculation
//=====================================================================================
genvar s;
generate
	for (s = 0; s < INPUT_WIDTH; s = s + 1) begin : pipe_stage
		reg [OUTPUT_WIDTH - 1:0] bcd_adjusted;
		integer i;
		
		// ADD
		always @ (*) begin
			bcd_adjusted = bcd_pipe[s];
			for (i = 0; i < OUTPUT_WIDTH / 4; i = i + 1) begin
				if (bcd_pipe[s][i * 4 +: 4] >= 5) begin
					bcd_adjusted[i * 4 +: 4] = bcd_pipe[s][i * 4 +: 4] + 3;
				end
			end
		end
		
		// SHIFT
		always @ (posedge clk, negedge rst_n) begin
			if (!rst_n) begin
				valid_pipe[s + 1] <= 1'b0;
				bcd_pipe[s + 1] <= 0;
				bin_pipe[s + 1] <= 0;
			end
			else begin
				valid_pipe[s + 1] <= valid_pipe[s];
				{bcd_pipe[s + 1], bin_pipe[s + 1]} <= {bcd_adjusted, bin_pipe[s]} << 1;
			end
		end
	end
endgenerate

//=====================================================================================
// Output Data
//=====================================================================================
assign bcd_out = bcd_pipe[INPUT_WIDTH];
assign out_valid = valid_pipe[INPUT_WIDTH];

endmodule