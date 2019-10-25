--| FULL_ADDER_4_SC.vhd
--| Self Contained 4-bit full adder
--| Add two 4-bit numbers along with a carry in bit.  Produce
--| a 4-bit sum and a carry out bit.
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

entity FULL_ADDER_4_SC is
	port (i_A			: in  std_logic_vector(3 downto 0);
			i_B			: in  std_logic_vector(3 downto 0);
			i_C			: in  std_logic;
			o_S			: out std_logic_vector(3 downto 0);
			o_C			: out std_logic);
end FULL_ADDER_4_SC;

architecture a_FULL_ADDER_4_SC of FULL_ADDER_4_SC is
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
				 o_C => w_C2);
				 
	-- Bit 2 Full Adder
	u_FULL_ADD_2: FULL_ADDER_1_SC
	port map (i_A => i_A(2),
				 i_B => i_B(2),
				 i_C => w_C2,
				 o_S => o_S(2),
				 o_C => w_C3);
				 
	-- Bit 3 Full Adder
	u_FULL_ADD_3: FULL_ADDER_1_SC
	port map (i_A => i_A(3),
				 i_B => i_B(3),
				 i_C => w_C3,
				 o_S => o_S(3),
				 o_C => o_C);
	
end a_FULL_ADDER_4_SC;