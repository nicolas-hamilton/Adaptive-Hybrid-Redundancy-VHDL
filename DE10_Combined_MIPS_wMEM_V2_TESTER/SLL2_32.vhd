--| SLL2_32.vhd
--| Shift a 32-bit input left by 2 bits
--|
--| INPUTS:
--| i_A - Input A
--|
--| OUTPUTS:
--| o_Z - Shifted input
library IEEE;
use IEEE.std_logic_1164.all;

entity SLL2_32 is
	port (i_A	: in  std_logic_vector(31 downto 0);
			o_Z	: out std_logic_vector(31 downto 0));
end SLL2_32;

architecture a_SLL2_32 of SLL2_32 is	
begin
	o_Z <= i_A(29 downto 0) & B"00";
end a_SLL2_32;