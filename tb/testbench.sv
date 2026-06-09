//=====================================================================================
//		Bin to BCD Converter Testbench Module
//
//		The module is used to test the Bin to BCD Converter.
//		The test was conducted in ModelSim 10.6d.
//		To verify the correct operation of the Bin to BCD Converter module, it's necessary to display signal waveforms.
//		The console displays messages about the start of test and errors;
//		Finally, a success/failure message is displayed, along with the number of errors, if any.
//
//=====================================================================================

`timescale 1 ns / 1 ps

module testbench;

parameter CLK_PERIOD = 20;
parameter RESET_CYCLES = 10;
parameter RAND_CYCLES = 100;
parameter INPUT_WIDTH = 16;
parameter OUTPUT_WIDTH = ((INPUT_WIDTH * 302) / 1000 + 1) * 4;

logic clk;
logic rst_n;
logic in_valid;
logic [INPUT_WIDTH - 1:0] bin_in;
logic [OUTPUT_WIDTH - 1:0] bcd_out;
logic out_valid;

logic in_valid_pipe;
logic [INPUT_WIDTH - 1:0] bin_in_pipe;
logic [OUTPUT_WIDTH - 1:0] bcd_out_pipe;
logic out_valid_pipe;

integer error_count = 0;
integer error_count_pipe = 0;

//=====================================================================================
// Bin to BCD Converter Instantiation
//=====================================================================================
bin_to_bcd_pipeline #(.INPUT_WIDTH(INPUT_WIDTH), .OUTPUT_WIDTH(OUTPUT_WIDTH)) dut_pipe
(
	.clk(clk),
	.rst_n(rst_n),
	.in_valid(in_valid_pipe),
	.bin_in(bin_in_pipe),
	.bcd_out(bcd_out_pipe),
	.out_valid(out_valid_pipe)
);

bin_to_bcd #(.INPUT_WIDTH(INPUT_WIDTH), .OUTPUT_WIDTH(OUTPUT_WIDTH)) dut
(
	.clk(clk),
	.rst_n(rst_n),
	.in_valid(in_valid),
	.bin_in(bin_in),
	.bcd_out(bcd_out),
	.out_valid(out_valid)
);

//=====================================================================================
// Clock signal generation
//=====================================================================================
initial begin
	clk = 0;
	forever clk = #(CLK_PERIOD/2) ~clk;
end

//=====================================================================================
// Reference Model
//=====================================================================================
function automatic [OUTPUT_WIDTH - 1:0] to_bcd_expected (logic [INPUT_WIDTH - 1:0] bin);
	logic [OUTPUT_WIDTH - 1:0] bcd_val;
	int temp;
	
	temp = bin;
	bcd_val = 0;
	
	for (int i = 0; i < OUTPUT_WIDTH / 4; i++) begin
		bcd_val[i * 4 +: 4] = temp % 10;
		temp = temp / 10;
	end
	return bcd_val;
endfunction

//=====================================================================================
// Setting Stimulus an Check
//=====================================================================================
task automatic drive_conversion (input logic [INPUT_WIDTH - 1:0] test_value);
	logic [OUTPUT_WIDTH - 1:0] expected_bcd;
	
	expected_bcd = to_bcd_expected(test_value);
	
	@(posedge clk);
	bin_in <= test_value;
	bin_in_pipe <= test_value;
	in_valid <= 1'b1;
	in_valid_pipe <= 1'b1;
	
	@(posedge clk);
	in_valid <= 1'b0;
	in_valid_pipe <= 1'b0;
	
	// Waiting for the out_valid flag with anti-hang protection (Watchdog)
	fork
		begin
			@(posedge out_valid);
		end
		begin
			repeat (INPUT_WIDTH * 4) @(posedge clk);
			$error("[TIMEOUT] Watchdog error.");
			$stop;
		end
	join_any
	disable fork; // Watchdog disable if out_valid
	
	assert (bcd_out == expected_bcd)
	else begin
		$error("[FAIL] FSM: Expected: %0h, Got: %0h", expected_bcd, bcd_out);
		error_count++;
	end
	
	assert (bcd_out_pipe == expected_bcd)
	else begin
		$error("[FAIL] Pipelined: Expected: %0h, Got: %0h", expected_bcd, bcd_out_pipe);
		error_count_pipe++;
	end
	
	repeat (2) begin
		@(posedge clk);
	end
endtask

//=====================================================================================
// Main initial block
//=====================================================================================
initial begin
	$display("\n\nSTARTING TESTBENCH FOR bin_to_bcd (INPUT_WIDTH = %0d, OUTPUT_WIDTH = %0d)", INPUT_WIDTH, OUTPUT_WIDTH);
	
	// in_validing value of signals	
	rst_n = 1'b0;
	in_valid = 1'b0;
	in_valid_pipe = 1'b0;
	bin_in = '0;
	bin_in_pipe = '0;
	
	repeat (RESET_CYCLES) begin
		@(posedge clk);
	end
	rst_n = 1'b1;
	@(posedge clk);
	
	drive_conversion('0); // Min value
	drive_conversion((2 ** INPUT_WIDTH) - 1); // Max value
	
	// Random Tests
	repeat (RAND_CYCLES) begin
		drive_conversion($urandom());
	end
	
	if (error_count == 0 && error_count_pipe == 0) begin
		$display("[PASS] BIN TO BCD CONVERTER MODULE TESTS PASSED!");
	end
	else begin
		$display("[FAIL] TESTS FAILED! FSM Module: %0d errors detected! Pipelined Module: %0d errors detected!", error_count, error_count_pipe);
	end
	$stop;
end

endmodule