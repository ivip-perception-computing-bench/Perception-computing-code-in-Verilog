`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:58:18 03/26/2016 
// Design Name: 
// Module Name:    addr_gen 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description:地址产生器，在计算时为mem产生读写的地址
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module addr_gen(
	clk_i,
//地址计数与重置                
	O_offset_cnt_en,     
	D_offset_cnt_en,
	offset_reset,

//表示正在传送的是prev、curr、next其中的一行               
	prev_row_load,        
	curr_row_load,
	next_row_load,
                
	adr_o
    );
	 
input clk_i;

input   O_offset_cnt_en;
input   D_offset_cnt_en;              
input   offset_reset ; 

input   prev_row_load;        
input   curr_row_load;      
input   next_row_load; 

output[21:0]  adr_o ;       

parameter WIDTH = 640;

        
reg[18:0]  O_offset;
reg[18:0]  D_offset;
wire[19:0]  O_prev_addr;
wire[19:0]  O_curr_addr;
wire[19:0]  O_next_addr;         
wire[19:0]  D_addr; 

/*******************************************************/
//初始化

always	@(posedge	clk_i)	
	if(offset_reset)		
		O_offset	<= 0;
	else	
	  if(O_offset_cnt_en)
	   O_offset	<= O_offset+1;
		
/*******************************************************/

assign	 O_prev_addr = O_offset;
assign	 O_curr_addr = O_prev_addr + WIDTH/4;
assign	 O_next_addr = O_prev_addr + 2*WIDTH/4;

/*******************************************************/

always	@(posedge	clk_i)	
	if(offset_reset)		
		D_offset	<= 0;
	else	
	  if(D_offset_cnt_en)	
	     D_offset	<= D_offset+1;
		 
/*******************************************************/

assign D_addr[19:0] = D_offset;
/*******************************************************/

assign	adr_o[21:2] =    prev_row_load ? O_prev_addr :
						 curr_row_load ? O_curr_addr :
						 next_row_load ? O_next_addr :
						 D_addr;
						 
assign adr_o[1:0]	=	2'b00;   //因为offset每次加一，而每次读出的数据为4个字节，所以输出时乘4，相当于地址每次加四

endmodule
