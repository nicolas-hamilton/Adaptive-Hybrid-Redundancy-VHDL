--| myNAND2
--| Perfomrs the operation Z = NAND(A,B)
--|
--| INPUTS:
--| A - Input A
--| B - Input B
--|
--| OUTPUTS:
--| Z - NAND(A,B)
library IEEE;
use IEEE.std_logic_1164.all;

entity myNAND2 is
	port (i_A : in  std_logic;
			i_B : in  std_logic;
			o_Z : out std_logic
			);
end myNAND2;

architecture a_myNAND2 of myNAND2 is
begin
	o_Z <= i_A nand i_B;
end a_myNAND2;