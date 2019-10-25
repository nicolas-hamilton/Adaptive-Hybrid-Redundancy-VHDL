--| myINV_TB
--| Tests myINV
library IEEE;
use IEEE.std_logic_1164.all;

entity myINV_TB is
end myINV_TB;

architecture testbench of myINV_TB is
	component myINV is
		port (i_A : in  std_logic;
				o_Z : out std_logic
				);
	end component;
	-- Declare signals
	signal w_A : std_logic := '0';
	signal w_Z : std_logic;
begin
	-- Connect myINV
	u_myINV: myINV
	port map (i_A => w_A,
				 o_Z => w_Z);
	
	-- Process for stimulating inputs		 
	stimulus: process is
	begin
		wait for 20 ns;
		w_A <= '1';
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;