--| myMUX8_1
--| 8 input, single bit multiplexer
--|
--| INPUTS:
--| i_0 - Input 0
--| i_1 - Input 1
--| i_2 - Input 2
--| i_3 - Input 3
--| i_4 - Input 4
--| i_5 - Input 5
--| i_6 - Input 6
--| i_7 - Input 7
--| i_S - Select Input
--|
--| OUTPUTS:
--| o_Z - Output the input corresponding the the decimal representation of i_S
library IEEE;
use IEEE.std_logic_1164.all;

entity myMUX8_1 is
	port (i_0 : in  std_logic;
			i_1 : in  std_logic;
			i_2 : in  std_logic;
			i_3 : in  std_logic;
			i_4 : in  std_logic;
			i_5 : in  std_logic;
			i_6 : in  std_logic;
			i_7 : in  std_logic;
			i_S : in  std_logic_vector (2 downto 0);
			o_Z : out std_logic);
end myMUX8_1;

architecture a_myMUX8_1 of myMUX8_1 is
--| Declare Components
	component myMUX4_1 is
		port (i_0 : in  std_logic;
				i_1 : in  std_logic;
				i_2 : in  std_logic;
				i_3 : in  std_logic;
				i_S : in  std_logic_vector (1 downto 0);
				o_Z : out std_logic
				);
	end component;
	component myMUX2_1 is
		port (i_0 : in  std_logic;
				i_1 : in  std_logic;
				i_S : in  std_logic;
				o_Z : out std_logic
				);
	end component;
--| Declare signals
	signal w_0123	: std_logic; -- MUX(0,1,2,3,i_S(1:0))
	signal w_4567	: std_logic; -- MUX(4,5,6,7,i_S(1:0))
begin
	u_myMUX4_1_0123: myMUX4_1
	port map (i_0 => i_0,
				 i_1 => i_1,
				 i_2 => i_2,
				 i_3 => i_3,
				 i_S => i_S(1 downto 0),
				 o_Z => w_0123);
	u_myMUX4_1_4567: myMUX4_1
	port map (i_0 => i_4,
				 i_1 => i_5,
				 i_2 => i_6,
				 i_3 => i_7,
				 i_S => i_S(1 downto 0),
				 o_Z => w_4567);
	u_myMUX2_1_OUT: myMUX2_1
	port map (i_0 => w_0123,
				 i_1 => w_4567,
				 i_S => i_S(2),
				 o_Z => o_Z);
end a_myMUX8_1;