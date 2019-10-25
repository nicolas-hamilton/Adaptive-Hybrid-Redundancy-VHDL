--| Bitwise_Ops2_32
--| Performs the AND, OR, XOR, and NOR operations on inputs A and B
--|
--| INPUTS:
--| i_A - Input A
--| i_B - Input B
--|
--| OUTPUTS:
--| o_A_n - Inverted Input A
--| o_B_n - Inverted Input B
--| o_AND - AND(A,B)
--| o_OR  - OR(A,B)
--| o_XOR - XOR(A,B)
--| o_XNOR - XNOR(A,B) - Inverted XOR output
--| o_NOR - NOR(A,B)
library IEEE;
use IEEE.std_logic_1164.all;

entity Bitwise_Ops2_32 is
	port (i_A		: in  std_logic_vector(31 downto 0);
			i_B		: in  std_logic_vector(31 downto 0);
			o_A_n		: out std_logic_vector(31 downto 0);
			o_B_n 	: out std_logic_vector(31 downto 0);
			o_AND		: out std_logic_vector(31 downto 0);
			o_NAND	: out std_logic_vector(31 downto 0);
			o_OR		: out std_logic_vector(31 downto 0);
			o_XOR		: out std_logic_vector(31 downto 0);
			o_XNOR	: out std_logic_vector(31 downto 0);
			o_NOR		: out std_logic_vector(31 downto 0));
end Bitwise_Ops2_32;

architecture a_Bitwise_Ops2_32 of Bitwise_Ops2_32 is
--| Declare components
	component Bitwise_Ops2 is
		port (i_A		: in  std_logic;
				i_B		: in  std_logic;
				o_A_n		: out std_logic;
				o_B_n 	: out std_logic;
				o_AND		: out std_logic;
				o_NAND	: out std_logic;
				o_OR		: out std_logic;
				o_XOR		: out std_logic;
				o_XNOR	: out std_logic;
				o_NOR		: out std_logic);
	end component;
begin
	bit_wise_array: for bit_index in 0 to 31 generate
		u_bit_ops : Bitwise_Ops2
		port map (i_A => i_A(bit_index),
					 i_B => i_B(bit_index),
					 o_A_n => o_A_n(bit_index),
					 o_B_n => o_B_n(bit_index),
					 o_AND => o_AND(bit_index),
					 o_NAND => o_NAND(bit_index),
					 o_OR => o_OR(bit_index),
					 o_XOR => o_XOR(bit_index),
					 o_XNOR => o_XNOR(bit_index),
					 o_NOR => o_NOR(bit_index));
	end generate bit_wise_array;
end a_Bitwise_Ops2_32;