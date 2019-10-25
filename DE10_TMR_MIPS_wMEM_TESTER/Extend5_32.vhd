--| Extend5_32.vhd
--| Zero Extend a 5-bit value to a 32-bit value
--|
--| INPUTS:
--| i_A - Input A
--|
--| OUTPUTS:
--| o_Z - Extended input
library IEEE;
use IEEE.std_logic_1164.all;

entity Extend5_32 is
	port (i_A	: in  std_logic_vector(4 downto 0);
			o_Z	: out std_logic_vector(31 downto 0));
end Extend5_32;

architecture a_Extend5_32 of Extend5_32 is	
begin
	o_Z <= B"000_0000_0000_0000_0000_0000_0000" & i_A;
end a_Extend5_32;