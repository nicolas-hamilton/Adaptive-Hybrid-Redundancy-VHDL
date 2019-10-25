--| myINV
--| Perfomrs the invert operation Z = NOT(A)
--|
--| INPUTS:
--| A - Input A
--|
--| OUTPUTS:
--| Z - NOT(A)
library IEEE;
use IEEE.std_logic_1164.all;

entity myINV is
	port (i_A : in  std_logic;
			o_Z : out std_logic);
end myINV;

architecture a_myINV of myINV is

	component myNAND2 is
		port (i_A : in  std_logic;
				i_B : in  std_logic;
				o_Z : out std_logic
				);
	end component;
begin
	u_myNAND2: myNAND2
	port map (i_A => i_A,
				 i_B => i_A,
				 o_Z => o_Z);
end a_myINV;