--| MUX16_N
--| 16 input, N-bit multiplexer
--|
--| INPUTS:
--| i_0  - Input 0
--| i_1  - Input 1
--| i_2  - Input 2
--| i_3  - Input 3
--| i_4  - Input 4
--| i_5  - Input 5
--| i_6  - Input 6
--| i_7  - Input 7
--| i_8  - Input 8
--| i_9  - Input 9
--| i_10 - Input 10
--| i_11 - Input 11
--| i_12 - Input 12
--| i_13 - Input 13
--| i_14 - Input 14
--| i_15 - Input 15
--| i_S - Select input
--|
--| OUTPUTS:
--| o_Z - Output the input corresponding the the decimal representation of i_S
library IEEE;
use IEEE.std_logic_1164.all;

entity myMUX16_N is
	generic(m_width : integer := 32);  -- Number of bits in the inputs and output
	port (i_0	: in  std_logic_vector(m_width-1 downto 0);
			i_1	: in  std_logic_vector(m_width-1 downto 0);
			i_2	: in  std_logic_vector(m_width-1 downto 0);
			i_3	: in  std_logic_vector(m_width-1 downto 0);
			i_4	: in  std_logic_vector(m_width-1 downto 0);
			i_5	: in  std_logic_vector(m_width-1 downto 0);
			i_6	: in  std_logic_vector(m_width-1 downto 0);
			i_7	: in  std_logic_vector(m_width-1 downto 0);
			i_8	: in  std_logic_vector(m_width-1 downto 0);
			i_9	: in  std_logic_vector(m_width-1 downto 0);
			i_10	: in  std_logic_vector(m_width-1 downto 0);
			i_11	: in  std_logic_vector(m_width-1 downto 0);
			i_12	: in  std_logic_vector(m_width-1 downto 0);
			i_13	: in  std_logic_vector(m_width-1 downto 0);
			i_14	: in  std_logic_vector(m_width-1 downto 0);
			i_15	: in  std_logic_vector(m_width-1 downto 0);
			i_S	: in  std_logic_vector(3 downto 0);
			o_Z	: out std_logic_vector(m_width-1 downto 0));
end myMUX16_N;

architecture a_myMUX16_N of myMUX16_N is
--| Declare components
	component myMUX16_1 is
		port (i_0 : in  std_logic;
				i_1 : in  std_logic;
				i_2 : in  std_logic;
				i_3 : in  std_logic;
				i_4 : in  std_logic;
				i_5 : in  std_logic;
				i_6 : in  std_logic;
				i_7 : in  std_logic;
				i_8 : in  std_logic;
				i_9 : in  std_logic;
				i_10 : in  std_logic;
				i_11 : in  std_logic;
				i_12 : in  std_logic;
				i_13 : in  std_logic;
				i_14 : in  std_logic;
				i_15 : in  std_logic;
				i_S : in  std_logic_vector(3 downto 0);
				o_Z : out std_logic
				);
	end component;
begin
	MUX16_1_array: for bit_index in 0 to m_width-1 generate
		u_MUX16_1 : myMUX16_1
		port map (i_0 => i_0(bit_index),
					 i_1 => i_1(bit_index),
					 i_2 => i_2(bit_index),
					 i_3 => i_3(bit_index),
					 i_4 => i_4(bit_index),
					 i_5 => i_5(bit_index),
					 i_6 => i_6(bit_index),
					 i_7 => i_7(bit_index),
					 i_8 => i_8(bit_index),
					 i_9 => i_9(bit_index),
					 i_10 => i_10(bit_index),
					 i_11 => i_11(bit_index),
					 i_12 => i_12(bit_index),
					 i_13 => i_13(bit_index),
					 i_14 => i_14(bit_index),
					 i_15 => i_15(bit_index),
					 i_S => i_S,
					 o_Z => o_Z(bit_index));
	end generate MUX16_1_array;
end a_myMUX16_N;