--| LEFT_SHIFT_TB
--| Tests LEFT_SHIFT
library IEEE;
use IEEE.std_logic_1164.all;

entity LEFT_SHIFT_TB is
end LEFT_SHIFT_TB;

architecture testbench of LEFT_SHIFT_TB is
	-- Declare Components
	component LEFT_SHIFT is
		port (i_A	: in  std_logic_vector(31 downto 0);
				i_SA	: in  std_logic_vector(4 downto 0);
				o_Z	: out std_logic_vector(31 downto 0)
				);
	end component;

	-- Declare signals
	signal w_A	: std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_0000_0000_0001";
	signal w_SA	: std_logic_vector(4 downto 0) := (others => '0');
	signal w_Z	: std_logic_vector(31 downto 0);

begin	
	-- Connect LEFT_SHIFT
	u_LEFT_SHIFT: LEFT_SHIFT
	port map (i_A => w_A,
				 i_SA => w_SA,
				 o_Z => w_Z);
	
	-- Process for stimulating inputs		 
	stimulus: process is
	begin
		wait for 20 ns;
		w_SA <= B"00001";
		wait for 20 ns;
		w_SA <= B"00010";
		wait for 20 ns;
		w_SA <= B"00011";
		wait for 20 ns;
		w_SA <= B"00100";
		wait for 20 ns;
		w_SA <= B"00101";
		wait for 20 ns;
		w_SA <= B"00110";
		wait for 20 ns;
		w_SA <= B"00111";
		wait for 20 ns;
		w_SA <= B"01000";
		wait for 20 ns;
		w_SA <= B"01001";
		wait for 20 ns;
		w_SA <= B"01010";
		wait for 20 ns;
		w_SA <= B"01011";
		wait for 20 ns;
		w_SA <= B"01100";
		wait for 20 ns;
		w_SA <= B"01101";
		wait for 20 ns;
		w_SA <= B"01110";
		wait for 20 ns;
		w_SA <= B"01111";
		wait for 20 ns;
		w_SA <= B"10000";
		wait for 20 ns;
		w_SA <= B"10001";
		wait for 20 ns;
		w_SA <= B"10010";
		wait for 20 ns;
		w_SA <= B"10011";
		wait for 20 ns;
		w_SA <= B"10100";
		wait for 20 ns;
		w_SA <= B"10101";
		wait for 20 ns;
		w_SA <= B"10110";
		wait for 20 ns;
		w_SA <= B"10111";
		wait for 20 ns;
		w_SA <= B"11000";
		wait for 20 ns;
		w_SA <= B"11001";
		wait for 20 ns;
		w_SA <= B"11010";
		wait for 20 ns;
		w_SA <= B"11011";
		wait for 20 ns;
		w_SA <= B"11100";
		wait for 20 ns;
		w_SA <= B"11101";
		wait for 20 ns;
		w_SA <= B"11110";
		wait for 20 ns;
		w_SA <= B"11111";
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;