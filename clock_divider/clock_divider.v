module clock_divider
#(
		parameter MODULO = 4
)
(
		input 			clk,
		input 			rst,
		output			tick

);

localparam WIDTH = (MODULO == 1) ? 1 : $clog2(MODULO);				//we build the register that will hold our counter

reg [WIDTH-1:0] count = 0;														//we set the initial counter register value as 0

assign tick = (count == MODULO - 1) ? 1'b1 : 1'b0;						//if the count register holds a value that is the same as MODULO - 1, we change the tick to HIGH
																						//if not, it stays as LOW
																						//the tick will stay HIGH for one "clk" only

always @ (posedge clk or posedge rst) begin								//we increase the count register when a clock signal comes through
	if (rst == 1'b1) begin
		count <= 0;
	end else begin
		count <= count +1;
	end
end

endmodule