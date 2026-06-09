# FPGA_Verilog_Basics
FPGA basics using a DE0Nano board (Altera Cyclone IV), Quartus Prime, Questa and Verilog.

Provided codes are related to basic clocking and the driving LEDs.

## General description
A blast from the past…

Build a scalable digital camera using an FPGA and an Adafruit Adalogger was the first serious hobby project I have concluded years ago and, as many first projects go, I never found the time to actually come back to it and do the documentation. That is despite it being the only practical FPGA project I can share that has an easy-to-understand use case.

Yes, yes, to be fair, the performance of that project was atrocious at best and had been significantly outclassed by some of my other projects (it was also a bit liberal on syntax quality, as we will be able to see later in the repo-chain), like, for instance, the STM32 Disco-based camera I have shared here. Yet, at the time, I was cooking from what I had available: the DE0 Nano and the Adalogger were literally the second and the third devboards I have ever bought from my own money after an Arduino UNO, so I was seriously limited on hardware.

Anyway, after exploring MPUs and Embedded Linux (second project coming a bit later), it seems like a natural next repo to make to be on FPGAs. Thus, I took the old project out, dusted it off, picked it apart into bite-size chunks and cleaned up the documentation enough so I could share it as a chain of repos. We will thus do a sequence of smaller projects about FPGAs, touching upon concepts and some simple – and later, not so simple – bits to keep us moving ahead.

Anyway, what are we talking about here?

### Why an FPGA?
To be clear right off the bat, if someone wants to do a specific task, getting an mcu is probably the way to go. They are a LOT easier to control and program up with tailored IDEs to help with coding and compilation, there is a dizzying amount of training and libraries around, they are very-very cheap and they come with all the peripherals we may need in our project.

On the contrary, should someone need more power to run an operating system, want parallel processing and practically turn every hardware issue into a software one, best to bring out the MPUs with multiple cores, get those cores wrangled into submission using embedded Linux or Zephyr.

With those two covered, what is left then?

Well, quite a bit. For starters, I don’t think that thinking about FPGAs as a “computing unit” is the correct approach whatsoever since that is not what they are supposed to be used for (though we can put a softcore processor into them, for instance). No, in my mind, an FPGA is a data bridge, an assembly line with dozens if not hundreds of conveyor belts moving data around, taking them in, processing them and churning them out. We can also have multiple entry and multiple exit ports – potentially hundreds - should we choose to, meaning that parallel sampling, parallel processing and parallel publishing is perfectly possible on a massive scale. This, matched with the fact that this software-based assembly line moves one step one clock tick at a time, obviously makes them ideal to process images.

Another use case is digital signal processing where dedicated FPGA logic will be significantly faster – and thus introduce less latency – than an mcu or an mpu would be. Pretty much all advanced communication systems use FPGAs, often in something called software defined radios.

FPGAs are also what run in GPUs and thus power all LLM and AI training, though I have little experience with these from a hardware point of view – for now - so I won’t be reflecting on them further.

Lastly, if it hasn’t been clear yet, another great benefit of FPGAs that they can interfaced with whatever we want. We don’t have designated peripherals in them, we have input ports and then we go about defining what those inputs ports are going to do using code. For all intents and purposes, we build the peripherals on both the inputs and the outputs the way we wish. This is an immensely useful capability to have, especially when the sensor we want to interface with does not have a standard peripheral to work with. This happens often with high-end optical sensors, for instance, where we may have an interface description to run the sensor from the sensor refman, just that this interface is not compatible with any existing COTS device (i.e., we have a custom interface and not MiPi or serial). In such case, we must build our own peripheral, receive data and then organise the data through the FPGA in a way that other units will be able to access it properly. At the last repo in this chain, we will build our own custom DCMI to receive data from a camera and then publish it to an mcu through SPI, for instance.

Anyway, FPGAs are very common and are used extensively in advanced electronics. Yet, surprisingly enough, they remain very much under the radar, very few people becoming experts in this niche technology. To be fair, likely reason for it is that we need a new syntax to use them AND be comfortable with a completely different way of thinking. More on this later.

#### Variations in hardware
There are multiple FPGA providers on the market, the most known ones being Xilinx (AMD), Altera (Intel) and the Lattice Semiconductor line of products. They are all common in being built up from basic “logic elements” (or LTEs) which are just a small look-up table, a D flip-flop/latch (a small memory element that “records” the value on the input of the element when a trigger/clock is detected) and a 2-to-1 mux to push the result to the LTEs output. While by itself a simple LTE is practically useless, we can do a lot of things with them if there are a lot of them organised in a particular fashion. FPGAs usually have thousands of them (in the DE0, we have 22320 LTEs, for instance) interconnected in ways that we can define their behaviour using the code we write.

While the difference between hardware may not seem grave, different FPGA producers may have different philosophies regarding internal RAM, for instance, so be aware of the resources you have available and how to reach them.

#### Variations in coding
There are two programming languages related to FPGAs: Verilog and VHDL.

I must admit, I don’t know VHDL yet and the project below will be in Verilog since the trainings I have found back in the day were for that particular hardware definition language, see the “to read” section below for details. Of note, Verilog is close to “C” in syntax, which immediately made it easier for me to follow, learn and understand. Yet, as a European, I probably should have gone with VHDL in retrospective since around these parts, it is a lot more common to come across that language compared to Verilog. (Of note, there is something called SystemVerilog which is a subset of Verilog that includes testing and verification processes. It is practically that same as Verilog just with test benches. We will mostly use this version of Verilog.)

Both languages are doing the same thing: describing hardware in something called register transfer level (RTL). Sometimes it is possible to have a simplified way to generate FPGA code too by using an “RTL viewer” that turns the code into a Simulink-style graph, or by using conversion programs to turn existing “Arduino”, “C” or “Python” code into FPGA code. I haven’t tested them, though with the advent of LLM based coding bots, probably there are easy ways to get some code generated quickly. The syntax really isn’t the difficult part when using FPGAs…

#### Variations in toolchains
To make things worse, we don’t just have variety in hardware and code syntax, we also have multiple software environments to generate code and then compile them to our devices.

Personally, I have found (Intel/Altera) Quartus prime to be the easiest software environment to use with ModelSim/Questa as the simulator. The reason for that is that the Lite version is free, the interface is somewhat intuitive, the simulator is streamlined into the IDE and there is a good amount of documentation to help us out, especially if we are using some of the official FPGA devboards from companies such as Terasic (my DE0 Nano is their low cost entry board, I can highly recommend it). We can also do pin assignment within a dropdown menu, do a simple timing analysis and generally make most of the necessary (i.e., basic) stuff without needing to pay for anything.

Mind, the Lattice toolchain with GTKwave as the simulator is also free and have more functions to offer compared to Quartus, though here the integration of the simulator into the IDE is dodgy, at best. We need to generate everything outside the IDE and then import them one-by-one to toolchain. We also have painfully little documentation to fall back upon. Lattice does not have a dedicated training board, though the ICE40 IceStick seems to do well for simple stuff (Shawn Hymel also uses it in his Digikey training).

Lastly, we have the Vivado suite which is the most advanced one of them all with the most amount of documentation to be had. Nevertheless, I have found it to be rather overwhelming and hiding waaaay too much stuff behind paywalls. Lately, as of 2026, they have also slammed a massive licence fee on some of their previously free functions, hamstringing many engineers in their work. This company philosophy just doesn’t seem to be very comforting to me personally who doesn’t want to spend money where it isn’t absolutely necessary. People seem to prefer Vivado and Xilinx compared to the Intel Altera one or the Lattice one for professional work though. Anyway, the most common devboard is the Basys 3 from Digilent, which is roughly the same price as the DE0 Nano.

All in all, I suggest using Quartus prime Lite 25.1.1 with Questa 25.1 since I know for a fact that it works fine. I have had issues with integrating the newer testbench in later versions of the toolchain, though this issue might be rectified in newer version. With the 25 version of both, the only messy thing is to set the licence variable in the OS you are running (System/Advanced system settings/Environmental Variables, add a new one called SALT_LICENCE_SERVER with a value that is the path of your licence file…plus set the path of the licence file within Quartus Tools/Licence setup) so Questa would run. The free licence “.dat” file can be requested from the Altera website.

#### Variations in project files
We will have multiple file types building up our FPGA projects. These can have different names, though their general purpose is the same:

- Main project file: this is going to be what holds the entire project together. In Quartus, this will be called “.qpf”.
- Verilog file(s): this is where the code is going to be (file extension will be “.v”). Of note, testbench control files are also going to be “.v” files, albeit a best practise is to name them as “_tb.v”. They will have to be manually imported into the testbench.
- Pin control/constraint file: this is where we will have the physical assignment for the pins. Should we encounter them, they are usually called “.pcf” files and they are NOT Verilog syntax (I think it is called Synopsys Design Constraint or SDC – for details, see “Design Constraints User Guide” from Microsemi). Within the Quartus, this is going to be integrated into the project file (generated using the IDE and then stored in the “.qsf” file), so we don’t need to make it ourselves separately.
- Output file: this is what the compilation of the FPGA project will lead to. In Quartus, it is called the “.sof” file and it is going to be the file we have to give the programmer built into Quartus to update the code on our FPGA. Mind, if we want our FPGA to keep the configuration after depowering (i.e. put the code into local FLASH and make the FPGA boot from it, more on that later), the “sof” will have to be converted to “.jic” file (this is done in a specific converter in Quartus). This new file is what needs to be used then during the programming of our device.

### Why make things so complicated?
This is a valid question.

I did this project back in the day partly because I wanted to learn FPGAs, partly because I wanted to deal with multi-megapixel camera sensors without the need to wrestle with Linux and MiPi (which interface wasn’t even available with the sensor I wanted to use anyway). I wanted flexibility regarding megapixel count even at the expense of speed and refresh rate. Also, I wanted to learn how certain communication buses (HDMI, SPI, I2C, Serial) and drive systems work on a profound level, not just implement pre-existing libraries.

As such, the decision was to go with FPGAs.

Below I want to share some very important concepts to grasp before we take a dive into coding though. As mentioned before, the trick of FPGAs really isn’t the syntax, it is the philosophy.

We need to forget all concepts that we have got used to in regular programming because while they have their own counterparts in FPGAs, they work in a very different way (for instance, all loops we are used to in “C” do different things in FPGA coding). Transferring directly will lead to issues, glitches and a whole bunch of hair being torn out of the scalp.

#### Basic concepts
When we program, we work in modules which run on “always” blocks. Always blocks are executed, well, “always” when a certain action is valid, i.e., when we have a trigger. We define the trigger in the “always” block definition. Execution  will be completely agnostic to the source of the trigger and we can’t put limits on it (instead, the trigger itself will have to be limited before it enters the block). Most often, we will see an execution on a change of state or edge, be that a falling edge (signal going from HIGH to LOW) or a rising edge (signal going from LOW to HIGH). The most common trigger is a clock signal, which will be just a square wave.

Initial blocks will execute at the power-up the device and give an initial value to registers. They can be considered as the “setup” phase of the FPGA. If we have multiple initial blocks, they will execute in parallel with each other.

Modules – just like functions in “C” – can be imported from other files. The toolchains are usually smart enough to recognise modules by name, thus dumping files in the same folder is usually enough to make it deal with them. Anyway, if we use the Quartus project wizard, it will directly ask for files to include, though this WILL NOT copy the files, just import them. As such, if we decide to tinker with the module, the modification will not be project-specific, it will change the imported file instead. We can call the same module multiple times (and make it execute in parallel, for instance), though we will have to give it a different name.

Defining constants work different in FPGAs compared to other devices. We can define general module parameters with “parameter” of a module, though these technically will be more like place holders than real parameters (think how we define functions in “C” and then call them by assigning a value to them). We do have to give them a base value though in the module which we can then overwrite when we call the module. Parameters are unique elements and thus they should not be defined in multiple different modules.

We can define local parameters – local constant small memory units – in each module with “localparam”. These cannot be modified externally and will always be removed once the module has executed. It is a best practice that all constants should be named with all capital letters.

“Wires” are one of the fundamental data type in FPGAs. They represent the physical connections between LTEs in the FPGA. As such, only wires can be passed between modules as outputs and behave more like information nets. Wires must thus be assigned to a certain value (which can be a constant HIGH or LOW value in case of a 1-bit wire), but never “given” one using an operator. This can be an input/output of a module, or an actual IO input/output. A wire does not store value, it only passes it (imagine connecting a literal wire between the modules, or an empty tube).  When calling a module, it will immediately define a wire between the higher-level data input and the module (i.e. module input/output definitions). A “wire” can be a vector or a matrix. It is recommended to indicate a wire in the code by putting “wire_” in the name of it.

Regarding variables, we have “registers” (“reg”) instead. These will be designated memory blocks that we “define” or “block” for our module to use as temporary data storage. A “reg” is a real memory element representing literal bits in the FPGA. It is something you don’t give value to but used as a temporal data holder in memory for your “always” blocks (or “initial” blocks). A “reg” can be given a value using operators, for instance, by sampling the value that is on a module input at the “always” block trigger, thus extracting data from the input and store it within the module. Once stored, a “reg” can be processed by a module. A “reg” can be a vector or a matrix. It is recommended to indicate a wire in the code by putting “reg_” in the name of it.

Registers can only be changed by one “always” block, otherwise their value becomes ambiguous. The trigger and driver system for the “always” block thus always have to be built in a way that it includes all triggers that are expected to change the value of a register.

All in all, modules are defined by the parameters (which can be overwritten when called a layer above) and inputs/outputs “ports”, which ports then must either be registers or wires, depending on if we want to feed data/publish data to a memory block (which can then be worked on by an “always” block, i.e., we have a register) or just have a combinational value and thus directly come from the output/go to the input of another module (we have a wire). Care should be given though that the designated wires and regs are the same width and depth or data will be lost when the transfer from one module to the other occurs. Similarly, one should always pay attention to give properly sized vectors to all inputs and outputs or data may be lost.

A pin constraint file assigns wires to physical pins which wires then we can interact with using our code.

If we don’t specify if an input/output should be a register or wire in syntax, it will automatically be assigned as a wire.

Lastly, it is very much recommended to start ANY FPGA code with a reset signal so as to properly define and configure the modules. Not doing so may lead the blocks executing on metastability or gibberish found in the registers (while an FPGA is volatile, it doesn’t mean it completely resets everything to GND when power is lost, far from it…). 

#### Blocking and non-blocking operators
Whatever is inside the “always” block though can be made to execute sequentially by using blocking operators. Blocking operations are assigned using the “=” operator. An example would be the simple module to give a constant value to an empty register and then display the register: first we give the value, then we print out.

The non-blocking operator is “<=” and will allow parallel execution – that is, all operations will happen the same time and not one after the other. Doing the same example from above, that is, giving a value to an empty register and display it would just show the register to be empty: displaying occurs the same time as the change in value of the register, meaning that the display action happens on an empty register. We would need to delay the display action until the register has been assigned its value (changing the value of a register may take multiple clock signals since we can always just change on bit at a time, which is where “Gray code” comes in, see in a later repo).

Generally, we should not use blocking operators in actual hardware code. The only exception to that are testbenches where we MUST use blocking operations all the time. More on that later.

We should also remember that bitwise operators and logical operators are not the same. Consult the cheat sheet in the “to read” section for the syntax.

#### Parallel execution, skew and setup/hold times
One of the most complicated concepts to wrestle with is that we are NOT executing code in a sequential fashion but in parallel. This means that whatever modification we are conducting, they will all occur at the same time. If you have used Simulink before, the whole spiel should sound familiar.

This parallel execution is clock-related though, and, physically speaking, both the signal and the clock will still have to progress through the FPGA, introducing delay or clock skew. We talk about negative skew when the clock arrives to a module (and thus make the module sample its inputs) before the change on said input has occurred. Positive skew is when the clock arrives to the module after the signal. Positive skew increases with the chain of modules we are using, potentially leading to a positive skew so great that it becomes a negative skew to the next clock tick, practically introducing an internal delay within the execution (not all code happens on the same clock cycle).

This is a very important concept for signal sampling (which we technically are doing all the time in an FPGA): it takes time for a signal to change on a hardware level (“setup time”) and it has to stay at the same value for a certain amount of time (“hold time”) to be considered a valid change. This means that if we end up sampling a value when it has not passed the setup+hold time combination, it can very much be that we will end up capturing an “in between” state of the value called “metastability”. (An example: we have a 3.3V internal logic system but the value we are flipping is sampled before the setup+hold time is passed, resulting in an actual signal voltage of 2.0V. Shall the FPGA consider this then as a HIGH state or a LOW state?).

The solution is to synchronize clocks when necessary or by introducing arbitrary delays and thus introduce a tolerance in skewing. Small shift registers (called synchronisers) are ideal to both mitigate metastability and to eliminate the effects of skew. They do make the entire code execute with a one clock cycle delay though.

#### Clocking and clock domain crossing
Clocking is probably the most complex bit of FPGA work. Glitches almost always come from timing violations, that is, the clocking not set as expected or modules processing the data flowing through them out of the intended sequence.

Anyway, we usually have an input signal from an external crystal that is giving a certain frequency to the device (on the DE0, this is a 50 MHz crystal on the R8 pin global clock pin), which signal we then assign as a wire on pin constraint. This physical input clock can then be processed further to get to a cadence we need our FPGA to execute its code at.

We won’t be going too deep into clocking here, that will be done in the following repo, we will just introduce a clock divider to clock SLOWER.  A clock divider would be a counter that only steps the desired system clock signal when a certain number of input oscillation cycles are reached and then give this desired system clock signal as output. This is how we reach, say, 1 Hz output from the 50 MHz we mentioned above, by counting the input clock edges 50.000 times in a module and then flip the state of the module output, generating a square wave.

Lastly, a practical note: it must be kept in mind that the speed at which we execute our code (the “always” block edge trigger we give) IS NOT the same as the speed at which the FPGA ticks over (the FPGA system clock). Do not be afraid to slow down the clock to a crawl and then observe step-by-step what your FPGA is doing. Also, every action – every physical change in values – takes at least one FPGA tick over to occur. It is perfectly possible that we will have so many things occurring in a module that it will not fit between two edge triggers.

Mind, we usually get an estimation of how fast we can maximum go with our design after compiling our code (check the details) where the toolchain will consider the clock skew, the module sizes and the different setup and hold times. Going faster than that estimation will lead to glitches.

#### Project structing
Something to remember regarding project organisation is that we import Verilog files into one another within code. Unlike in “C” though this importing happens through calling modules by their local names, like classes would be defined. Eventually, the “.v” files – and our entire code - are thus organised in a tree-like hierarchy.

The top module name should be the same as the project name to help constructing the project properly (the toolchain should be able to figure out the hierarchy by itself anyway though experience suggests naming helps).
The important philosophy regarding this tree-like structure is that any signal will have to physically travel “down” this tree and then “up” the tree with the results to exit the output (input and output definition is on the highest level). This “travel” from one section of the FPGA to the other will introduce skew (see above) which will become an issue if complexity becomes extensive. Best practice is to make the project structure as simple as possible and to clock our design comfortably below the clocking limit mentioned above.

#### Volatility
A concept that may come as strange is that FPGAs are inherently volatile devices, meaning that they lose their configuration upon power loss. To get around this issue, the actual configuration machine code for the FPGA is stored in an external flash memory which is then read in by the device every time power is applied using SPI (i.e., it “boots” from a local flash chip). This memory is what ensures that the FPGA will behave the same way after power is applied again.

Unless specifically set up as such, we will be directly sending the configuration data from the IDE to the device though, meaning that the configuration is wiped upon the loss of power. In order to avoid the update of the FPGA from the connected PC and load the values in the local non-volatile memory, we need to specifically set the programmer in the IDE as such: in Quartus, this is done when we upload the code to the board and select “jic” instead of “sof”.

Lastly, it is possible to “perma-lock” the configuration of the FPGA by writing to a designated SRAM memory section inside the FPGA.

ATTENTION!!!

Always check that you are updating with the right code type to the right boot option. If memory serves, all toolchains will warn you multiple times when you are about to hard-bake the configuration into the internal FPGA SRAM , but if you miss these warnings, you will effectively turn your very flexible FPGA into a very non-flexible electronics device.

#### Input levels
FPGAs are extremely sensitive to input quality since, if the voltage levels are not met properly (say, we apply 1.7 V on a nominal CMOS 2.5V input), the device will not be able to tell if the input is HIGH or LOW (see metastability). All physical pins in the FPGA are connected to an IO driver cell and the drive voltage of those cells will define the HIGH state on that particular pin (CMOS or TTL or LVDS). We often can select these drive voltages individually for each pin expect for LVDS, which comes in differential pairs and thus are always two pins. The LOW state for all setups will be the same: GND.

Mind, the IO drive voltage IS NOT the same as the FPGA core voltage though. The only exception to this rule are the dedicated pins: power and clocking.

#### Testbenches, simulators
Testbenches are simulators that will simulate to you in a simple manner, what your FPGA code will execute as. This usually will be a simplified interface – a waveform - where you can visually check the generated states of the outputs in reference to the inputs given to the code. Mind, simulations are not taking into consideration hardware limits, nor do they have a pin distribution, so they literally are only there to see, what a specific output will be when the code receives a specific input. They will not be able to perfectly estimate your outputs on real hardware. At any rate, they are perfect to just show that the code that has been written “should” work.

Testbench files are Verilog files just like the code we write to the device (as best practice, name them as “PROJECTNAME_tb.v”) but must be imported into the simulator we are using manually (at least, that’s how it is in Quartus – Assignment/Settings/EDA Tools/Simulation/Compile test bench). Simulators usually run automatically on code compilation, given they are included in the project, of course. The code for the simulator will not be synthesized.

Mind, test bench files are put on top of our device code, literally there to simulate an input and then capture the output from the device code. We will have to simulate a clock in the “_tb.v” code, as well as the duration of the test bench execution (given as a “localparam”). The duration should always be longer than the simulated clock, otherwise we won’t see anything. A too long duration though could make the testbench difficult to decipher. It is recommended to play around with these values to reach the most convenient outcome. It is also very common to not see anything in the simulation simply because we haven’t selected the right timescale/duration/clk signal combination.

The timescale is defined by the “’timescale” command at the start of the testbench file (if memory serves, the timescale definition is what tells the IDE that the executed Verilog code is a testbench, though I am not sure on that). The scale will be defined by giving a unit size – the time step – and the precision itself.

A testbench will be considered as a separate module after the “’timescale” definition.

Testbenches often run loops (forever/always, while, for or repeat) and functions that do not exist in the hardware code itself. Testbench codes thus work like what we are used to in “C” and can deal with loops as we expect (unlike synthesizable FPGA code).

“Always begin” is the way to generate clocking in the testbench, for instance, a line that would throw an error in real hardware.

Mind, if we want to exactly simulate what happens within the FPGA because during a certain time frame or we want to see an estimated “exact” timing, the timescale, the delays and the DURATION must all align (for example if we want to have a 50 MHz clk signal fed into our module by the simulator, the clk signal has to switch every 10 ns for a 20 ns long period).

Always include the DURATION parameter within an initial block to stop the simulation otherwise the simulator might break (it will run indefinitely).

Just a note: I noticed a glitch where the waveform is not loaded into the simulator at the end of the simulation. If this happens, just click on one of the simulator items to open the “_tb.v” file in the simulator. This will reset the simulator screen and re-import the waveform.

## To read
I used the Shawn Hymel training a lot, albeit, using a different environment:
https://www.youtube.com/playlist?list=PLEBQazB0HUyT1WmMONxRZn9NmQ_9CIKhb

I also suggest checking any of the Ben Heck element 14 videos on youtube about FPGAs, he explains them very well.

I also recommend giving the Nandland site a look, it has interesting projects and a waaaaay more detailed take on FPGAs compared to myself:
[Nandland – Learn FPGA, VHDL & Verilog](https://nandland.com/)

Some general knowledge on FPGAs can be extracted from here:
[EEVblog #496 - What Is An FPGA? - YouTube](https://www.youtube.com/watch?v=gUsHwi4M4xE&t=1s)

For the PWM and sigma-delta modulator:
https://www.fpga4fun.com/PWM_DAC.html

We have a Verilog syntax cheat sheet:
https://marceluda.github.io/rp_dummy/EEOF2018/Verilog_Cheat_Sheet.pdf

Lastly, I will be using the fpga4fun website a lot, practically running along it. I used it extensively when I was first learning FPGAs.

## Particularities
Let’s look at a few simple code elements to see some of the concepts above in action. I am providing testbenches for all of them and the “.sof” file to update the DE0 Nano.

Of note, both Quartus and the Questa are very clear and communicative on errors, just check the discussion windows (“messages” for Quartus, “transcript” for Questa) in both of them to see, where and what broke during the processing of the code.

### Clock divider
First of all, we need to start with the simplest thing and sort out the clocking.

Here we have a simple clock divider with two inputs (clk and a rst) and one output. The pins are not defined in the project since we will only use the simulator to see the dividing effect. The “MODULO” parameter will define, how we divide the clock. Mind, we set a counter to count up until the MODULO value and every time the count reaches this value (“MODULO – 1” is used since “0” counts as one already), we assign the output as HIGH (or 1’b1, which is 1 digit, binary, value “1”) for one cycle. If the count is not the same as the MODULO (minus 1…), the output is kept as “0”. (Of note, MODULO is a 32 bit value, so it can go quite high but not infinitely high.)

Mind, we don’t reset the counter register upon the divided clock generation here, which means that register will get incremented past the desired value until it turns over due to overflow, leading to an inaccurate clock output. We can get around this problem in by resetting the clock divider every time it generates a tick. Here, we will do this in the tb file by sampling the output of the divider into a register using the input clock – so the value of the divider will emerge in the register with a delay – and then feed it back into the clock divider as a reset signal. This will mean that the clock divider will be automatically reset  one input clock cycle after generating a tick.

In the tb file, we set the timescale as whatever we want it (here it does not matter), we set and initialise the input values (clk included with the necessary always loop, rst as a “manual” activation), give a DURATION and import the divider module.

The simulator then should run automatically, showing that the output of the divider will go HIGH fewer times than the original clk, the time depending on the module parameter MODULO we have provided.

### Blinky counter
Now that we have a clock, we can import this module into our next project and make a one-second blinky.

Checking the DE0 Nano datasheet, we know that the 8 LEDs of the board are placed on A15, A13, B13, A11, D1, F3, B1 and L3, the clock (the 50 MHz oscillator) is connected to R8 and one of the push buttons are on J15. In “Assignment/Pin planner”, we can set the LEDs as outputs, the clock and button as inputs and set the pin constraints as such. The I/O voltage standard can be kept as 2.5V all around, with 8 mA current strength and no pull resistors. The name of the pins will come from the wires we have defined as inputs/outputs for the highest-level module.

With that all sorted, we can import the clock divider module and then assign its wire output to the wire connected to our LED. We should give a MODULO values high enough to the divider that we will be able to follow the blinking.

The code itself will be then another counter on top of the divider which will then increase a register whenever the divided clock activates a trigger. The register will be assigned to the output wires for the LEDs. (Of note, assigning the divider’s counter to the LED outputs will lead to a very fast counter, that’s why we need a second one to make things visible.) If we just want a simple blinky, set up only the first LED and assign it the first bit of the counter register. Since the hardware input clk is 50 MHz, the divider will have to have a MODULO value of 5000000 to have a 0.1 second blinky (we can test this parameter change by running the testbench of the clock divider from above).

When we compile the code and upload it to the FPGA, we will see an 8-bit counter that goes up and then down with a speed of 100 ms.

I am also sharing the tb to simulate the counter. Please note that the tb timescale is 1 us and the duration is 1000 us. In order to see anything, the MODULO of the clock divider in the blinky code will have to be decreased from “5000000” to “5000”. This will change the divider’s output from a 100 ms clock to a 100 us one and allow us to simulate 10 steps of the counter. Alternatively, one could keep the clock divider as-is and increase the simulation time, though this will make it take a lot of time to finish.

Also, within the tb, we need to invert our reset signal since – to comply with the hardware – we do an inversion in the device code right now. This wasn’t the case in the clock divider since that was never loaded into the device. Just a reminder, this negation is only necessary because the buttons on the DE0 Nano are active LOW.

### Blinky with sigma-delta modulator
This will be the last project in this repo where we will make the LEDs turn on and off gradually using a simplified PWM.

Just to recap, PWM is short for  “pulsed width modulation” and what it does is change a clock signal into something that has a variable wave form: the produced signal will be HIGH for only a certain portion of the generated clock cycle and won’t stay 50% HIGH, 50% LOW square wave all the time (in electronics speak, we change the duty cycle of the clock signal from 50%). For example, our clock divider from before generates just a signal trick, meaning it will generate a divided clock signal that will be HIGH only for one hardware clock cycle.

If fed into a LED, a PWM signal will dim the LED’s brightness proportional to the HIGH/LOW ratio of the signal across time.

We thus need to change the HIGH/LOW ratio. Now, we could do this the simple way and just define a counter that will flip the output bit HIGH when its value is higher than a limit (i.e. a comparator) or we can do something more complex, like a sigma-delta modulator (a more complex version of a PWM with better frequency response and thus filtering options).

Here in code I have decided to implement the sigma-delta modulator: every time we overflow, we will give a HIGH, otherwise we will give a LOW. The greater the feed-in value, the faster the overflow will happen. We feed then this value into the output wires with a masking. Note that the assigning is done directly and not through a loop to decrease the chance of introducing glitches. (I left the looping solution between comments in code too to see the difference between direct assign and loop assign: while the output of the two versions will be the same on the FPGA, the testbench will glitch out due to the loop.) Mind, we have to keep the LED count at 8 when direct assigning otherwise the code will not execute due to wires being assigned that were not defined prior.

I have also removed the reset button since we don’t really need it here.

Lastly, I have modified the code in a way that now we can change the clock divider MODULO value directly from the tb, we don’t need to recompile the entire code.

## Conclusion
Above we have discussed some of the basic concepts of FPGAs, followed by a set of projects to show a blinky.

In the next repo, we will go deeper in clock domains.

