//디지털 입력을 7-segment array와 LCD에 표시까지 해야 함.
module DAC_display(clk, rst, btn, add_sel, dac_csn, dac_ldacn, dac_wrn, dac_a_b, dac_d, seg_sel, seg_data, LCD_E, LCD_RS, LCD_RW, LCD_DATA);
////////////////     Common Variables     ///////////////////
input clk, rst;
parameter DELAY = 0,
		   SET_WRN = 1,
		   FUNCTION_SET = 1,
		   UP_DATA = 2,
		   ENTRY_MODE = 2,
		   DISP_ONOFF = 3,
		   LINE1 = 4,
		   LINE2 = 5,
		   DELAY_T = 6,
		   CLEAR_DISP = 7;
		   
		   
////////////////    variables for DAC     ///////////////////
input [5:0] btn;
input add_sel;
output reg dac_csn, dac_ldacn, dac_wrn, dac_a_b;
output reg [7:0] dac_d;
reg [7:0] cnt_DAC;
reg [1:0] state_DAC; // state for DAC
reg [7:0] dac_d_temp;
wire [5:0] btn_t;
//output reg [7:0] led_out; 어짜피 lcd랑 segment로 볼 거니까 그냥 뺌

////////////////    variables for 7-Segment     ///////////////////
output reg [7:0] seg_sel; // Segment Array
output reg [7:0] seg_data;
reg number_SEG;

////////////////    variables for LCD_text     ///////////////////
output LCD_E;
output reg LCD_RS, LCD_RW;
output reg [7:0] LCD_DATA;
reg [6:0] cnt_LCD;
reg [2:0] state_LCD; // state for LCD
//////////////////////////////////////////////////////////////////		   

/////////////////////////     DAC module    ////////////////////////////
oneshot_universal #(.WIDTH(6)) U1(clk, rst, {btn[5:0]}, {btn_t[5:0]});

always@(posedge clk or negedge rst) begin
	if(!rst) begin
		state_DAC <= DELAY;
	end
	else begin
		case(state_DAC)
			DELAY : if(cnt_DAC == 200) state_DAC <= SET_WRN;
			SET_WRN : if(cnt_DAC == 50) state_DAC <= UP_DATA;
			UP_DATA : if(cnt_DAC == 30) state_DAC <= DELAY;
			endcase
	end
end

always@(posedge clk or negedge rst) begin
	if(!rst) begin
		cnt_DAC <= 0;
	end
	else begin
		case(state_DAC)
			DELAY : 
				if(cnt_DAC>=200) cnt_DAC <= 0;
				else cnt_DAC <= cnt_DAC + 1;
			SET_WRN :
				if(cnt_DAC>=50) cnt_DAC <= 0;
				else cnt_DAC <= cnt_DAC + 1;
			UP_DATA :
				if(cnt_DAC>=30) cnt_DAC <= 0;
				else cnt_DAC <= cnt_DAC + 1;
		endcase
	end
end
always@(posedge clk or negedge rst) begin
	if(!rst) begin
		dac_wrn <= 1;
	end
	else begin
		case(state_DAC)
			DELAY : dac_wrn <= 1;
			SET_WRN : dac_wrn <= 0;
			UP_DATA : dac_d <= dac_d_temp;
		endcase
	end
end
always@(posedge clk or negedge rst) begin
	if(!rst) begin
		dac_d_temp <= 8'b0000_0000;
		//led_out <= 8'b0101_0101;
	end
	else begin
		if(btn_t == 6'b100000) 		dac_d_temp <= dac_d_temp - 8'b0000_0001;
		else if(btn_t == 6'b010000) dac_d_temp <= dac_d_temp + 8'b0000_0001;
		else if(btn_t == 6'b001000) dac_d_temp <= dac_d_temp + 8'b0000_0010;
		else if(btn_t == 6'b000100) dac_d_temp <= dac_d_temp + 8'b0000_0010;
		else if(btn_t == 6'b000010) dac_d_temp <= dac_d_temp + 8'b0000_1000;
		else if(btn_t == 6'b000001) dac_d_temp <= dac_d_temp + 8'b0000_1000;
		else dac_d_temp <= dac_d_temp;
		//led_out <= dac_d_temp;
	end
end

always@(posedge clk) begin
	dac_csn <= 0;
	dac_ldacn <= 0;
	dac_a_b <= add_sel; // 0 : Select A, 1 : Select B
end
/////////////////////////     7-Segment module    ////////////////////////////
always@(posedge clk or negedge rst) begin
	if(!rst) seg_sel <= 8'b1111_1110;
	else begin
		seg_sel <= {seg_sel[6:0], seg_sel[7]};
	end
end
 
always@(*) begin
	case(number_SEG)
		0 : seg_data = 8'b11111100; // 0
		1 : seg_data = 8'b01100000; // 1
	endcase
end

always@(*) begin
	case(seg_sel)
		8'b11111110 : number_SEG = dac_d[0];
		8'b11111101 : number_SEG = dac_d[1];
		8'b11111011 : number_SEG = dac_d[2];
		8'b11110111 : number_SEG = dac_d[3];
		8'b11101111 : number_SEG = dac_d[4];
		8'b11011111 : number_SEG = dac_d[5];
		8'b10111111 : number_SEG = dac_d[6];
		8'b01111111 : number_SEG = dac_d[7];
	endcase
end
/////////////////////////     LCD_text module    ////////////////////////////
always@(posedge clk or negedge rst) begin
	if(!rst) state_LCD <= DELAY;
	else begin
		case(state_LCD)
			DELAY : 
				if(cnt_LCD == 70) state_LCD <= FUNCTION_SET;
			FUNCTION_SET : 
				if(cnt_LCD == 30) state_LCD <= DISP_ONOFF;
			DISP_ONOFF :
				if(cnt_LCD == 30) state_LCD <= ENTRY_MODE;
			ENTRY_MODE :
				if(cnt_LCD == 30) state_LCD <= LINE1;
			LINE1 :
				if(cnt_LCD == 20) state_LCD <= LINE2;
			LINE2 :
				if(cnt_LCD == 20) state_LCD <= DELAY_T;
			DELAY_T :
				if(cnt_LCD == 5) state_LCD <= CLEAR_DISP;
			CLEAR_DISP :
				if(cnt_LCD == 5) state_LCD <= LINE1;
		endcase
	end
end

always@(posedge clk or negedge rst) begin
	if(!rst) cnt_LCD <= 0;
	else begin
		case(state_LCD)
			DELAY : 
				if(cnt_LCD >= 70) cnt_LCD <= 0;
				else cnt_LCD <= cnt_LCD + 1;
			FUNCTION_SET : 
				if(cnt_LCD >= 30) cnt_LCD <= 0;
				else cnt_LCD <= cnt_LCD + 1;
			DISP_ONOFF :
				if(cnt_LCD >= 30) cnt_LCD <= 0;
				else cnt_LCD <= cnt_LCD + 1;
			ENTRY_MODE :
				if(cnt_LCD >= 30) cnt_LCD <= 0;
				else cnt_LCD <= cnt_LCD + 1;
			LINE1 :
				if(cnt_LCD >= 20) cnt_LCD <= 0;
				else cnt_LCD <= cnt_LCD + 1;
			LINE2 :
				if(cnt_LCD >= 20) cnt_LCD <= 0;
				else cnt_LCD <= cnt_LCD + 1;
			DELAY_T :
				if(cnt_LCD >= 5) cnt_LCD <= 0;
				else cnt_LCD <= cnt_LCD + 1;
			CLEAR_DISP :
				if(cnt_LCD >= 5) cnt_LCD <= 0;
				else cnt_LCD <= cnt_LCD + 1;
		endcase
	end
end

always@(posedge clk or negedge rst) begin
	if(!rst) {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_1_0000_0000;
	else begin
		case(state_LCD)
			FUNCTION_SET :
				{LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_0011_1000;
			DISP_ONOFF :
				{LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_0000_1100;
			ENTRY_MODE :
				{LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_0000_0110;
			LINE1 : begin
				case(cnt_LCD)
					00 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_1000_0000; // DDRAM-ADDRESS LINE1
					01 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_0100; // D
					02 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_1001; // I
					03 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_0111; // G
					04 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0101_0100; // T
					05 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_0001; // A
					06 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_1100; // L
					07 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_1001; // I
					09 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0100_1110; // N
					10 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0101_0000; // P
					11 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0101_0101; // U
					12 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0101_0100; // T
					default : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000;
				endcase
			end
			LINE2 : begin
				case(cnt_LCD)
					00 : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_1100_0000; // DDRAM-ADDRESS LINE2
					01 : begin
						if(dac_d[7] == 0) {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
						else			  {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
					end
					02 : begin
						if(dac_d[6] == 0) {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
						else			  {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
					end
					03 : begin
						if(dac_d[5] == 0) {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
						else			  {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
					end
					04 : begin
						if(dac_d[4] == 0) {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
						else			  {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
					end
					05 : begin
						if(dac_d[3] == 0) {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
						else			  {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
					end
					06 : begin
						if(dac_d[2] == 0) {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
						else			  {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
					end
					07 : begin
						if(dac_d[1] == 0) {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
						else			  {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
					end
					08 : begin
						if(dac_d[0] == 0) {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0000; // 0
						else			  {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0011_0001; // 1
					end
					default : {LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_0_0010_0000;
				endcase
			end
			DELAY_T :
				{LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_0000_0010;
			CLEAR_DISP :
				{LCD_RS, LCD_RW, LCD_DATA} <= 10'b0_0_0000_0001;
			default :
				{LCD_RS, LCD_RW, LCD_DATA} <= 10'b1_1_0000_0000;
			endcase
	end
end

assign LCD_E = clk;

endmodule