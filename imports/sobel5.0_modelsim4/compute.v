`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:46:40 03/26/2016 
// Design Name: 
// Module Name:    compute 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: sobel计算模块，核心模块
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module compute(
	rst_i,     
	clk_i,
//从memory读出的32位数据                
	dat_i,     
//状态机控制信号
	shift_en,     //信号有效，则更新result_row
	prev_row_load,    //信号有效，则表示dat_i是第1行的数据
	curr_row_load,		//信号有效，则表示dat_i是第2行的数据
	next_row_load,		//信号有效，则表示dat_i是第3行的数据
//运算结果      
	result_row     //包含四个像素的结果
    );

input clk_i;
input rst_i;

input[31:0] dat_i;

input  shift_en;       
input  prev_row_load; 
input  curr_row_load;  
input  next_row_load; 

output[31:0] result_row; 

reg [31:0] prev_row=0, curr_row=0, next_row=0;
reg [7:0] O[-1:1][-1:1]; //用来存放待计算的9（3*3）个像素值

reg signed 	[10:0] Dx=0, Dy=0;

reg [7:0] abs_D = 0 ;  
reg [31:0] result_row =0 ; //储存计算结果，包含四个像素的计算结果
//-----------------------------------------------------------------------------
//当XXX_row_load有效的时候，将XXX行的四个像素值读入32bit寄存器

//当shift_en有效时，32bit寄存器左移1字节，移出去的部分进入3*3寄存器[7:0] O[-1:1][-1:1]
//同时3*3寄存器输出一个计算结果

always@(posedge clk_i)
	if(prev_row_load)	  
	   prev_row	<= dat_i;
	else 
	  if(shift_en)		
	    prev_row[31:8] <= prev_row[23:0];

always@(posedge clk_i)
	if(curr_row_load)	 
	   curr_row<= dat_i;
	else 
	  if(shift_en )   
	    curr_row [31:8]<=curr_row[23:0];

always@(posedge clk_i)
	if(next_row_load)	  
	   next_row<=dat_i;
	else
	  if(shift_en )	
	     next_row [31:8]<=next_row[23:0];
//------------------------------------------------------------------------------

//求绝对值
function [10:0]	abs ( input signed [10:0] x);
	abs = x >=0 ? x : -x ;
endfunction
//-------------------------------------------------------------------------------

always @(posedge clk_i) 
   if(rst_i)
      begin
            O[-1][-1]<=0;
	          O[-1][ 0]<=0;
	          O[-1][+1]<=0;
	          O[ 0][-1]<=0;
	          O[ 0][ 0]<=0;
	          O[ 0][+1]<=0;
	          O[+1][-1]<=0;
	          O[+1][ 0]<=0;
	          O[+1][+1]<=0;
	   end
	else
	if ( shift_en )	 
	begin
		abs_D <= (abs(Dx) + abs(Dy))>>3;
	
		Dx	<= -$signed({3'b000, O[-1][-1]})	        //-1* O[-1][-1]
				  +$signed({3'b000, O[-1][+1]})	        //+1* O[-1][+1]
				  -($signed({3'b000, O[ 0][-1]})<<1)    //-2* O[ 0][-1]
				  +($signed({3'b000, O[ 0][+1]})<<1)	   //+2* O[ 0][+1]
				  -$signed({3'b000, O[+1][-1]})	        //-1* O[+1][-1]
				  +$signed({3'b000, O[+1][+1]});	       //+1* O[+1][+1]
			
		Dy	<= $signed({3'b000, O[-1][-1]})	         //+1* O[-1][-1]
				  +($signed({3'b000, O[-1][ 0]})<<1)    //+2* O[-1][0]			     		
				  +$signed({3'b000, O[-1][+1]})	        //+1* O[-1][+1]
				  -$signed({3'b000, O[+1][-1]})         //-1* O[+1][-1]
				  -($signed({3'b000, O[+1][ 0]})<<1)    //-2* O[+1][ 0]
				  -$signed({3'b000, O[+1][+1]});	       //-1* O[+1][+1]
				
	  O[-1][-1]	<=	O[-1][0];
	  O[-1][ 0]	<=	O[-1][+1];
    O[-1][+1]	<=	prev_row[31:24];
    O[ 0][-1]	<=	O[0][0];
    O[ 0][ 0]	<=	O[0][+1];
    O[ 0][+1]	<=	curr_row[31:24];
    O[+1][-1]	<=	O[+1][0];
    O[+1][ 0]	<=	O[+1][+1];
    O[+1][+1]	<=	next_row[31:24];
  end
//----------------------------------------------------------------------------
//更新输出
always	@(posedge clk_i)
	if(shift_en)	
	   result_row	<= { result_row[23:0], abs_D};



endmodule
