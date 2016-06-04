`timescale 1ns/1ns

module testbench;
parameter t_c = 10;

reg clk;
reg rst;
reg pro_done=0;
wire done;
//wire start_ok;

initial begin
  $fsdbDumpfile("wave_test.fsdb");
  $fsdbDumpvars;
end

always begin //clk gen
		clk = 1'b1; #(t_c/2);
		clk = 1'b0; #(t_c/2);
	end

initial begin //reset gen
		rst  = 1'b1;
		#(2.5*t_c)	rst = 1'b0;
//		@(posedge pro_done);//wait process done
//		$stop;
	end


wire [31:0] dat_out;
wire ack_out;
reg cyc_i;
reg stb_i;

reg we;
wire [31:0] dat_i;
//reg [31:0] adr;

initial begin
  cyc_i = 1'b0;
  stb_i = 1'b0;
  we = 0;
//  adr = 32'd0;
end

reg [21:0] mem_adr_i;
reg [3:0] state;
reg teststart;
initial teststart = 0;
reg start;
//reg readstart;

initial begin
// readstart = 0;
  start = 0;
  #(4.5*t_c)	teststart = 1'b1;
  #(2*t_c)  teststart = 0;
end

always @(posedge done) begin
	pro_done<= 1;
end

sobel sobel_inf(
                  .rst_i(rst),
                  .clk_i(clk),
						
                  .cyc_i(cyc_i),
                  .stb_i(stb_i),
						
                  .adr_in(mem_adr_i),
                  .we(we),
                  .dat_in(dat_i),
 //                 .readstart(readstart),
                  .start(start),
                  .dat_out(dat_out),
                  .ack_out(ack_out),
//                .start_ok(start_ok),
                  .done(done));

always @ (posedge clk or posedge rst) begin
  if (rst) begin
    state <= 0;
    mem_adr_i <= 0;
    cyc_i <= 0;
	 stb_i <= 0;
  end
  else begin
    case(state)
      4'b0000: begin
        state <= 4'b0000;
        mem_adr_i <= 0;
        cyc_i <= 0;
        start <= 0;
		  we <= 1;
        if (teststart == 1)
          state <= 4'b0001;
      end
      
      4'b0001: begin
//        mem_adr_i <= mem_adr_i + 4;
        cyc_i <= 1;
		  stb_i <= 1;
        state <= 4'b0010;
      end
		
		4'b0010:begin
			if(ack_out) begin
				stb_i <= 0;
				state <= 4'b0011;
			end
			else 
				state <= 4'b0010;
		end
      
		4'b0011:begin
			mem_adr_i <= mem_adr_i+4;
			stb_i <= 1;
			if(mem_adr_i >= 22'h4b000) begin
				cyc_i <= 0;
				stb_i <= 0;
				state <= 4'b0100;
			end
			else 
				state <= 4'b0010;
		end	
	
      4'b0100: begin
        start <= 1;
        mem_adr_i <= 0;
		  if(pro_done) begin
		  start <= 0;
		  we <= 0;
        state <= 4'b0101;
		  end
		  else
		  state <= 4'b0100;
      end
		
		4'b0101:begin
			cyc_i <= 1;
		  stb_i <= 1;
		  state <= 4'b0110; 
		end
		
		4'b0110:begin
			if(ack_out) begin
				stb_i <= 0;
				state <= 4'b0111;
			end
			else 
				state <= 4'b0110;
		end
		
		4'b0111:begin
			mem_adr_i <= mem_adr_i+4;
			stb_i <= 1;
			if(mem_adr_i >= 22'h4ab00) begin
				$stop;
			end
			else 
				state <=4'b0110;
		end

    endcase
  end
end

DMAtest DMAtest1( .clk(clk),
                  .rst(rst),
						.we(!we),
						.ack_out(ack_out),
						.readstart(cyc_i),
						.done(pro_done),
                  .mem_adr_i(mem_adr_i),
                  .mem_dat_o(dat_i),
						.mem_dat_i(dat_out)
						);

endmodule




