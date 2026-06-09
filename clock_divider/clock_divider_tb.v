`timescale 1 ns / 1 ps
 
 module clock_divider_tb ();							//testbench module name
 
 		
		reg				tb_clk = 0;			//input of the tested module
		reg				tb_rst_btn = 0;			//input of the tested module
		wire				tb_div_clk;			//this is the output of the tested module
		reg				tb_div_rst;
	
		localparam	DURATION = 5000;				//simulation will last for DURATION*timescale	
		
		always begin							//if this is set, say to 12 MHz clk, we should switch clock every 41.6 ns. For 50 MHz one step should last for 20 ns.
			#10							//a clk has to happen twice to lead to a full cycle, so the wait time is half the necessary cycle time
			tb_clk = ~tb_clk;				
		end
		
		
		initial begin							//initial reset for the clock divider module
			#10
			tb_rst_btn = 1;
			#1
			tb_rst_btn = 0;
		end


    		initial begin							//we use the DURATION parameter to stop the simulation
           
        		// Wait for given amount of time for simulation to complete
       			 #(DURATION)
        
        		$stop;
   	 	end

		always @ (negedge tb_clk) begin					

			tb_div_rst <= tb_div_clk;

		end

		clock_divider							//import the tested module
			#(50) 							//overwrite the MODULO parameter
			clock_divider_test
			(.clk(tb_clk),						//with the wires and registers defined/driven by the testbench
			.rst(tb_div_rst),
			.tick(tb_div_clk)
			);

endmodule
		