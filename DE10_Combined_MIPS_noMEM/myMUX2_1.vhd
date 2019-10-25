--| myMUX2_1
--| 2 input, single bit multiplexer
--|
--| INPUTS:
--| i_0 - Input 0
--| i_1 - Input 1
--| i_s - Select Input
--|
--| OUTPUTS:
--| o_Z - Output i_0 if i_S = 0 and i_1 if i_S = 1
library IEEE;
use IEEE.std_logic_1164.all;

entity myMUX2_1 is
	port (i_0 : in  std_logic;
			i_1 : in  std_logic;
			i_S : in  std_logic;
			o_Z : out std_logic);
end myMUX2_1;

architecture a_myMUX2_1 of myMUX2_1 is
--| Declare Components
	component myNAND2 is
		port (i_A : in  std_logic;
				i_B : in  std_logic;
				o_Z : out std_logic);
	end component;

	component myINV is
		port (i_A : in  std_logic;
				o_Z : out std_logic);
	end component;
--| Declare signals
	signal w_S_n		: std_logic; -- INV(i_S)
	signal w_S_ni_0	: std_logic; -- NAND(INV(i_S),i_0)
	signal w_Si_1		: std_logic; -- NAND(i_S,i_1)
begin
	u_myINV_S: myINV
	port map (i_A => i_S,
				 o_Z => w_S_n);
	u_myNAND2_S_ni_0: myNAND2
	port map (i_A => w_S_n,
				 i_B => i_0,
				 o_Z => w_S_ni_0);
	u_myNAND2_Si_1: myNAND2
	port map (i_A => i_S,
				 i_B => i_1,
				 o_Z => w_Si_1);
	u_myNAND2_MUX_OUT: myNAND2
	port map (i_A => w_S_ni_0,
				 i_B => w_Si_1,
				 o_Z => o_Z);
end a_myMUX2_1;