`timescale 1ns/1ps

module fifo_testbench;
	localparam DATA_DEPTH = 256;
	localparam DATA_WIDTH = 32;
	reg clock;
	//assign clock = 1'b0;
	reg reset;
	//assign reset = 1'b1;
	
	reg write_enable;
	reg [DATA_WIDTH-1:0] data_in;
	reg read_enable;
	wire [DATA_WIDTH-1:0] data_out;
	wire data_valid;
	wire empty;
	wire full;
	integer write_counter;
	integer read_counter;
	reg enable_read;
	reg empty_reg;
	
	localparam START_TEST 					= 4'b0001;
	localparam START_FULL_TEST 				= 4'b0010;
	localparam START_EMPTY_TEST 			= 4'b0100;
	localparam START_ALTERNATING_READ_TEST 	= 4'b1000;
	
	reg [3:0] test_state;

	generic_fifo #(DATA_DEPTH, DATA_WIDTH) dut (clock, reset, write_enable, data_in, read_enable, data_out, data_valid, empty, full);
	
	initial begin
		clock = 1'b0;
		reset = 1'b1;
	end

	initial begin
		#1000 reset = 1'b0;
	end
	
	always begin
		#5 clock = ~clock;
	end
	
	always @(posedge clock) begin
		empty_reg	<= empty;
	end

	always @(posedge clock or reset) begin
		if (reset == 1'b1) begin
			test_state		<= START_TEST;
			write_enable	<= 1'b0;
			data_in			<= 0;
			read_enable		<= 1'b0;
			write_counter	<= 0;
			read_counter	<= 0;
			enable_read		<= 1'b0;
		end
		else begin
			case (test_state)
				START_TEST:
				begin
					write_enable	<= 1'b0;
					data_in			<= 0;
					read_enable		<= 1'b0;
					write_counter	<= 0;
					read_counter	<= 0;
					test_state		<= START_FULL_TEST;					
				end
				START_FULL_TEST:
				begin
					if (full != 1'b1) begin
						write_enable	<= 1'b1;
						data_in			<= write_counter;
						write_counter	<= write_counter + 1;
					end
					else begin
						write_enable	<= 1'b0;
						data_in			<= 0;
						test_state		<= START_EMPTY_TEST;
					end
				end
				START_EMPTY_TEST:
				begin
					if (empty == 1'b0) begin
						read_enable		<= 1'b1;
					end
					else begin
					   read_enable		<= 1'b0;
					   enable_read		<= 1'b1;
					   test_state		<= START_ALTERNATING_READ_TEST;
					end
				end
				START_ALTERNATING_READ_TEST:
				begin
					if (full != 1'b1) begin
						write_enable	<= 1'b1;
						data_in			<= write_counter;
						write_counter	<= write_counter + 1;
					end
					else begin
						write_enable	<= 1'b0;
						data_in			<= 0;
					end
					
					enable_read		<= ~enable_read;
					
					if (empty == 1'b0) begin
						read_enable		<= enable_read;
					end
					else if ((empty) && (!empty_reg)) begin
						test_state		<= START_TEST;
					end
				end
				default: test_state		<= START_TEST;
			endcase
		end
	end
endmodule