--| myMUX4_1
--| 4 input, single bit multiplexer
--|
--| INPUTS:
--| i_0 - Input 0
--| i_1 - Input 1
--| i_2 - Input 2
--| i_3 - Input 3
--| i_S - Select Input
--|
--| OUTPUTS:
--| o_Z - Output the input corresponding the the decimal representation of i_S
library IEEE;
use IEEE.std_logic_1164.all;

entity myMUX4_1 is
	port (i_0 : in  std_logic;
			i_1 : in  std_logic;
			i_2 : in  std_logic;
			i_3 : in  std_logic;
			i_S : in  std_logic_vector (1 downto 0);
			o_Z : out std_logic);
end myMUX4_1;

architecture a_myMUX4_1 of myMUX4_1 is
--| Declare Components
	component myMUX2_1 is
		port (i_0 : in  std_logic;
				i_1 : in  std_logic;
				i_S : in  std_logic;
				o_Z : out std_logic
				);
	end component;
--| Declare signals
	signal w_01		: std_logic; -- MUX(0,1,i_S(0))
	signal w_23	: std_logic; -- MUX(2,3,i_S(0))
begin
	u_myMUX2_1_01: myMUX2_1
	port map (i_0 => i_0,
				 i_1 => i_1,
				 i_S => i_S(0),
				 o_Z => w_01);
	u_myMUX2_1_23: myMUX2_1
	port map (i_0 => i_2,
				 i_1 => i_3,
				 i_S => i_S(0),
				 o_Z => w_23);
	u_myMUX2_1_0123: myMUX2_1
	port map (i_0 => w_01,
				 i_1 => w_23,
				 i_S => i_S(1),
				 o_Z => o_Z);
end a_myMUX4_1;