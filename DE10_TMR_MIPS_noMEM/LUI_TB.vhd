--| LUI_TB
--| Tests LUI
library IEEE;
use IEEE.std_logic_1164.all;

entity LUI_TB is
end LUI_TB;

architecture testbench of LUI_TB is
	component LUI is
		port (i_A : in  std_logic_vector(15 downto 0);
				o_Z : out std_logic_vector(31 downto 0)
				);
	end component;

	-- Declare signals
	signal w_A : std_logic_vector(15 downto 0) := B"1111_1111_1111_1111";
	signal w_Z : std_logic_vector(31 downto 0);

begin	
	-- Connect LUI
	u_LUI: LUI
	port map (i_A => w_A,
				 o_Z => w_Z);
	
	-- Process for stimulating inputs		 
	stimulus: process is
	begin
		wait for 20 ns;
		w_A <= B"0000_0000_1111_1111";
		wait for 20 ns;
		w_A <= B"1111_1111_0000_0000";
		wait for 20 ns;
		w_A <= B"0101_0101_0101_0101";
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;