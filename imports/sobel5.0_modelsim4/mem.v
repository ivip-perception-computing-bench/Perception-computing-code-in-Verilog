`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:01:19 03/26/2016 
// Design Name: 
// Module Name:    mem 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 片上存储，采用Xilinx Block memory 生成
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module mem(
	clk_i,
              
	mem_cyc_i,
	mem_stb_i,
	mem_we_i,       //1为向模块写，0为读
	mem_ack_o,   
              
	mem_adr_i,    //地址输入
	mem_dat_i,   //数据输入
	mem_dat_o,   //数据输出
              
	readorg   //信号有效时，memory与上层模块通信
    );
	 
input  clk_i;
input  readorg;
input  mem_cyc_i;
input  mem_stb_i;
input  mem_we_i;
output reg mem_ack_o = 1'b0;

input[21:0]   mem_adr_i;
input[31:0]   mem_dat_i ;
output[31:0]    mem_dat_o;               
wire            mem_stb_i;
reg [31:0] mem_dat_o=0;

reg mem_en_1;  //block memory的使能信号
reg D_mem_en_1;

wire [31:0] dat_out_mem_1;   
wire [31:0] dat_out_D_mem_1;

blk_mem_gen_0 mem_1 (
  .clka(clk_i),    // input wire clka
  .ena(mem_en_1),      // input wire ena
  .wea(mem_we_i),      // input wire [0 : 0] wea
  .addra(mem_adr_i[21:2]),  // input wire [17 : 0] addra
  .dina(mem_dat_i),    // input wire [31 : 0] dina
  .douta(dat_out_mem_1)  // output wire [31 : 0] douta
);
blk_mem_gen_0 D_mem_1 (
  .clka(clk_i),    // input wire clka
  .ena(D_mem_en_1),      // input wire ena
  .wea(mem_we_i),      // input wire [0 : 0] wea
  .addra(mem_adr_i[21:2]),  // input wire [17 : 0] addra
  .dina(mem_dat_i),    // input wire [31 : 0] dina
  .douta(dat_out_D_mem_1)  // output wire [31 : 0] douta
);

always @(posedge clk_i) begin
    if(mem_cyc_i && mem_stb_i) begin
        if (!mem_we_i) begin    //读memory 
            if (readorg) begin     //上层模块从sobel的memory中读
                    mem_en_1 <= 0;
                    D_mem_en_1 <=1;		     
				    mem_dat_o <= dat_out_D_mem_1;
				    mem_ack_o = 1'b1;
			end        
			else begin       //comp从memory中读	
                    mem_en_1 <= 1;
                    D_mem_en_1 <=0;	     
                    mem_dat_o <= dat_out_mem_1;
                    mem_ack_o = 1'b1;
			end
		end  

		else if(mem_we_i) begin   //写memory   
            if (readorg) begin    //上层模块将图片信息写到sobel的memory中
                    mem_en_1 <= 1;
                    D_mem_en_1 <=0;              
                    mem_ack_o = 1'b1; 
			end      
			else begin      //comp模块将结果写到memory中
                    mem_en_1 <= 0;
                    D_mem_en_1 <=1;                
                    mem_ack_o = 1'b1;
		    end
	    end
	    else begin
		   mem_ack_o = 1'b0;
		end
    end
    else begin
         mem_ack_o = 1'b0;
    end
end
endmodule
