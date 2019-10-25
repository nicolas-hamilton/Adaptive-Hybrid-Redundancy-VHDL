--| MUX32_N
--| 32 input, N-bit multiplexer
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
--| i_16 - Input 16
--| i_17 - Input 17
--| i_18 - Input 18
--| i_19 - Input 19
--| i_20 - Input 20
--| i_21 - Input 21
--| i_22 - Input 22
--| i_23 - Input 23
--| i_24 - Input 24
--| i_25 - Input 25
--| i_26 - Input 26
--| i_27 - Input 27
--| i_28 - Input 28
--| i_29 - Input 29
--| i_30 - Input 30
--| i_31 - Input 31
--| i_S - Select input
--|
--| OUTPUTS:
--| o_Z - Output the input corresponding the the decimal representation of i_S
library IEEE;
use IEEE.std_logic_1164.all;

entity myMUX32_N is
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
			i_16	: in  std_logic_vector(m_width-1 downto 0);
			i_17	: in  std_logic_vector(m_width-1 downto 0);
			i_18	: in  std_logic_vector(m_width-1 downto 0);
			i_19	: in  std_logic_vector(m_width-1 downto 0);
			i_20	: in  std_logic_vector(m_width-1 downto 0);
			i_21	: in  std_logic_vector(m_width-1 downto 0);
			i_22	: in  std_logic_vector(m_width-1 downto 0);
			i_23	: in  std_logic_vector(m_width-1 downto 0);
			i_24	: in  std_logic_vector(m_width-1 downto 0);
			i_25	: in  std_logic_vector(m_width-1 downto 0);
			i_26	: in  std_logic_vector(m_width-1 downto 0);
			i_27	: in  std_logic_vector(m_width-1 downto 0);
			i_28	: in  std_logic_vector(m_width-1 downto 0);
			i_29	: in  std_logic_vector(m_width-1 downto 0);
			i_30	: in  std_logic_vector(m_width-1 downto 0);
			i_31	: in  std_logic_vector(m_width-1 downto 0);
			i_S	: in  std_logic_vector(4 downto 0);
			o_Z	: out std_logic_vector(m_width-1 downto 0));
end myMUX32_N;

architecture a_myMUX32_N of myMUX32_N is
--| Declare components
	component myMUX32_1 is
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
				i_16 : in  std_logic;
				i_17 : in  std_logic;
				i_18 : in  std_logic;
				i_19 : in  std_logic;
				i_20 : in  std_logic;
				i_21 : in  std_logic;
				i_22 : in  std_logic;
				i_23 : in  std_logic;
				i_24 : in  std_logic;
				i_25 : in  std_logic;
				i_26 : in  std_logic;
				i_27 : in  std_logic;
				i_28 : in  std_logic;
				i_29 : in  std_logic;
				i_30 : in  std_logic;
				i_31 : in  std_logic;
				i_S : in  std_logic_vector(4 downto 0);
				o_Z : out std_logic
				);
	end component;
begin
	MUX32_1_array: for bit_index in 0 to m_width-1 generate
		u_MUX32_1 : myMUX32_1
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
					 i_16 => i_16(bit_index),
					 i_17 => i_17(bit_index),
					 i_18 => i_18(bit_index),
					 i_19 => i_19(bit_index),
					 i_20 => i_20(bit_index),
					 i_21 => i_21(bit_index),
					 i_22 => i_22(bit_index),
					 i_23 => i_23(bit_index),
					 i_24 => i_24(bit_index),
					 i_25 => i_25(bit_index),
					 i_26 => i_26(bit_index),
					 i_27 => i_27(bit_index),
					 i_28 => i_28(bit_index),
					 i_29 => i_29(bit_index),
					 i_30 => i_30(bit_index),
					 i_31 => i_31(bit_index),
					 i_S => i_S,
					 o_Z => o_Z(bit_index));
	end generate MUX32_1_array;
end a_myMUX32_N;