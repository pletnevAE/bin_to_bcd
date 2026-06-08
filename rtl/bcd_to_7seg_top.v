//=====================================================================================
//			BCD to 7-segment Converter Top Module
//
//			Parameters:
//				DIGITS - Number of 7-segment indicators
//
//			Control Signals:
//				clk - clock signal
//				rst_n – reset (Active-Low)
//
//			Data:
//				bcd_in - input (BCD) data
//				seg_out - output (7-segment) data			
//=====================================================================================

module bcd_to_7seg_top
#(
	parameter DIGITS = 3
)
(
	input clk, // Clock
	input rst_n, // Reset
	input [DIGITS * 4 - 1:0] bcd_in, // Input BCD
	output [DIGITS * 7 - 1:0] seg_out // Output 7-segment
);

//=====================================================================================
// BCD to 7-segment Converters Instantiation
//=====================================================================================
genvar i;
generate
	for (i = 0; i < DIGITS; i = i + 1) begin : gen_7seg
		bcd_to_7seg ints_digit
		(
			.clk(clk),
			.rst_n(rst_n),
			.bcd(bcd_in[i * 4 +: 4]),
			.seg(seg_out[i * 7 +: 7])
		);
	end
endgenerate

endmodule