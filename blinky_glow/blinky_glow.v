module blinky_glow
#(
	parameter 										LED_COUNT = 8,					//How many LEDs do we wish to use (we will have to do pin assignement to all of them!)
	parameter		[(LED_COUNT - 1):0]		LED_MASK = 8'b10101010,		//Will define which LEDs to use when we AND gate this parameter into the output wire (see below)
																							//it will be technically an output mask on the LEDs
	parameter										CLK_DIV_MODULO = 500000		//we overwrite the MODULO to 500000 to have a divider at 10 ms from 50 MHz																				
)
(
	input 	hw_clk,
	output 	wire	[(LED_COUNT - 1):0]		LED_out								//output
);


//we set the clock divider
wire div_clk;
reg div_rst = 0;

//clock divider reset flag
	always @ (negedge hw_clk) begin												//its negedge to be sure that we have a full clock cycle after the reception of the divided clock

		div_rst <= div_clk;															//clock divider reset flag

	end

	//we import the clock divider from the previous verilog example
	clock_divider #(CLK_DIV_MODULO) div_1 (												
			.clk(hw_clk),
			.rst(div_rst),																
			.tick(div_clk)
	);

//we do the same count direction as we did in the clock divider
localparam 		COUNTING_DOWN = 1'b0;												//Counter state machine parameters
localparam 		COUNTING_UP = 1'b1;
reg					state;

reg 				[5:0]									PWM_counter;					//PWM counter register (will be up until 32)
reg 				[(5 + 1):0]							PWM_signal;						//this will be the actual PWM signal
																								//note that the PWM_signal register is 1 bit wider than the PWM_counter register

	initial begin
		PWM_counter = 6'b0;																//Give initial value to the counter to start from.	
		PWM_signal = 7'b0;																//give initial value to the output
	end
		
	//we check the PWM count direction
	always @ (posedge hw_clk) begin													//Up-down counter state machine
		case (state)
			COUNTING_UP: begin
				if (PWM_counter == 6'b111111) begin									//This line is currently hard wired to the maximum value of a 6 bit register.
					state <= COUNTING_DOWN;
				end
			end
			COUNTING_DOWN: begin
				if (PWM_counter == 0) begin
					state <= COUNTING_UP;
				end
			end
			default: state <= COUNTING_UP;
		endcase
	end																		
																			
	//we change the PWM counter with the clock divider clock 																		
	always @(posedge div_clk) begin
		if(state == COUNTING_UP) begin
			PWM_counter <= PWM_counter + 1;
		end else if (state == COUNTING_DOWN) begin
			PWM_counter <= PWM_counter - 1;
		end else
			PWM_counter <= PWM_counter;
	end

	//we define the sigma-delta modulator signal MSB by using overflow
	always @(posedge hw_clk) PWM_signal <= PWM_signal[5:0] + PWM_counter;	//We add the PWM_counter value to the previous PWM_signal register.
																													//we thus step the PWM_signal register by the PWM_counter using the hw_clk
																													//mind, the PWM_counter value itself will change only with div_clk
/*	
//looping assign																								
//we apply the LED mask
reg					[3:0]								i;													//we define a varible that can run between 0 and 7
reg					[(LED_COUNT - 1):0]			Masked_output_signal;						//this will be fed into the output wire

	always @(posedge hw_clk) begin
		
		if (i < LED_COUNT) begin																			//we step our i variable 
			i = i + 1;
		end else begin
			i = 0;
		end
		
		Masked_output_signal[i] = PWM_signal[(5 + 1)] & LED_MASK[i];							//we apply the mask to generate the output signal
																													//note that we use the extra bit of the PWM_signal as the source of the PWM
																													//the LED will light up every time the PWN_signal MSB is HIGH
																													//how much time the MSB is HIGH will depend on the PWM_counter
		
	end

//we assign the output
assign LED_out = Masked_output_signal;*/

//direct assign
//we assign the otuputs to the LEDs and the masking
assign LED_out[0] = PWM_signal[(5 + 1)] & LED_MASK[0];
assign LED_out[1] = PWM_signal[(5 + 1)] & LED_MASK[1];
assign LED_out[2] = PWM_signal[(5 + 1)] & LED_MASK[2];
assign LED_out[3] = PWM_signal[(5 + 1)] & LED_MASK[3];
assign LED_out[4] = PWM_signal[(5 + 1)] & LED_MASK[4];
assign LED_out[5] = PWM_signal[(5 + 1)] & LED_MASK[5];
assign LED_out[6] = PWM_signal[(5 + 1)] & LED_MASK[6];
assign LED_out[7] = PWM_signal[(5 + 1)] & LED_MASK[7];


endmodule