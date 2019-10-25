--| Extend16_32.vhd
--| Zero Extend a 16-bit signed value to a 32-bit value
--|
--| INPUTS:
--| i_A - Input A
--|
--| OUTPUTS:
--| o_Z - Sign extended input
library IEEE;
use IEEE.std_logic_1164.all;

entity Extend16_32 is
	port (i_A	: in  std_logic_vector(15 downto 0);
			o_Z	: out std_logic_vector(31 downto 0));
end Extend16_32;

architecture a_Extend16_32 of Extend16_32 is	
begin
	o_Z <= B"0000000000000000" & i_A;
end a_Extend16_32;