--| Sign_Extend16_32_TB.vhd
--| Test the Sign_Extend16_32.vhd
library IEEE;
use IEEE.std_logic_1164.all;

entity Sign_Extend16_32_TB is
end Sign_Extend16_32_TB;

architecture testbench of Sign_Extend16_32_TB is
--| Declare components
	component Sign_Extend16_32 is
		port (i_A	: in  std_logic_vector(15 downto 0);
				o_Z	: out std_logic_vector(31 downto 0));
	end component;

--| Declare Signals
	signal w_A : std_logic_vector(15 downto 0) := B"0000_1111_0101_1001";
	signal w_Z : std_logic_vector(31 downto 0);
begin
	u_Sign_Extend16_32: Sign_Extend16_32
	port map(i_A => w_A,
				o_Z => w_Z);
				
	stimulus: process is
	begin
		wait for 20 ns;
		w_A <= B"1100_1111_0101_1001";
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;