`timescale 1 us / 10 ns  

module blinky_counter_tb();

wire [7:0] tb_out;

reg tb_clk = 0;
reg tb_rst = 0;


localparam DURATION = 10000;				//we run for 10000 us

//Generate clock signal. We don't have one in a test bench
always begin  //runs indefinitely, like the "while 1" loop
			
	#0.01	//this should trigger the clock every 10 ns, which will be 50 MHz on a 1 us timescale
	
	tb_clk = ~tb_clk; //toggle the clk line to mimick a clock

end

initial begin			//initial reset when we start it up
	#0.1		//delay 0.1 time units, which will be 100 ns
	tb_rst = 1'b0;
	#0.1
	tb_rst = 1'b1;
end

//which module to test
blinky_counter 
blinky_counter_test (
		.hw_clk(tb_clk),
		.rst_btn(tb_rst),
		.LED_out(tb_out)
);

initial begin		//this is to stop the simulation after 10000 cycles
	#(DURATION);	//this should make the simulation run for 10 seconds
	$stop;
	$finish;
end

endmodule