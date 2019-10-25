--| MUX4_N
--| 4 input, N-bit multiplexer
--|
--| INPUTS:
--| i_0 - Input 0
--| i_1 - Input 1
--| i_2 - Input 2
--| i_3 - Input 3
--| i_S - Select input
--|
--| OUTPUTS:
--| o_Z - Output the input corresponding the the decimal representation of i_S
library IEEE;
use IEEE.std_logic_1164.all;

entity myMUX4_N is
	generic(m_width : integer := 32);  -- Number of bits in the inputs and output
	port (i_0	: in  std_logic_vector(m_width-1 downto 0);
			i_1	: in  std_logic_vector(m_width-1 downto 0);
			i_2	: in  std_logic_vector(m_width-1 downto 0);
			i_3	: in  std_logic_vector(m_width-1 downto 0);
			i_S	: in  std_logic_vector(1 downto 0);
			o_Z	: out std_logic_vector(m_width-1 downto 0));
end myMUX4_N;

architecture a_myMUX4_N of myMUX4_N is
--| Declare components
	component myMUX4_1 is
		port (i_0 : in  std_logic;
				i_1 : in  std_logic;
				i_2 : in  std_logic;
				i_3 : in  std_logic;
				i_S : in  std_logic_vector(1 downto 0);
				o_Z : out std_logic
				);
	end component;
begin
	mux4_1_array: for bit_index in 0 to m_width-1 generate
		u_mux4_1 : myMUX4_1
		port map (i_0 => i_0(bit_index),
					 i_1 => i_1(bit_index),
					 i_2 => i_2(bit_index),
					 i_3 => i_3(bit_index),
					 i_S => i_S,
					 o_Z => o_Z(bit_index));
	end generate mux4_1_array;
end a_myMUX4_N;