--| myMUX2_1_TB
--| Tests myMUX2_1
library IEEE;
use IEEE.std_logic_1164.all;

entity myMUX2_1_TB is
end myMUX2_1_TB;

architecture testbench of myMUX2_1_TB is
	-- Declare Components
	component myMUX2_1 is
		port (i_0 : in  std_logic;
				i_1 : in  std_logic;
				i_S : in  std_logic;
				o_Z : out std_logic
				);
	end component;

	-- Declare signals
	signal w_0 : std_logic := '0';
	signal w_1 : std_logic := '1';
	signal w_S : std_logic := '0';
	signal w_Z : std_logic;

begin	
	-- Connect myMUX2_1
	u_myMUX2_1: myMUX2_1
	port map (i_0 => w_0,
				 i_1 => w_1,
				 i_S => w_S,
				 o_Z => w_Z);
	
	-- Process for stimulating inputs		 
	stimulus: process is
	begin
		wait for 20 ns;
		w_S <= '1';
		wait for 20 ns;
		w_0 <= '1';
		w_1 <= '0';
		wait for 20 ns;
		w_S <= '0';
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;