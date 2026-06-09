`timescale 1 us / 10 ns
 
 module blinky_glow_tb ();							//testbench module name
 
 		
		reg					tb_clk = 0;					//input of the tested module
		localparam				tb_LED_number = 8;				//the FPGA code is hard-wired to tun on 8 LEDs, so don't change this
		wire					[(tb_LED_number - 1):0]		tb_LED_out;					//this is the output of the tested module
	
		localparam	DURATION = 5000;				//simulation will last for DURATION*timescale	
		
		always begin						
			#0.01											//generate the 50MHz clock
			tb_clk = ~tb_clk;				
		end
		
	
    	initial begin							//we use the DURATION parameter to stop the simulation
           
        		// Wait for given amount of time for simulation to complete
       			 #(DURATION)
        
        		$stop;
   	 end

		blinky_glow							//import the tested module
		#(tb_LED_number, 8'b10101010, 5000)
			blinky_glow_test
			(.hw_clk(tb_clk),						//with the wires and registers defined/driven by the testbench
			.LED_out(tb_LED_out)
			);

endmodule
		