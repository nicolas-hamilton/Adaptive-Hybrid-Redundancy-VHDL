--| myINV_N
--| N-bit inverter.  Each bit is inverted idependently of the others
--|
--| INPUTS:
--| i_A - Input to invert
--|
--| OUTPUTS:
--| o_Z - i_0 if i_S = 0 and i_1 if i_S = 1
library IEEE;
use IEEE.std_logic_1164.all;

entity myINV_N is
	generic(m_width : integer := 32);  -- Number of bits in the inputs and output
	port (i_A	: in  std_logic_vector(m_width-1 downto 0);
			o_Z	: out std_logic_vector(m_width-1 downto 0));
end myINV_N;

architecture a_myINV_N of myINV_N is
--| Declare components
	component myINV is
		port (i_A : in  std_logic;
				o_Z : out std_logic);
	end component;
begin
	myINV_array: for bit_index in 0 to m_width-1 generate
		u_myINV : myINV
		port map (i_A => i_A(bit_index),
					 o_Z => o_Z(bit_index));
	end generate myINV_array;
end a_myINV_N;