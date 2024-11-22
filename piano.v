module piano (CLOCK_50, KEY, PS2_CLK, PS2_DAT, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK, AUD_ADCDAT,	AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, FPGA_I2C_SDAT,	AUD_XCK, AUD_DACDAT, FPGA_I2C_SCLK);
	
	//Inputs
	input	CLOCK_50;
	input [3:0]	KEY;
	inout	PS2_CLK;
	inout PS2_DAT;
	input				AUD_ADCDAT;
	inout				AUD_BCLK;
	inout				AUD_ADCLRCK;
	inout				AUD_DACLRCK;

	inout				FPGA_I2C_SDAT;
	
	//Outputs
	output [7:0] VGA_R;
	output [7:0] VGA_G;
	output [7:0] VGA_B;
	output VGA_HS;
	output VGA_VS;
	output VGA_BLANK_N;
	output VGA_SYNC_N;
	output VGA_CLK;
	output				AUD_XCK;
	output				AUD_DACDAT;

	output				FPGA_I2C_SCLK;
	
	//Registers
	reg time_1;
	reg[24:0] counter;
	reg [7:0] x_step;
   reg [6:0] y_step;
	reg [7:0] data_received;
	reg [2:0] colours[23:0];
	reg [2:0] VGA_COLOUR;
	reg on_off;
	reg [18:0] delay_reg;
	reg [18:0] delay_cnt;
	reg snd;
	
	//Wires
	wire [7:0] ps2_key_data;
	wire ps2_key_pressed;
	wire [7:0] VGA_X;
	wire [6:0] VGA_Y;
	wire [18:0] delay;
	wire				audio_in_available;
	wire		[31:0]	left_channel_audio_in;
	wire		[31:0]	right_channel_audio_in;
	wire				read_audio_in;

	wire				audio_out_allowed;
	wire		[31:0]	left_channel_audio_out;
	wire		[31:0]	right_channel_audio_out;
	wire				write_audio_out;
	
	//Parameters
	parameter Tab_obj = 8'h0D, Q = 8'h15, W = 8'h1D, E = 8'h24, R = 8'h2D, T = 8'h2C, Y = 8'h35, U = 8'h3C, I = 8'h43, O = 8'h44, P = 8'h4D, keyA = 8'h54, keyB = 8'h5B, keyC = 8'h5D, key_1 = 8'h16, key_2 = 8'h1E, key_4 = 8'h25, key_5 = 8'h2E, key_6 = 8'h36, key_8 = 8'h3E, key_9 = 8'h46, key_D = 8'h4E, key_E = 8'h55, key_F = 8'h66;
	parameter clr_r = 3'b100, clr_w = 3'b111, clr_b = 3'b000;
	parameter d_tab = 50000000/130.813/2, d_q = 50000000/130.832/2, d_w = 50000000/164.814/2, d_e = 50000000/174.614/2, d_r = 50000000/195.998/2, d_t = 50000000/220/2, d_y = 50000000/246.942/2, d_u = 50000000/261.626/2, d_i = 50000000/293.665/2, d_o = 50000000/329.628/2, d_p = 50000000/349.228/2, d_keyA = 50000000/391.995/2, d_keyB = 50000000/440/2, d_keyC = 50000000/493.883/2, d_1 = 50000000/138.591/2, d_2 = 50000000/155.563/2, d_4 = 50000000/184.997/2, d_5 = 50000000/207.652/2, d_6 = 50000000/233.082/2, d_8 = 50000000/277.183/2, d_9 = 50000000/311.127/2, d_key_D = 50000000/369.994/2, d_key_E = 50000000/415.305/2, d_key_F = 50000000/466.164/2;

//Keyboard input
always@(posedge CLOCK_50)
	begin
		if (!KEY[0])
		begin 
			counter <= 25'b0000000000000000000000000;
			time_1 <= 1'b0;
			data_received <= 8'h00;
			x_step <= 0;
			y_step <= 0;
		end
		else
			begin
			if (x_step < 159) x_step <= x_step + 1;
			else begin
				x_step <= 0;
				if (y_step < 119) y_step <= y_step + 1;
				else y_step <= 0;
			end
			if (counter < 25'b1011111010111100001000000)
				counter <= counter + 1;
			else
			begin
				if (time_1 < 1)
					time_1 <= 1;
				else
					begin
					data_received <= 8'h00;
					time_1 <= 0;
					end
				counter <= 25'b0000000000000000000000000;
			end
			if (ps2_key_pressed == 1'b1) data_received <= ps2_key_data;
			end
	end
	
assign VGA_X = x_step;
assign VGA_Y = y_step;

integer a, k, c;
//Logic
always @(*) begin

//Assigning Colours
case (data_received)
	Tab_obj: begin
		colours[0] <= clr_r;
	   for (k = 1; k < 14; k = k + 1) colours[k] <= clr_w;
		for (c = 14; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_tab;
	end
	Q: begin
		colours[0] <= clr_w;
		colours[1] <= clr_r;
	   for (k = 2; k < 14; k = k + 1) colours[k] <= clr_w;
		for (c = 14; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_q;
	end
	W: begin
		for (a = 0; a < 2; a = a + 1) colours[a] <= clr_w;
		colours[2] <= clr_r;
	   for (k = 3; k < 14; k = k + 1) colours[k] <= clr_w;
		for (c = 14; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_w;
	end
	E: begin 
		for (a = 0; a < 3; a = a + 1) colours[a] <= clr_w;
		colours[3] <= clr_r;
	   for (k = 4; k < 14; k = k + 1) colours[k] <= clr_w;
		for (c = 14; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_e;
	end
	R: begin
		for (a = 0; a < 4; a = a + 1) colours[a] <= clr_w;
		colours[4] <= clr_r;
	   for (k = 5; k < 14; k = k + 1) colours[k] <= clr_w;
		for (c = 14; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_r;
	end
	T: begin
		for (a = 0; a < 5; a = a + 1) colours[a] <= clr_w;
		colours[5] <= clr_r;
	   for (k = 6; k < 14; k = k + 1) colours[k] <= clr_w;
		for (c = 14; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_t;
	end
	Y: begin
		for (a = 0; a < 6; a = a + 1) colours[a] <= clr_w;
		colours[6] <= clr_r;
	   for (k = 7; k < 14; k = k + 1) colours[k] <= clr_w;
		for (c = 14; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_y;
	end
	U: begin
		for (a = 0; a < 7; a = a + 1) colours[a] <= clr_w;
		colours[7] <= clr_r;
	   for (k = 8; k < 14; k = k + 1) colours[k] <= clr_w;
		for (c = 14; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_u;
	end
	I: begin
		for (a = 0; a < 8; a = a + 1) colours[a] <= clr_w;
		colours[8] <= clr_r;
	   for (k = 9; k < 14; k = k + 1) colours[k] <= clr_w;
		for (c = 14; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_i;
	end
	O: begin
		for (a = 0; a < 9; a = a + 1) colours[a] <= clr_w;
		colours[9] <= clr_r;
	   for (k = 10; k < 14; k = k + 1) colours[k] <= clr_w;
		for (c = 14; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_o;
	end
	P: begin
		for (a = 0; a < 10; a = a + 1) colours[a] <= clr_w;
		colours[10] <= clr_r;
	   for (k = 11; k < 14; k = k + 1) colours[k] <= clr_w;
		for (c = 14; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_p;
	end
	keyA: begin
		for (a = 0; a < 11; a = a + 1) colours[a] <= clr_w;
		colours[11] <= clr_r;
	   for (k = 12; k < 14; k = k + 1) colours[k] <= clr_w;
		for (c = 14; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_keyA;
	end
	keyB: begin
		for (a = 0; a < 12; a = a + 1) colours[a] <= clr_w;
		colours[12] <= clr_r;
	   colours[13] <= clr_w;
		for (c = 14; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_keyB;
	end
	keyC: begin
		for (a = 0; a < 13; a = a + 1) colours[a] <= clr_w;
		colours[13] <= clr_r;
		for (c = 14; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_keyC;
	end
	key_1: begin
	   for (k = 0; k < 14; k = k + 1) colours[k] <= clr_w;
		colours[14] <= clr_r;
		for (c = 15; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_1;
	end
	key_2: begin
	   for (k = 0; k < 14; k = k + 1) colours[k] <= clr_w;
		colours[14] <= clr_b;
		colours[15] <= clr_r;
		for (c = 16; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_2;
	end
	key_4: begin
	   for (k = 0; k < 14; k = k + 1) colours[k] <= clr_w;
		for (a = 14; a < 16; a = a + 1) colours[a] <= clr_b;
		colours[16] <= clr_r;
		for (c = 17; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_4;
	end
	key_5: begin
		for (k = 0; k < 14; k = k + 1) colours[k] <= clr_w;
		for (a = 14; a < 17; a = a + 1) colours[a] <= clr_b;
		colours[17] <= clr_r;
		for (c = 18; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_5;
	end
	key_6: begin
		for (k = 0; k < 14; k = k + 1) colours[k] <= clr_w;
		for (a = 14; a < 18; a = a + 1) colours[a] <= clr_b;
		colours[18] <= clr_r;
		for (c = 19; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_6;
	end
	key_8: begin
		for (k = 0; k < 14; k = k + 1) colours[k] <= clr_w;
		for (a = 14; a < 19; a = a + 1) colours[a] <= clr_b;
		colours[19] <= clr_r;
		for (c = 20; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_8;
	end
	key_9: begin
		for (k = 0; k < 14; k = k + 1) colours[k] <= clr_w;
		for (a = 14; a < 20; a = a + 1) colours[a] <= clr_b;
		colours[20] <= clr_r;
		for (c = 21; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_9;
	end
	key_D: begin
		for (k = 0; k < 14; k = k + 1) colours[k] <= clr_w;
		for (a = 14; a < 21; a = a + 1) colours[a] <= clr_b;
		colours[21] <= clr_r;
		for (c = 22; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 1;
		delay_reg <= d_key_D;
	end
	key_E: begin
		for (k = 0; k < 14; k = k + 1) colours[k] <= clr_w;
		for (a = 14; a < 22; a = a + 1) colours[a] <= clr_b;
		colours[22] <= clr_r;
		colours[23] <= clr_b;
		on_off <= 1;
		delay_reg <= d_key_E;
	end
	key_F: begin
		for (k = 0; k < 14; k = k + 1) colours[k] <= clr_w;
		for (a = 14; a < 23; a = a + 1) colours[a] <= clr_b;
		colours[23] <= clr_r;
		on_off <= 1;
		delay_reg <= d_key_F;
	end
	default: begin
	   for (k = 0; k < 14; k = k + 1) colours[k] <= clr_w;
		for (c = 14; c < 24; c = c + 1) colours[c] <= clr_b;
		on_off <= 0;
		delay_reg <= d_key_F;
	end
endcase

//Assigning colours to specific regions
case(1'b1)

	(VGA_Y < 34): VGA_COLOUR <= clr_b; //Black top 
	((VGA_X <= 3) && (VGA_Y < 83)): VGA_COLOUR <= clr_b; //Black left
	((VGA_X > 156) && (VGA_Y < 83)): VGA_COLOUR <= clr_b; //Black right
	(VGA_Y == 83): VGA_COLOUR <= clr_b; //Black line
	
	(VGA_Y > 83): VGA_COLOUR <= clr_w; //White bottom
	
	//Bottom half
	((VGA_X <= 13) && (VGA_X > 3) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= colours[0]; //Tab
	
	((VGA_X == 14) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= clr_b; //Black line
	((VGA_X > 14) && (VGA_X <= 24) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= colours[1]; //Q
	
	((VGA_X == 25) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= clr_b; //Black line
	((VGA_X > 25) && (VGA_X <= 35) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= colours[2]; //W
	
	((VGA_X == 36) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= clr_b; //Black line
	((VGA_X > 36) && (VGA_X <= 46) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= colours[3]; //E
	
	((VGA_X == 47) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= clr_b; //Black line
	((VGA_X > 47) && (VGA_X <= 57) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= colours[4]; //R
	
	((VGA_X == 58) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= clr_b; //Black line
	((VGA_X > 58) && (VGA_X <= 68) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= colours[5]; //T
	
	((VGA_X == 69) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= clr_b; //Black line
	((VGA_X > 69) && (VGA_X <= 79) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= colours[6]; //Y
	
	((VGA_X == 80) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= clr_b; //Black line
	((VGA_X > 80) && (VGA_X <= 90) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= colours[7]; //U
	
	((VGA_X == 91) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= clr_b; //Black line
	((VGA_X > 91) && (VGA_X <= 101) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= colours[8]; //I
	
	((VGA_X == 102) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= clr_b; //Black line
	((VGA_X > 102) && (VGA_X <= 112) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= colours[9]; //O
	
	((VGA_X == 113) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= clr_b; //Black line
	((VGA_X > 113) && (VGA_X <= 123) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= colours[10]; //P
	
	((VGA_X == 124) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= clr_b; //Black line
	((VGA_X > 124) && (VGA_X <= 134) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= colours[11]; //[
	
	((VGA_X == 135) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= clr_b; //Black line
	((VGA_X > 135) && (VGA_X <= 145) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= colours[12]; //]
	
	((VGA_X == 146) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= clr_b; //Black line
	((VGA_X > 146) && (VGA_X <= 156) && (VGA_Y >= 69) && (VGA_Y < 83)): VGA_COLOUR <= colours[13]; //
	
	
	//Top half
	((VGA_X < 11) && (VGA_X > 3) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[0]; //Tab
	((VGA_X >= 11) && (VGA_X <= 17) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[14]; //1
	
	((VGA_X > 17) && (VGA_X < 22) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[1]; //Q
	((VGA_X >= 22) && (VGA_X <= 28) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[15]; //2
	
	((VGA_X > 28) && (VGA_X <= 35) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[2]; //W
	((VGA_X > 36) && (VGA_X < 44) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[3]; //E
	((VGA_X >= 44) && (VGA_X <= 50) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[16]; //4
	
	((VGA_X > 50) && (VGA_X < 55) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[4]; //R
	((VGA_X >= 55) && (VGA_X <= 61) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[17]; //5
	
	((VGA_X > 61) && (VGA_X < 66) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[5]; //T
	((VGA_X >= 66) && (VGA_X <= 72) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[18]; //6
	
	((VGA_X > 72) && (VGA_X <= 79) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[6]; //Y
	((VGA_X > 80) && (VGA_X < 88) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[7]; //U
	((VGA_X >= 88) && (VGA_X <= 94) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[19]; //8
	
	((VGA_X > 94) && (VGA_X < 99) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[8]; //I
	((VGA_X >= 99) && (VGA_X <= 105) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[20]; //9
	
	((VGA_X > 105) && (VGA_X <= 112) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[9]; //O
	((VGA_X > 113) && (VGA_X < 121) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[10]; //P
	((VGA_X >= 121) && (VGA_X <= 127) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[21]; //-
	
	((VGA_X > 127) && (VGA_X < 132) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[11]; //[
	((VGA_X >= 132) && (VGA_X <= 138) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[22]; //=
	
	((VGA_X > 138) && (VGA_X < 143) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[12]; //]
	((VGA_X >= 143) && (VGA_X <= 149) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[23]; //
	((VGA_X > 149) && (VGA_X <= 156) && (VGA_Y >= 34) && (VGA_Y < 83)): VGA_COLOUR <= colours[13]; //
	
	default: VGA_COLOUR <= clr_b;
endcase
end

//Sound
assign delay = delay_reg;
 
always @(posedge CLOCK_50)
	if(delay_cnt == delay) begin
		delay_cnt <= 0;
		snd <= !snd;
	end else delay_cnt <= delay_cnt + 1;
	
wire [31:0] sound = (on_off == 0) ? 0 : snd ? 32'd10000000 : -32'd10000000;


assign read_audio_in			= audio_in_available & audio_out_allowed;

assign left_channel_audio_out	= left_channel_audio_in+sound;
assign right_channel_audio_out	= right_channel_audio_in+sound;
assign write_audio_out			= audio_in_available & audio_out_allowed;

PS2_Controller PS2 (
	.CLOCK_50				(CLOCK_50),
	.reset				(~KEY[0]),

	.PS2_CLK			(PS2_CLK),
 	.PS2_DAT			(PS2_DAT),

	.received_data		(ps2_key_data),
	.received_data_en	(ps2_key_pressed)
);

vga_adapter VGA (
			.resetn(KEY[0]),
			.clock(CLOCK_50),
			.colour(VGA_COLOUR),
			.x(VGA_X),
			.y(VGA_Y),
			.plot(1'b1),
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK_N(VGA_BLANK_N),
			.VGA_SYNC_N(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "background.mif";

Audio_Controller Audio_Controller (
	// Inputs
	.CLOCK_50						(CLOCK_50),
	.reset						(~KEY[0]),

	.clear_audio_in_memory		(),
	.read_audio_in				(read_audio_in),
	
	.clear_audio_out_memory		(),
	.left_channel_audio_out		(left_channel_audio_out),
	.right_channel_audio_out	(right_channel_audio_out),
	.write_audio_out			(write_audio_out),

	.AUD_ADCDAT					(AUD_ADCDAT),

	// Bidirectionals
	.AUD_BCLK					(AUD_BCLK),
	.AUD_ADCLRCK				(AUD_ADCLRCK),
	.AUD_DACLRCK				(AUD_DACLRCK),


	// Outputs
	.audio_in_available			(audio_in_available),
	.left_channel_audio_in		(left_channel_audio_in),
	.right_channel_audio_in		(right_channel_audio_in),

	.audio_out_allowed			(audio_out_allowed),

	.AUD_XCK					(AUD_XCK),
	.AUD_DACDAT					(AUD_DACDAT)

);

avconf #(.USE_MIC_INPUT(1)) avc (
	.FPGA_I2C_SCLK					(FPGA_I2C_SCLK),
	.FPGA_I2C_SDAT					(FPGA_I2C_SDAT),
	.CLOCK_50					(CLOCK_50),
	.reset						(~KEY[0])
);
endmodule