--| myMUX16_1
--| 16 input, single bit multiplexer
--|
--| INPUTS:
--| i_0  - Input 0
--| i_1  - Input 1
--| i_2  - Input 2
--| i_3  - Input 3
--| i_4  - Input 4
--| i_5  - Input 5
--| i_6  - Input 6
--| i_7  - Input 7
--| i_8  - Input 8
--| i_9  - Input 9
--| i_10 - Input 10
--| i_11 - Input 11
--| i_12 - Input 12
--| i_13 - Input 13
--| i_14 - Input 14
--| i_15 - Input 15
--| i_S - Select input
--|
--| OUTPUTS:
--| o_Z - Output the input corresponding the the decimal representation of i_S
library IEEE;
use IEEE.std_logic_1164.all;

entity myMUX16_1 is
	port (i_0	: in  std_logic;
			i_1	: in  std_logic;
			i_2	: in  std_logic;
			i_3	: in  std_logic;
			i_4	: in  std_logic;
			i_5	: in  std_logic;
			i_6	: in  std_logic;
			i_7	: in  std_logic;
			i_8	: in  std_logic;
			i_9	: in  std_logic;
			i_10	: in  std_logic;
			i_11	: in  std_logic;
			i_12	: in  std_logic;
			i_13	: in  std_logic;
			i_14	: in  std_logic;
			i_15	: in  std_logic;
			i_S	: in  std_logic_vector (3 downto 0);
			o_Z	: out std_logic);
end myMUX16_1;

architecture a_myMUX16_1 of myMUX16_1 is
--| Declare Components
	component myMUX8_1 is
		port (i_0 : in  std_logic;
				i_1 : in  std_logic;
				i_2 : in  std_logic;
				i_3 : in  std_logic;
				i_4 : in  std_logic;
				i_5 : in  std_logic;
				i_6 : in  std_logic;
				i_7 : in  std_logic;
				i_S : in  std_logic_vector (2 downto 0);
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
	signal w_0_7	: std_logic; -- MUX(0,1, 2, 3, 4, 5, 6, 7,i_S(2:0))
	signal w_8_15	: std_logic; -- MUX(8,9,10,11,12,13,14,15,i_S(2:0))
begin
	u_myMUX8_1_0_7: myMUX8_1
	port map (i_0 => i_0,
				 i_1 => i_1,
				 i_2 => i_2,
				 i_3 => i_3,
				 i_4 => i_4,
				 i_5 => i_5,
				 i_6 => i_6,
				 i_7 => i_7,
				 i_S => i_S(2 downto 0),
				 o_Z => w_0_7);
	u_myMUX8_1_8_15: myMUX8_1
	port map (i_0 => i_8,
				 i_1 => i_9,
				 i_2 => i_10,
				 i_3 => i_11,
				 i_4 => i_12,
				 i_5 => i_13,
				 i_6 => i_14,
				 i_7 => i_15,
				 i_S => i_S(2 downto 0),
				 o_Z => w_8_15);
	u_myMUX2_1_OUT: myMUX2_1
	port map (i_0 => w_0_7,
				 i_1 => w_8_15,
				 i_S => i_S(3),
				 o_Z => o_Z);
end a_myMUX16_1;