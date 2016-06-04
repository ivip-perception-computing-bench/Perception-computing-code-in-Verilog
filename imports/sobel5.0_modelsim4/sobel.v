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
// Description: Sobel operator���ӿڣ�wishbone
//����ͼƬ��ʽ��8λbmp��640*480
//ͼƬ���ϲ�ģ��д��Ƭ�ϴ洢��������������ϲ�ģ�齫�������
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
`define width 640 //ԭʼͼƬ���
`define height 480 //ԭʼͼƬ�߶�
module sobel(
	clk_i,
	rst_i,
	
	cyc_i,
	stb_i,
	
	start,   //״̬����ʼ�ź�
	we,   
	
	adr_in,  //�ϲ�ģ���дsobelʱ�ĵ�ַ����
	dat_in,   //�ϲ�ģ����sobelд����ʱ����������
	dat_out,      //�ϲ�ģ���sobel���ʱ�ĵ�ַ���
	ack_out,    //���ϼ�ģ���ack

	done     //��ͼƬ��ȫ������ʱ�����ź���Ч���ϲ�ģ�鿪ʼ��sobel���
    );
	 
input  clk_i;
input  rst_i;

input cyc_i;
input stb_i;

input  start;   //״̬����ʼ�źţ�״̬��idle������һ��״̬
input	 we;

input [21:0] adr_in;
input [31:0] dat_in;    //sobelģ�����ⲿģ��ͨ�ŵ����ݽӿ�
output  [31:0] dat_out;   //sobelģ�����ⲿģ��ͨ�ŵ����ݽӿ�

output reg ack_out;
output  done;   //ͼƬ����ȫ������ʱ�����ź���Ч

wire  readstart;   //�ϲ�ģ����sobel��memoryд��Ƭ����ʱ��Ч

wire   start;     //״̬����ʼ�źţ�״̬��idle������һ��״̬
wire   cyc_o;     //״̬����memory��cyc�ź�
wire   stb_o;     //assign stb_o=cyc_o
wire   we_o;		//״̬����memory��we�źţ�0Ϊ����1Ϊд

wire   done_set;    //���һ��״̬�������ź���Ч����һ��״̬Ϊidle
wire   shift_en;    //״̬����compģ����ź�
wire   prev_row_load;   //�ź���Ч�����ʾ���ڶ����ǵ�1�е�����
wire   curr_row_load;	//�ź���Ч�����ʾ���ڶ����ǵ�2�е�����
wire   next_row_load;	//�ź���Ч�����ʾ���ڶ����ǵ�3�е�����
wire   O_offset_cnt_en;   //״̬����addr_gen�ĵ�ַ����ʹ��
wire   D_offset_cnt_en;		//״̬����addr_gen�ĵ�ַ����ʹ��
wire   offset_reset;     //״̬����addr_gen�ĵ�ַ���������źţ�idle״̬ʱ���ź���Ч����ַ���¼���
wire[31:0]   result_row;   //compģ��ļ������������memory
wire[31:0]   dat_i;    //memory�����compģ�������
wire[21:0]   adr_o;    //addr_gen�����memory�ĵ�ַ
wire mem_ack_out;

wire done;   //ͼƬ����ȫ������ʱ�����ź���Ч

assign readstart = cyc_i;

//--------------------�л�memoryģ����������--------------------------
reg mem_we;
reg mem_cyc;
reg mem_stb;
reg [21:0] mem_adr_i;
wire [21:0] adr_out;
reg [31:0] mem_dat_in;

always @* begin  
	if(cyc_i) begin     //�ϲ�ģ�齫��Ƭд��sobelģ��
		mem_cyc = cyc_i;
		mem_stb = stb_i;
		mem_we = we;
		mem_adr_i = adr_in;
		mem_dat_in = dat_in;
		ack_out = mem_ack_out;
	end
	else begin            //��Ƭд��memory��sobelģ�鿪ʼ���У���ʱmemory��comp��״̬������
		mem_cyc = cyc_o;
		mem_stb = stb_o;
		mem_we = we_o;
		mem_adr_i = adr_o;
		mem_dat_in = result_row;
		ack_out = 0;
	end
end
//----------------------------------------------------------------------------

assign dat_out[31:0] = dat_i; // sobelģ������������ͼƬ�������Ժ���Ч
assign   ack_i = mem_ack_out;  //memory��״̬����ack�ź�

compute compute(
	.rst_i(rst_i),     
	.clk_i(clk_i),
//��memory������32λ����                
	.dat_i(dat_i),     
//״̬�������ź�
	.shift_en(shift_en),    
	.prev_row_load(prev_row_load),
	.curr_row_load(curr_row_load),
	.next_row_load(next_row_load),
//������      
	.result_row(result_row)
);
  
mem  mem(
	.clk_i(clk_i),
              
	.mem_cyc_i(mem_cyc),
	.mem_stb_i(mem_stb),
	.mem_we_i(mem_we),       //1Ϊ��ģ��д��0Ϊ��
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

//���ĳһ�е�ַ��ʹ���ź�               
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
	.offset_reset(offset_reset),      //��ַ��������
               
//��ַ����ʹ��              
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
