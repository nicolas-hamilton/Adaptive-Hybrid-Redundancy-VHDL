--| SLL2_TB.vhd
--| Test the SLL2.vhd
library IEEE;
use IEEE.std_logic_1164.all;

entity SLL2_32_TB is
end SLL2_32_TB;

architecture testbench of SLL2_32_TB is
--| Declare components
	component SLL2_32 is
		port (i_A	: in  std_logic_vector(31 downto 0);
				o_Z	: out std_logic_vector(31 downto 0));
	end component;

--| Declare Signals
	signal w_A : std_logic_vector(31 downto 0) := B"0000_0000_0000_1111_0000_1111_0101_1001";
	signal w_Z : std_logic_vector(31 downto 0);
begin
	u_SLL2_32: SLL2_32
	port map(i_A => w_A,
				o_Z => w_Z);
				
	stimulus: process is
	begin
		wait for 20 ns;
		w_A <= B"1111_0000_1111_0000_1100_1111_0101_1001";
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;