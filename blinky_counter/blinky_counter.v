module blinky_counter (hw_clk, rst_btn,LED_out);

		input 	wire 					hw_clk, rst_btn;						//hardware clk input (will be 50 MHz on the DE0 Nano) and reset button input
		output 	wire		[7:0] 	LED_out;									//output to the 8 LEDs on the board


reg 			[7:0] 		count;												//this is the register that will store the count values
reg 							count_direction;									//count direction flag for the state machine														
										
wire div_clk;																		//this will be our divided clock coming from the clock divider
wire inv_rst = ~rst_btn;														//we invert the reset button since the DE0 Nano buttons are active LOW

reg div_rst = 0;																	//clock divider reset flag register

//count direction flag value definition
localparam 					COUNTING_DOWN = 1'b0;
localparam 					COUNTING_UP = 1'b1;

//we set the count register as all "0"
initial begin
	count <= 8'b0;
end

//clok divider reset flag
always @ (negedge hw_clk) begin												//its negedge to be sure that we have a full clock cycle after the reception of the divided clock

	div_rst <= div_clk;															//clock divider reset flag

end

//we import the clock divider from the previous verilog example
clock_divider #(5000) div_1 (												//we overwrite the MODULO to 5000000 to have a divider at 100 ms from 50 MHz
																					//we overwrite the MODULO to 5000 to have a divider at 100 us from 50 MHz (recommended for tb)
		.clk(hw_clk),
		.rst(div_rst),																//we feed the tick signal back into the clock divider to reset it
		.tick(div_clk)
);

//we check if we are counting up or down		
always @ (posedge hw_clk) begin												//we run the count register control on the hw_clk
	case (count_direction)
		COUNTING_UP: begin
			if (count == 8'b11111111) begin
				count_direction <= COUNTING_DOWN;
			end
		end
		COUNTING_DOWN: begin
			if (count == 8'b0) begin
				count_direction <= COUNTING_UP;
			end
		end
		default: count_direction <= COUNTING_UP;
	endcase
end

//we change the count register value depending on count direction
always @ (posedge div_clk or posedge inv_rst) begin							//we run the acutal count on div_clk
	if (inv_rst == 1'b1) begin														   //we include the button reset
			count <= 8'b0;
		end	
	else begin
		if(count_direction == COUNTING_UP) begin
			count <= count + 1;
		end else if (count_direction == COUNTING_DOWN) begin
			count <= count - 1;
		end else
			count <= count;
	end
end

//we assign the count register to the LEDs
assign LED_out[7:0] = count[7:0];

endmodule