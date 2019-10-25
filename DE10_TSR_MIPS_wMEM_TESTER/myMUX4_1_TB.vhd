--| myMUX4_1_TB
--| Tests myMUX4_1
library IEEE;
use IEEE.std_logic_1164.all;

entity myMUX4_1_TB is
end myMUX4_1_TB;

architecture testbench of myMUX4_1_TB is
	-- Declare Components
	component myMUX4_1 is
		port (i_0 : in  std_logic;
				i_1 : in  std_logic;
				i_2 : in  std_logic;
				i_3 : in  std_logic;
				i_S : in  std_logic_vector(1 downto 0);
				o_Z : out std_logic
				);
	end component;

	-- Declare signals
	signal w_0 : std_logic := '0';
	signal w_1 : std_logic := '1';
	signal w_2 : std_logic := '1';
	signal w_3 : std_logic := '0';
	signal w_S : std_logic_vector(1 downto 0) := B"00";
	signal w_Z : std_logic;

begin	
	-- Connect myMUX4_1
	u_myMUX4_1: myMUX4_1
	port map (i_0 => w_0,
				 i_1 => w_1,
				 i_2 => w_2,
				 i_3 => w_3,
				 i_S => w_S,
				 o_Z => w_Z);
	
	-- Process for stimulating inputs		 
	stimulus: process is
	begin
		wait for 20 ns;
		w_S <= B"01";
		wait for 20 ns;
		w_S <= B"10";
		wait for 20 ns;
		w_S <= B"11";
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;