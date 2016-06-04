`define bmp_data_file "./bmp_dat.txt"
`timescale 1ns/1ns

module DMAtest( clk,
                rst,
					 we,
					 ack_out,
					 done,
					 readstart,
                mem_adr_i,
                mem_dat_o,
					 mem_dat_i
					 );
input clk;
input rst;
input readstart;
input we;
input done;
input ack_out;
input [21:0] mem_adr_i;
input [31:0] mem_dat_i;
output reg [31:0] mem_dat_o;

reg [7:0] mem['h4b000-1:'h0];     //define memory address as 0H-F0000H
reg [7:0] Dmem['h4b000-1:'h0];

initial
  $readmemh(`bmp_data_file,mem);//read original image data from text file into memory
integer DATAFILE;
initial
DATAFILE =$fopen("post_process_dat.txt");//sobel‘ÀÀ„Ω·π˚

always @ (posedge ack_out or posedge rst) begin
	if (rst)
		mem_dat_o = 32'd0;
	else begin
	 while (!readstart) @(posedge clk);
		if(!we)
			mem_dat_o ={mem[mem_adr_i],mem[mem_adr_i+1],mem[mem_adr_i+2],mem[mem_adr_i+3]};
		else if (we) begin
			while (!done) @(posedge clk);
			{Dmem[mem_adr_i],Dmem[mem_adr_i+1],Dmem[mem_adr_i+2],Dmem[mem_adr_i+3]}=mem_dat_i;
//			if(ack_out) begin
			$fdisplay(DATAFILE, "%0h", Dmem[mem_adr_i]);
         $fdisplay(DATAFILE, "%0h", Dmem[mem_adr_i+1]);
         $fdisplay(DATAFILE, "%0h", Dmem[mem_adr_i+2]);
         $fdisplay(DATAFILE, "%0h", Dmem[mem_adr_i+3]);
//			end
		end
	end
end

endmodule