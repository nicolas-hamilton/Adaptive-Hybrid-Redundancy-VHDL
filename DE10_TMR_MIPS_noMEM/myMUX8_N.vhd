--| MUX8_N
--| 8 input, N-bit multiplexer
--|
--| INPUTS:
--| i_0 - Input 0
--| i_1 - Input 1
--| i_2 - Input 2
--| i_3 - Input 3
--| i_4 - Input 4
--| i_5 - Input 5
--| i_6 - Input 6
--| i_7 - Input 7
--| i_S - Select input
--|
--| OUTPUTS:
--| o_Z - Output the input corresponding the the decimal representation of i_S
library IEEE;
use IEEE.std_logic_1164.all;

entity myMUX8_N is
	generic(m_width : integer := 32);  -- Number of bits in the inputs and output
	port (i_0	: in  std_logic_vector(m_width-1 downto 0);
			i_1	: in  std_logic_vector(m_width-1 downto 0);
			i_2	: in  std_logic_vector(m_width-1 downto 0);
			i_3	: in  std_logic_vector(m_width-1 downto 0);
			i_4	: in  std_logic_vector(m_width-1 downto 0);
			i_5	: in  std_logic_vector(m_width-1 downto 0);
			i_6	: in  std_logic_vector(m_width-1 downto 0);
			i_7	: in  std_logic_vector(m_width-1 downto 0);
			i_S	: in  std_logic_vector(2 downto 0);
			o_Z	: out std_logic_vector(m_width-1 downto 0));
end myMUX8_N;

architecture a_myMUX8_N of myMUX8_N is
--| Declare components
	component myMUX8_1 is
		port (i_0 : in  std_logic;
				i_1 : in  std_logic;
				i_2 : in  std_logic;
				i_3 : in  std_logic;
				i_4 : in  std_logic;
				i_5 : in  std_logic;
				i_6 : in  std_logic;
				i_7 : in  std_logic;
				i_S : in  std_logic_vector(2 downto 0);
				o_Z : out std_logic
				);
	end component;
begin
	MUX8_1_array: for bit_index in 0 to m_width-1 generate
		u_MUX8_1 : myMUX8_1
		port map (i_0 => i_0(bit_index),
					 i_1 => i_1(bit_index),
					 i_2 => i_2(bit_index),
					 i_3 => i_3(bit_index),
					 i_4 => i_4(bit_index),
					 i_5 => i_5(bit_index),
					 i_6 => i_6(bit_index),
					 i_7 => i_7(bit_index),
					 i_S => i_S,
					 o_Z => o_Z(bit_index));
	end generate MUX8_1_array;
end a_myMUX8_N;