--| Decoder5_32_TB
--| Tests Decoder5_32
library IEEE;
use IEEE.std_logic_1164.all;

entity Decoder5_32_TB is
end Decoder5_32_TB;

architecture testbench of Decoder5_32_TB is
	component Decoder5_32 is
		port (i_S	: in  std_logic_vector(4 downto 0);
				o_Z	: out std_logic_vector(31 downto 0)
				);
	end component;

	-- Declare signals
	signal w_S	: std_logic_vector(4 downto 0) := (others => '0');
	signal w_Z	: std_logic_vector(31 downto 0);

begin	
	-- Connect Decoder5_32
	u_Decoder5_32: Decoder5_32
	port map (i_S => w_S,
				 o_Z => w_Z);
	
	-- Process for stimulating inputs		 
	stimulus: process is
	begin
		wait for 20 ns;
		w_S <= B"00001";
		wait for 20 ns;
		w_S <= B"00010";
		wait for 20 ns;
		w_S <= B"00011";
		wait for 20 ns;
		w_S <= B"00100";
		wait for 20 ns;
		w_S <= B"00101";
		wait for 20 ns;
		w_S <= B"00110";
		wait for 20 ns;
		w_S <= B"00111";
		wait for 20 ns;
		w_S <= B"01000";
		wait for 20 ns;
		w_S <= B"01001";
		wait for 20 ns;
		w_S <= B"01010";
		wait for 20 ns;
		w_S <= B"01011";
		wait for 20 ns;
		w_S <= B"01100";
		wait for 20 ns;
		w_S <= B"01101";
		wait for 20 ns;
		w_S <= B"01110";
		wait for 20 ns;
		w_S <= B"01111";
		wait for 20 ns;
		w_S <= B"10000";
		wait for 20 ns;
		w_S <= B"10001";
		wait for 20 ns;
		w_S <= B"10010";
		wait for 20 ns;
		w_S <= B"10011";
		wait for 20 ns;
		w_S <= B"10100";
		wait for 20 ns;
		w_S <= B"10101";
		wait for 20 ns;
		w_S <= B"10110";
		wait for 20 ns;
		w_S <= B"10111";
		wait for 20 ns;
		w_S <= B"11000";
		wait for 20 ns;
		w_S <= B"11001";
		wait for 20 ns;
		w_S <= B"11010";
		wait for 20 ns;
		w_S <= B"11011";
		wait for 20 ns;
		w_S <= B"11100";
		wait for 20 ns;
		w_S <= B"11101";
		wait for 20 ns;
		w_S <= B"11110";
		wait for 20 ns;
		w_S <= B"11111";
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;