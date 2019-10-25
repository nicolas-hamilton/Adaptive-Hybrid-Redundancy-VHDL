--| MUX2_N
--| 2 input, N-bit multiplexer
--|
--| INPUTS:
--| i_0 - Input 0
--| i_1 - Input 1
--| i_S - Select input
--|
--| OUTPUTS:
--| o_Z - Output i_0 if i_S = 0 and i_1 if i_S = 1
library IEEE;
use IEEE.std_logic_1164.all;

entity myMUX2_N is
	generic(m_width : integer := 32);  -- Number of bits in the inputs and output
	port (i_0	: in  std_logic_vector(m_width-1 downto 0);
			i_1	: in  std_logic_vector(m_width-1 downto 0);
			i_S	: in  std_logic;
			o_Z	: out std_logic_vector(m_width-1 downto 0));
end myMUX2_N;

architecture a_myMUX2_N of myMUX2_N is
--| Declare components
	component myMUX2_1 is
		port (i_0 : in  std_logic;
				i_1 : in  std_logic;
				i_S : in  std_logic;
				o_Z : out std_logic
				);
	end component;
begin
	mux2_1_array: for bit_index in 0 to m_width-1 generate
		u_mux2_1 : myMUX2_1
		port map (i_0 => i_0(bit_index),
					 i_1 => i_1(bit_index),
					 i_S => i_S,
					 o_Z => o_Z(bit_index));
	end generate mux2_1_array;
end a_myMUX2_N;