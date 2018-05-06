library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rs232 is
	Port (		clk_i : in  STD_LOGIC;
				rst_i : in std_logic;
				RXD_i : in std_logic;
				TXD_o : out std_logic);
end rs232;

architecture Behavioral of rs232 is


type stateRS is (quiet, start, data, stop);
signal state : stateRS := quiet;
signal enable : std_logic := '0';
signal frame : std_logic_vector(7 downto 0) := "11111111";
signal toedit: std_logic_vector(7 downto 0) := "11111111";

begin
	
	p1:process(clk_i, rst_i)
		variable counter: integer range 0 to 10000 := 0;
		variable little_counter: integer range 0 to 8 := 0;

		begin
		if(rst_i = '1') then 
			frame <= "11111111";
			counter := 0;
			little_counter := 0;
			state <= quiet;
			enable <= '0';
		elsif rising_edge(clk_i) then
			if(enable = '0') then
				if(RXD_i = '1') then
					state <= quiet;
				else
					state <= start;
					enable <= '1';
				end if;
			else
				counter := counter + 1;
				if(state = start and RXD_i = '0' and counter = 2604) then
					state <= data;
					counter := 0;
				elsif(state = data and counter = 5208) then
					if(little_counter /= 8) then
						frame(little_counter) <= RXD_i;
						little_counter := little_counter + 1;
					else
						little_counter := 0;
						state <= stop;
						toedit <= frame + x"20";
					end if;
					counter := 0;
				elsif(state = stop) then
					enable <= '0';
					counter := 0;
				end if;
			end if;			
		end if;
	end process;
	
	p2:process(clk_i)
	variable answer_counter: integer range 0 to 10000000;
	variable n: integer range 0 to 9;
	variable answer_enable: std_logic := '0';
		begin
			if rising_edge(clk_i) then
				if(state = stop) then
					answer_enable := '1';
				end if;
				if(answer_enable = '0') then
					TXD_o <= '1';
				elsif(answer_enable = '1') then
					if(answer_counter = 5208) then
						case n is
								when 0 => 	TXD_o <= '0';
												n := n + 1;
								when 9 => 	TXD_o <= '1';
												n := 0;
												answer_enable := '0';
												
							when others => TXD_o <= toedit(n-1);
												n := n + 1;
						end case;
						answer_counter := 0;
					end if;				
					answer_counter := answer_counter + 1;
				end if;
			end if;
	end process;

end Behavioral;