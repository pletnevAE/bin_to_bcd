//=====================================================================================
//			BCD to 7-segment Converter Module
//
//			Control Signals:
//				clk - clock signal
//				rst_n – reset (Active-Low)
//
//			Data:
//				bcd - input (BCD) data
//				seg - output (7-segment) data			
//=====================================================================================

module bcd_to_7seg
(
	input clk, // Clock
	input rst_n, // Reset
	input [3:0] bcd, // Input BCD
	output reg [6:0] seg // Output 7-segment
);

//=====================================================================================
// 7-segment Table for DE10-Lite
//=====================================================================================
always @ (posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		seg <= 7'b1111111;
	end
	else begin
		case (bcd)
			0 : seg <= 7'b1000000;
			1 : seg <= 7'b1111001;
			2 : seg <= 7'b0100100;
			3 : seg <= 7'b0110000;
			4 : seg <= 7'b0011001;
			5 : seg <= 7'b0010010;
			6 : seg <= 7'b0000010;
			7 : seg <= 7'b1111000;
			8 : seg <= 7'b0000000;
			9 : seg <= 7'b0010000;
			default : seg <= 7'b1111111;
		endcase
	end
end

endmodule