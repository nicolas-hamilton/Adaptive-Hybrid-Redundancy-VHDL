--| Sign_Extend16_32.vhd
--| Sign Extend a 16-bit signed value to a 32-bit signed value
--|
--| INPUTS:
--| i_A - Input A
--|
--| OUTPUTS:
--| o_Z - Sign extended input
library IEEE;
use IEEE.std_logic_1164.all;

entity Sign_Extend16_32 is
	port (i_A	: in  std_logic_vector(15 downto 0);
			o_Z	: out std_logic_vector(31 downto 0));
end Sign_Extend16_32;

architecture a_Sign_Extend16_32 of Sign_Extend16_32 is	
begin
	o_Z <= i_A(15) & i_A(15) & i_A(15) & i_A(15) & 
	       i_A(15) & i_A(15) & i_A(15) & i_A(15) &
			 i_A(15) & i_A(15) & i_A(15) & i_A(15) &
			 i_A(15) & i_A(15) & i_A(15) & i_A(15) & i_A;
end a_Sign_Extend16_32;