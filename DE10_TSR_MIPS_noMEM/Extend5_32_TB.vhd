--| Extend5_32_TB.vhd
--| Test the Extend5_32.vhd
library IEEE;
use IEEE.std_logic_1164.all;

entity Extend5_32_TB is
end Extend5_32_TB;

architecture testbench of Extend5_32_TB is
--| Declare components
	component Extend5_32 is
		port (i_A	: in  std_logic_vector(4 downto 0);
				o_Z	: out std_logic_vector(31 downto 0));
	end component;

--| Declare Signals
	signal w_A : std_logic_vector(15 downto 0) := B"0_1001";
	signal w_Z : std_logic_vector(31 downto 0);
begin
	u_Extend5_32: Extend5_32
	port map(i_A => w_A,
				o_Z => w_Z);
				
	stimulus: process is
	begin
		wait for 20 ns;
		w_A <= B"1_1001";
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;