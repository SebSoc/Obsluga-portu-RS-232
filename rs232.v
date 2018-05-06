`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:37:17 03/04/2018 
// Design Name: 
// Module Name:    rs232 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

//utworzenie makr okreœlaj¹cych aktualny stan transmisji
`define quiet 2'b00
`define start 2'b01
`define data 2'b10
`define stop 2'b11

module rs232(TXD_o, clk_i, rst_i, RXD_i);		//modu³ g³ówny
	 
	 output TXD_o;
	 input clk_i;
    input rst_i;
    input RXD_i;
   
	 wire [7:0] toedit;		//wektor s³u¿¹cy jako bufor dla ramki
	 wire [1:0] state;		//zmienna przechowuj¹ca stan 00-quiet, 01-start, 10-data, 11-stop
	 	 
	 rxd r(toedit, state, clk_i, rst_i, RXD_i);		//odbiornik
	 txd t(TXD_o, clk_i, state, toedit);				//nadajnik


endmodule


module rxd (toedit, state, clk_i, rst_i, RXD_i);		//modu³ odbiornika

output [7:0] toedit;					
output [1:0] state;
input clk_i, rst_i, RXD_i;
reg [1:0] state; 
reg [7:0] frame, toedit; 						//do wektora frame zbierany jest bajt danych
reg enable;											//flaga okreslajacy czy jakaœ dana jest przesy³ana
integer counter, little_counter;				//counter liczy cykle zegara aby probkowac go w odpowiednim momencie, little_counter liczy bity

initial					//inicjalizacja zmiennych
	begin
		toedit = 8'b11111111;
		state = `quiet;
		enable = 1'b0;
		frame = 8'b11111111;
		counter = 0;
		little_counter = 0;		
	end


always @(posedge clk_i or posedge rst_i )				//oczekawanie na zdarzenie, zegar lub reset
	begin
		if(rst_i)												//obs³uga resetu
			begin
				frame = 8'b11111111;
				counter = 0;
				little_counter = 0;
				state = `quiet;
				enable = 1'b0;
			end
		else														//normalny tryb pracy
			begin
				if(enable == 1'b0)							//gdy stan bez transmisji
					begin
						if(RXD_i == 1'b1)						
							begin
								state = `quiet;				//stan bez transmisji
							end
						else
							begin
								state = `start;				//bit startu
								enable = 1'b1;					//rozpoczecie odbioru danych
							end
					end
				else
					begin
						counter = counter + 1;				//licznik rosnie z czestotliwoscia 50MHz
						if(state == `start && RXD_i == 1'b0 && counter == 2604)	//2604 czyli w polowie bitu probkujemy i sprawdzamy czy to bit startu
							begin
								state = `data;													//8 bitów danych
								counter = 0;
							end
						else if(state == `data && counter == 5208)					//próbkowanie z czestotliwoscia 9600
							begin
								if(little_counter != 8)										//zbieranie 8 bitów
									begin
										frame[little_counter] = RXD_i;
										little_counter = little_counter + 1;
									end
								else																//bit stopu
									begin
										little_counter = 0;
										state = `stop;
										toedit = frame + 8'h20;								//dodajemy h20 zgodnie z poleceniem i zapisujemy w buforze
									end
								counter = 0;
							end
						else if(state == `stop)												//w po³owie bitu stopu przechodzimy w stan pasywny i jestesmy gotowi na kolejna ramke
							begin
								enable = 1'b0;
								counter = 0;
							end
					end
			end	
	end
endmodule


module txd(TXD_o, clk_i, state, toedit);											//modu³ nadajnika

output TXD_o;
input clk_i; 
input [1:0] state;
input [7:0] toedit;

integer counter, bitNr;																//counter podobnie jak w rxd, bitNr liczy bity tak jak little_counter
reg enable;																				//pozwolenie na aktywacje nadajnika
reg TXD_o;

initial																					//inicjalizacja zmiennych
	begin
		counter = 0;
		bitNr = 0;
		enable = 1'b0;
	end
	
always @(posedge clk_i)																//oczekiwanie na zdarzenie - narastaj¹ce zbocze zegara
	begin
		if(state == `stop)															//je¿eli odbiornik odebra³ bit stopu mo¿na aktywowaæ nadajnik
			begin
				enable = 1'b1;
			end
		if(enable == 1'b0)															//stan pasywny nadajnika
			begin
				TXD_o = 1'b1;
			end
		else if(enable == 1'b1)
			begin
				if(counter == 5208)													//nadawanie czestotliwosc 9600
					begin
						case (bitNr)
							0			:begin											//bit startu
											TXD_o = 1'b0;
											bitNr = bitNr + 1;
										end
							9			:begin											//bit stopu
											TXD_o = 1'b1;
											bitNr = 0;
											enable = 1'b0;
										end
							default	:begin											//ramka danych
											TXD_o = toedit[bitNr-1];				//wysy³anie zawartoœci bufora
											bitNr = bitNr + 1;
										end
						endcase
						counter = 0;
					end
				counter = counter + 1;
			end
	end
endmodule
