--| myRegN.vhd
--| N-bit register
--|
--| INPUTS:
--| i_clk	- Clock
--| i_reset	- Reset
--| i_D		- Data
--|
--| OUTPUTS:
--| o_Q - Output
library IEEE;
use IEEE.std_logic_1164.all;

entity myRegN is
	generic(m_width : integer := 32);  -- Number of bits in the inputs and output
	port (i_clk		: in  std_logic;
			i_reset	: in  std_logic;
			i_D		: in  std_logic_vector(m_width-1 downto 0);
			o_Q		: out std_logic_vector(m_width-1 downto 0));
end myRegN;

architecture a_myRegN of myRegN is	
--| Declare Components
	component myReg1 is
		port (i_clk		: in  std_logic;
				i_reset	: in  std_logic;
				i_D		: in  std_logic;
				o_Q		: out std_logic);
	end component;

begin
	reg_array: for bit_index in 0 to m_width-1 generate
		u_myReg1 : myReg1
		port map (i_clk => i_clk,
					 i_reset => i_reset,
					 i_D => i_D(bit_index),
					 o_Q => o_Q(bit_index));
	end generate reg_array;
end a_myRegN;