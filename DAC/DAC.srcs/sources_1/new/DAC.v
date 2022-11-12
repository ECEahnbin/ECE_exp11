module DAC(clk, rst, btn, add_sel, dac_csn, dac_ldacn, dac_wrn, dac_a_b, dac_d, led_out);
input clk, rst;
input [5:0] btn;
input add_sel;
output reg dac_csn, dac_ldacn, dac_wrn, dac_a_b;
output reg [7:0] dac_d;
output reg [7:0] led_out;

reg [7:0] dac_d_temp;
reg [7:0] cnt;
wire [5:0] btn_t;

reg [1:0] state;

parameter DELAY = 2'b00,
		   SET_WRN = 2'b01,
		   UP_DATA = 2'b10;
		   
oneshot_universal #(.WIDTH(6)) U1(clk, rst, {btn[5:0]}, {btn_t[5:0]});

always@(posedge clk or negedge rst) begin
	if(!rst) begin
		state <= DELAY;
	end
	else begin
		case(state)
			DELAY : if(cnt == 200) state <= SET_WRN;
			SET_WRN : if(cnt == 50) state <= UP_DATA;
			UP_DATA : if(cnt == 30) state <= DELAY;
			endcase
	end
end

always@(posedge clk or negedge rst) begin
	if(!rst) begin
		cnt <= 0;
	end
	else begin
		case(state)
			DELAY : 
				if(cnt>=200) cnt <= 0;
				else cnt <= cnt + 1;
			SET_WRN :
				if(cnt>=50) cnt <= 0;
				else cnt <= cnt + 1;
			UP_DATA :
				if(cnt>=30) cnt <= 0;
				else cnt <= cnt + 1;
		endcase
	end
end
always@(posedge clk or negedge rst) begin
	if(!rst) begin
		dac_wrn <= 1;
	end
	else begin
		case(state)
			DELAY : dac_wrn <= 1;
			SET_WRN : dac_wrn <= 0;
			UP_DATA : dac_d <= dac_d_temp;
		endcase
	end
end
always@(posedge clk or negedge rst) begin
	if(!rst) begin
		dac_d_temp <= 8'b0000_0000;
		led_out <= 8'b0101_0101;
	end
	else begin
		if(btn_t == 6'b100000) 		dac_d_temp <= dac_d_temp - 8'b0000_0001;
		else if(btn_t == 6'b010000) dac_d_temp <= dac_d_temp + 8'b0000_0001;
		else if(btn_t == 6'b001000) dac_d_temp <= dac_d_temp + 8'b0000_0010;
		else if(btn_t == 6'b000100) dac_d_temp <= dac_d_temp + 8'b0000_0010;
		else if(btn_t == 6'b000010) dac_d_temp <= dac_d_temp + 8'b0000_1000;
		else if(btn_t == 6'b000001) dac_d_temp <= dac_d_temp + 8'b0000_1000;
		else dac_d_temp <= dac_d_temp;
		led_out <= dac_d_temp;
	end
end

always@(posedge clk) begin
	dac_csn <= 0;
	dac_ldacn <= 0;
	dac_a_b <= add_sel; // 0 : Select A, 1 : Select B
end
endmodule
