`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:46:24 03/26/2016 
// Design Name: 
// Module Name:    machine 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: FSM
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module machine(
	clk_i,
	rst_i,
	ack_i,
               
	start,    //信号有效时，state从idle跳到read_prev_0
	offset_reset,      //地址计数重置
               
//地址计数使能              
	O_offset_cnt_en,     
	D_offset_cnt_en,
               
	prev_row_load,
	curr_row_load,
	next_row_load,
               
	shift_en,
	cyc_o,
	we_o,
	stb_o,
               
	done_set
    );

input  clk_i;
input  rst_i;
input  ack_i;

input wire start; //信号有效时，state从idle跳到read_prev_0

output reg offset_reset;  //给addr_gen，使地址计数器重置
output reg O_offset_cnt_en;  //给addr_gen，地址计数器+1
output reg D_offset_cnt_en;	//给addr_gen，地址计数器+1

output reg prev_row_load; //区分正在传输的数据是第几行
output reg curr_row_load;      
output reg next_row_load;    

output reg shift_en;   //信号有效，则更新result_row

output reg cyc_o;  //状态机给memory的cyc信号
output reg we_o;   //assign stb_o=cyc_o
output wire stb_o;  //状态机给memory的we信号，0为读，1为写

output reg done_set;   //最后一个状态结束后信号有效，下一个状态为idle

parameter WIDTH = 640;  
parameter HEIGHT = 480; 

parameter [4:0]	idle	=5'b00000,
						read_prev_0	=5'b00001,
						read_curr_0	=5'b00010,
						read_next_0	=5'b00011,
						comp1_0		=5'b00100,
						comp2_0		=5'b00101,
						comp3_0		=5'b00110,
						comp4_0		=5'b00111,
						read_prev		=5'b01000,
						read_curr		=5'b01001,
						read_next		=5'b01010,
						comp1			=5'b01011,
						comp2			=5'b01100,
						comp3			=5'b01101,
						comp4			=5'b01110,
						write_result	=5'b01111,
						write_158		=5'b10000,
						comp1_159		=5'b10001,
						comp2_159		=5'b10010,
						comp3_159		=5'b10011,
						comp4_159		=5'b10100,
						write_159		=5'b10101;
					
reg [4:0] current_state,next_state;
reg [10:0] row;     
reg [8:0] col;

reg  row_reset,col_reset;  //idle状态时用来重置row和col

reg row_cnt_en, col_cnt_en;   //row和col计数使能信号

always @(posedge clk_i)		//行计数
	if (row_reset)	
		 row <= 0;
	else 
	 if (row_cnt_en)	
	    row <= row + 1;

always @(posedge clk_i)		//列计数
	if (col_reset)		
	   col		<= 0;
	else 
	  if (col_cnt_en)	
	    col<= col+1;

//状态机fsm
always @(posedge clk_i)		
	if (rst_i)	
	   current_state<= idle;
	else	
	   current_state<= next_state;
	
always @* 
  begin	
	offset_reset		=1'b0;
  row_reset			=1'b0;
	col_reset			=1'b0;
	row_cnt_en		=1'b0; 
	col_cnt_en		=1'b0;
	O_offset_cnt_en	=1'b0; 
	D_offset_cnt_en	=1'b0;
	prev_row_load		=1'b0; 
	curr_row_load	=1'b0;
	next_row_load		=1'b0;
	shift_en			=1'b0; 
	cyc_o				=1'b0;
	we_o				=1'b0; 
	done_set			=1'b0;
	
case (current_state)
idle: begin
	    cyc_o =1'b0;
			we_o =1'b0;
			done_set=1'b0;
			D_offset_cnt_en =1'b0;
			offset_reset =1'b1; 
			row_reset =1'b1;
			col_reset = 1'b1;
			if (start)  
			  next_state = read_prev_0;
			else		 
			  next_state = idle;
      end
	  
/*************************************************************/	  
read_prev_0: begin
	    offset_reset =1'b0;
	    row_reset =1'b0;
	    we_o =1'b0;
	    row_cnt_en =1'b0;
	    D_offset_cnt_en =1'b0;
			col_reset = 1'b1; 
			prev_row_load = 1'b1;
			cyc_o	= 1'b1;
			if (ack_i)  
			   next_state = read_curr_0;
			else	
			 next_state = read_prev_0;
		  end
/***********************************************************************/		  
read_curr_0: begin
	    col_reset = 1'b0; 
	    prev_row_load = 1'b0;	
 			curr_row_load =1'b1; 
 			cyc_o =1'b1;
			if (ack_i)              
			   next_state = read_next_0;
			else		 
			   next_state = read_curr_0;
		  end
/*********************************************************************/
read_next_0: begin
	    curr_row_load =1'b0;
			next_row_load =1'b1; 
			cyc_o =1'b1;
			if (ack_i)	          
			  begin
				  O_offset_cnt_en =1'b1;
				  next_state =comp1_0;
			  end
			else 
			   next_state = read_next_0;
		  end
/********************************************************************/
comp1_0: begin
	    next_row_load =1'b0; 
	    cyc_o =1'b0;
	    O_offset_cnt_en =1'b0;
			shift_en =1'b1;
			next_state =comp2_0;
		  end
comp2_0: begin
			shift_en =1'b1;
			next_state =comp3_0;
		  end
comp3_0: begin
			shift_en =1'b1;
			next_state =comp4_0;
		  end
comp4_0: begin
			shift_en =1'b1;
			next_state =read_prev;
		  end	
/**************************************************************/
read_prev: begin
	    shift_en =1'b0;	
	    we_o =1'b0;
	    col_cnt_en =1'b0; 
	    D_offset_cnt_en =1'b0;
			prev_row_load = 1'b1;
			cyc_o	= 1'b1;
			if (ack_i)  
			   next_state = read_curr;
			else	
			 next_state = read_prev;
		  end	   
read_curr: begin	
	    prev_row_load = 1'b0;
	    curr_row_load = 1'b1;
			cyc_o	= 1'b1;
			if (ack_i)  
			   next_state = read_next;
			else	
			 next_state = read_curr;
		  end	
read_next: begin
	    curr_row_load = 1'b0;	
	    next_row_load =1'b1;
			cyc_o	= 1'b1;
			if (ack_i)
				 begin
				 	 O_offset_cnt_en =1'b1;  
			     next_state = comp1;
			   end
			else	
			    next_state = read_next;
		  end
/************************************************************/		  
comp1: begin
	    next_row_load =1'b0;
	    O_offset_cnt_en =1'b0; 
	    cyc_o =1'b0;
			shift_en =1'b1;
			next_state =comp2;
		  end		   
comp2: begin
			shift_en =1'b1;
			next_state =comp3;
		  end
comp3: begin
			shift_en =1'b1;
			next_state =comp4;
		  end		   
comp4: begin
			shift_en =1'b1;
			if (col ==(WIDTH/4-2)) 
			    next_state = write_158;
			else			 
			    next_state =	write_result;
			end
/********************************************************/
write_result: begin
	    shift_en =1'b0;
			cyc_o =1'b1; 
			we_o =1'b1;
			if(ack_i)	
			  begin
				  col_cnt_en =1'b1; 
				  D_offset_cnt_en =1'b1;
				  next_state =read_prev;
			  end
			else 
			   next_state = write_result;
	  		end
write_158: begin
	    shift_en =1'b0;
			cyc_o =1'b1; 
			we_o =1'b1;
			if(ack_i)	
			  begin
				  col_cnt_en =1'b1; 
				  D_offset_cnt_en =1'b1;
				  next_state =comp1_159;
			  end
			else 
			    next_state =write_158;
			end
/***************************************************************/
comp1_159: begin                              //compute的流水线输出
	    col_cnt_en =1'b0;
	    D_offset_cnt_en =1'b0; 
	    cyc_o =1'b0;
	    we_o =1'b0;
			shift_en =1'b1;
			next_state =comp2_159;
		  end			
comp2_159: begin
	    shift_en =1'b1;
			next_state =comp3_159;
		  end				
comp3_159: begin
	    shift_en =1'b1;
			next_state =comp4_159;
		  end	
comp4_159: begin
	    shift_en =1'b1;
			next_state =write_159;
		  end			  			
write_159: begin
	    shift_en =1'b0;
			cyc_o =1'b1;
			we_o =1'b1;
			if(ack_i)	
			  begin
				D_offset_cnt_en =1'b1;
				if (row == HEIGHT-3) //done
				   begin
					   done_set =1'b1;
					   next_state = idle;
				   end
				else 
				  begin
					  row_cnt_en =1'b1;
					  next_state =read_prev_0;
					end
			 end
			else 
			   next_state = write_159;
			end
	endcase
end
/*******************************************************************/

assign stb_o = cyc_o;

endmodule
