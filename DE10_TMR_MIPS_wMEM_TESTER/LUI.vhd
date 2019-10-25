--| LUI - Load Upper Immediate
--| Perfomrs the operation Z = [Immediate B"0000_0000_0000_0000"]
--|
--| INPUTS:
--| A - Input A
--| B - Input B
--|
--| OUTPUTS:
--| Z - NAND(A,B)
library IEEE;
use IEEE.std_logic_1164.all;

entity LUI is
	port (i_A : in  std_logic_vector(15 downto 0);
			o_Z : out std_logic_vector(31 downto 0)
			);
end LUI;

architecture a_LUI of LUI is
	--| Declare constants
	constant k_zero16 : std_logic_vector(15 downto 0) := (others => '0');
begin
	o_Z <= i_A & k_zero16;
end a_LUI;