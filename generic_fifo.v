module generic_fifo (clock, reset, write_enable, data_in, read_enable, data_out, data_valid, empty, full);
	parameter data_depth = 256;
	parameter data_width = 16;

	input clock;
	input reset;
	input write_enable;
	input [data_width-1:0] data_in;
	input read_enable;
	output reg [data_width-1:0] data_out;
	output reg data_valid;
	output reg empty;
	output reg full;
	
	reg [data_width-1:0] data_array [data_depth-1:0];
	localparam COUNTER_MSB = $clog2(data_depth);
	reg [COUNTER_MSB:0] input_counter;							// Write pointer
	reg [COUNTER_MSB:0] output_pointer;							// Read pointer
	reg [COUNTER_MSB:0] current_size;
	
	integer i;
	
	always @(posedge reset or posedge clock)
	begin
		if (reset)
		begin
			for (i = 0; i < data_depth-1; i = i + 1) begin
				data_array[i]	<= 0;
			end
			
			input_counter	<= 0;
			output_pointer	<= 0;
			empty			<= 1'b1;
			full			<= 1'b0;
			current_size	<= 0;
		end
		else begin
			if ((write_enable == 1'b1) && (read_enable == 1'b0)) begin
				// First check to make sure FIFO is not already full
				if (current_size < data_depth) begin
					if (input_counter[COUNTER_MSB-1:0] < data_depth) begin
						input_counter	<= input_counter + 1;
						data_array[input_counter[COUNTER_MSB-1:0]]	<= data_in;
					end
					
					full	<= 1'b0;
				end
				else begin
					full	<= 1'b1;
				end
				
				data_valid	<= 1'b0;
			end
			else if ((write_enable == 1'b0) && (read_enable == 1'b1) && (input_counter != output_pointer)) begin
				data_out	<= data_array[output_pointer];
				data_valid	<= 1'b1;
			
				if (output_pointer < data_depth-1) begin
					output_pointer	<= output_pointer + 1;
				end
				else begin
					output_pointer				<= 0;
					input_counter[COUNTER_MSB]	<= 1'b0;	
				end

				full	<= 1'b0;
			end
			else if ((write_enable == 1'b1) && (read_enable == 1'b1)) begin
				if (current_size < data_depth) begin
					if (input_counter[COUNTER_MSB-1:0] < data_depth) begin
						input_counter	<= input_counter + 1;
						data_array[input_counter[COUNTER_MSB-1:0]]	<= data_in;
					end
					
					full	<= 1'b0;
				end
				else begin
					full	<= 1'b1;
				end
				
				if (input_counter != output_pointer) begin
					data_out	<= data_array[output_pointer];
					data_valid	<= 1'b1;

					if (output_pointer < data_depth-1) begin
						output_pointer	<= output_pointer + 1;
					end
					else begin
						output_pointer				<= 0;
						input_counter[COUNTER_MSB]	<= 1'b0;	
					end
				end
				else begin
					data_valid	<= 1'b0;
				end
			end
			else begin
				data_valid	<= 1'b0;
				
				if (current_size < data_depth) begin
					full	<= 1'b0;
				end
				else begin
					full	<= 1'b1;
				end
			end
			
			if (input_counter == output_pointer) begin
				empty	<= 1'b1;
			end
			else begin
				empty	<= 1'b0;
			end
			
			current_size	<= input_counter - output_pointer;
		end
	end
endmodule