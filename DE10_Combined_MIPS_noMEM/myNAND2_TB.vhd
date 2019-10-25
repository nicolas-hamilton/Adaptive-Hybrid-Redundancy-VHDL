--| myNAND2_TB
--| Tests myNAND2
library IEEE;
use IEEE.std_logic_1164.all;

entity myNAND2_TB is
end myNAND2_TB;

architecture testbench of myNAND2_TB is
	-- Declare Components
	component myNAND2 is
		port (i_A : in  std_logic;
				i_B : in  std_logic;
				o_Z : out std_logic
				);
	end component;

	-- Declare signals
	signal w_A : std_logic := '0';
	signal w_B : std_logic := '0';
	signal w_Z : std_logic;

begin	
	-- Connect myNAND2
	u_myNAND2: myNAND2
	port map (i_A => w_A,
				 i_B => w_B,
				 o_Z => w_Z);
	
	-- Process for stimulating inputs		 
	stimulus: process is
	begin
		wait for 20 ns;
		w_A <= '1';
		wait for 20 ns;
		w_B <= '1';
		wait for 20 ns;
		w_A <= '0';
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;