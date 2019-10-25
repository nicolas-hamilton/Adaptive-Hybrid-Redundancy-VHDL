--| FULL_ADDER_2_SC.vhd
--| Self contained 2-bit full adder
--| Add two 2-bit numbers along with a carry in bit.  Produce
--| a 2-bit sum and a carry out bit.
--|
--| INPUTS:
--| i_A - Input A
--| i_B - Input B
--| i_C - Carry In
--|
--| OUTPUTS:
--| o_S - i_A+i_B+i_C (sum)
--| o_C - Carry Out
library IEEE;
use IEEE.std_logic_1164.all;

entity FULL_ADDER_2_SC is
	port (i_A			: in  std_logic_vector(1 downto 0);
			i_B			: in  std_logic_vector(1 downto 0);
			i_C			: in  std_logic;
			o_S			: out std_logic_vector(1 downto 0);
			o_C			: out std_logic);
end FULL_ADDER_2_SC;

architecture a_FULL_ADDER_2_SC of FULL_ADDER_2_SC is
--| Declare components
	component FULL_ADDER_1_SC is
		port (i_A			: in  std_logic;
				i_B			: in  std_logic;
				i_C			: in  std_logic;
				o_S			: out std_logic;
				o_C			: out std_logic);
	end component;
--| Declare signals
	signal w_C1 : std_logic; -- Carry out from bit 0 addition to bit 1 addition
	signal w_C2 : std_logic; -- Carry out from bit 1 addition to bit 2 addition
	signal w_C3 : std_logic; -- Carry out from bit 3 addition to bit 4 addition
	
begin				 
	-- Bit 0 Full Adder
	u_FULL_ADD_0: FULL_ADDER_1_SC
	port map (i_A => i_A(0),
				 i_B => i_B(0),
				 i_C => i_C,
				 o_S => o_S(0),
				 o_C => w_C1);
				 
	-- Bit 1 Full Adder
	u_FULL_ADD_1: FULL_ADDER_1_SC
	port map (i_A => i_A(1),
				 i_B => i_B(1),
				 i_C => w_C1,
				 o_S => o_S(1),
				 o_C => o_C);
end a_FULL_ADDER_2_SC;