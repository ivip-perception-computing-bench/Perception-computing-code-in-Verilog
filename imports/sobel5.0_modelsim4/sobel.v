`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:  Xy Chen
// 
// Create Date:    14:46:02 03/26/2016 
// Design Name: 
// Module Name:    sobel 
// Project Name:  
// Target Devices:  zynq_7000    
// Tool versions:   vivado 2014.4
// Description: Sobel operator；接口：wishbone
//处理图片格式：8位bmp，640*480
//图片由上层模块写入片上存储，处理完后在由上层模块将结果读出
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
`define width 640 //原始图片宽度
`define height 480 //原始图片高度
module sobel(
	clk_i,
	rst_i,
	
	cyc_i,
	stb_i,
	
	start,   //状态机开始信号
	we,   
	
	adr_in,  //上层模块读写sobel时的地址输入
	dat_in,   //上层模块向sobel写数据时的数据输入
	dat_out,      //上层模块读sobel结果时的地址输出
	ack_out,    //与上级模块的ack

	done     //当图片完全处理完时，此信号有效，上层模块开始读sobel结果
    );
	 
input  clk_i;
input  rst_i;

input cyc_i;
input stb_i;

input  start;   //状态机开始信号，状态从idle跳到下一个状态
input	 we;

input [21:0] adr_in;
input [31:0] dat_in;    //sobel模块与外部模块通信的数据接口
output  [31:0] dat_out;   //sobel模块与外部模块通信的数据接口

output reg ack_out;
output  done;   //图片被完全处理完时，此信号有效

wire  readstart;   //上层模块向sobel的memory写照片数据时有效

wire   start;     //状态机开始信号，状态从idle跳到下一个状态
wire   cyc_o;     //状态机给memory的cyc信号
wire   stb_o;     //assign stb_o=cyc_o
wire   we_o;		//状态机给memory的we信号，0为读，1为写

wire   done_set;    //最后一个状态结束后信号有效，下一个状态为idle
wire   shift_en;    //状态机给comp模块的信号
wire   prev_row_load;   //信号有效，则表示正在读的是第1行的数据
wire   curr_row_load;	//信号有效，则表示正在读的是第2行的数据
wire   next_row_load;	//信号有效，则表示正在读的是第3行的数据
wire   O_offset_cnt_en;   //状态机给addr_gen的地址计数使能
wire   D_offset_cnt_en;		//状态机给addr_gen的地址计数使能
wire   offset_reset;     //状态机给addr_gen的地址计数重置信号，idle状态时此信号有效，地址重新计数
wire[31:0]   result_row;   //comp模块的计算结果，输出给memory
wire[31:0]   dat_i;    //memory输出给comp模块的数据
wire[21:0]   adr_o;    //addr_gen输出给memory的地址
wire mem_ack_out;

wire done;   //图片被完全处理完时，此信号有效

assign readstart = cyc_i;

//--------------------切换memory模块的输入输出--------------------------
reg mem_we;
reg mem_cyc;
reg mem_stb;
reg [21:0] mem_adr_i;
wire [21:0] adr_out;
reg [31:0] mem_dat_in;

always @* begin  
	if(cyc_i) begin     //上层模块将照片写入sobel模块
		mem_cyc = cyc_i;
		mem_stb = stb_i;
		mem_we = we;
		mem_adr_i = adr_in;
		mem_dat_in = dat_in;
		ack_out = mem_ack_out;
	end
	else begin            //照片写入memory后，sobel模块开始运行，此时memory与comp与状态机相连
		mem_cyc = cyc_o;
		mem_stb = stb_o;
		mem_we = we_o;
		mem_adr_i = adr_o;
		mem_dat_in = result_row;
		ack_out = 0;
	end
end
//----------------------------------------------------------------------------

assign dat_out[31:0] = dat_i; // sobel模块的输出，整个图片处理完以后有效
assign   ack_i = mem_ack_out;  //memory与状态机的ack信号

compute compute(
	.rst_i(rst_i),     
	.clk_i(clk_i),
//从memory读出的32位数据                
	.dat_i(dat_i),     
//状态机控制信号
	.shift_en(shift_en),    
	.prev_row_load(prev_row_load),
	.curr_row_load(curr_row_load),
	.next_row_load(next_row_load),
//运算结果      
	.result_row(result_row)
);
  
mem  mem(
	.clk_i(clk_i),
              
	.mem_cyc_i(mem_cyc),
	.mem_stb_i(mem_stb),
	.mem_we_i(mem_we),       //1为向模块写，0为读
	.mem_ack_o(mem_ack_out),   
              
	.mem_adr_i(mem_adr_i),    
	.mem_dat_i(mem_dat_in),
	.mem_dat_o(dat_i),
              
	.readorg(readstart)
);
				  
addr_gen addr_gen(
	.clk_i(clk_i),
                
	.O_offset_cnt_en(O_offset_cnt_en),
	.D_offset_cnt_en(D_offset_cnt_en),
	.offset_reset(offset_reset),

//输出某一行地址的使能信号               
	.prev_row_load(prev_row_load),        
	.curr_row_load(curr_row_load),
	.next_row_load(next_row_load),
                
	.adr_o(adr_o)
);
                  
machine machine(
	.clk_i(clk_i),
	.rst_i(rst_i),
	.ack_i(ack_i),
               
	.start(start),
	.offset_reset(offset_reset),      //地址计数重置
               
//地址计数使能              
	.O_offset_cnt_en(O_offset_cnt_en),     
	.D_offset_cnt_en(D_offset_cnt_en),
               
	.prev_row_load(prev_row_load),
	.curr_row_load(curr_row_load),
	.next_row_load(next_row_load),
               
	.shift_en(shift_en),
	.cyc_o(cyc_o),
	.we_o(we_o),
	.stb_o(stb_o),
               
	.done_set(done)
);

					
endmodule
