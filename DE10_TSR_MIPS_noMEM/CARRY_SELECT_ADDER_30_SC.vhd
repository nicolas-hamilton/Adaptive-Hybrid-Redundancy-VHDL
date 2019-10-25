--| CARRY_SELECT_ADDER_30_SC
--| Add two 30-bit numbers along with a carry in bit.  Produce
--| a 30-bit sum and a carry out bit.
--|
--| INPUTS:
--| i_A - Input A
--| i_B - Input B
--| i_A_n - Inverted input A
--| i_B_n - Inverted input B
--| i_AB_AND - AND(A,B)
--| i_AB_NAND - NOT(AND(A,B))
--| i_AB_NOR - NOT(OR(A,B))
--| i_C - Carry In
--|
--| OUTPUTS:
--| o_S - i_A+i_B+i_C (sum)
--| o_C - Carry Out
library IEEE;
use IEEE.std_logic_1164.all;

entity CARRY_SELECT_ADDER_30_SC is
	port (i_A			: in  std_logic_vector(29 downto 0);
			i_B			: in  std_logic_vector(29 downto 0);
			i_C			: in  std_logic;
			o_S			: out std_logic_vector(29 downto 0);
			o_C			: out std_logic);
end CARRY_SELECT_ADDER_30_SC;

architecture a_CARRY_SELECT_ADDER_30_SC of CARRY_SELECT_ADDER_30_SC is
--| Declare components
	component CARRY_SELECT_ADDER_4_SC is
		port (i_A			: in  std_logic_vector(3 downto 0);
				i_B			: in  std_logic_vector(3 downto 0);
				i_C			: in  std_logic;
				o_S			: out std_logic_vector(3 downto 0);
				o_C			: out std_logic);
	end component;
	
	component CARRY_SELECT_ADDER_2_SC is
		port (i_A			: in  std_logic_vector(1 downto 0);
				i_B			: in  std_logic_vector(1 downto 0);
				i_C			: in  std_logic;
				o_S			: out std_logic_vector(1 downto 0);
				o_C			: out std_logic);
	end component;
	
--| Declare signals
	signal w_C1 : std_logic; -- Carry out from CARRY_SELECT_ADDER 0 to CARRY_SELECT_ADDER 1
	signal w_C2 : std_logic; -- Carry out from CARRY_SELECT_ADDER 1 to CARRY_SELECT_ADDER 2
	signal w_C3 : std_logic; -- Carry out from CARRY_SELECT_ADDER 2 to CARRY_SELECT_ADDER 3
	signal w_C4 : std_logic; -- Carry out from CARRY_SELECT_ADDER 3 to CARRY_SELECT_ADDER 4
	signal w_C5 : std_logic; -- Carry out from CARRY_SELECT_ADDER 4 to CARRY_SELECT_ADDER 5
	signal w_C6 : std_logic; -- Carry out from CARRY_SELECT_ADDER 5 to CARRY_SELECT_ADDER 6
	signal w_C7 : std_logic; -- Carry out from CARRY_SELECT_ADDER 6 to CARRY_SELECT_ADDER 7
begin
	-- Connect CARRY_SELECT_ADDERs
	u_CARRY_SELECT_ADDER_0: CARRY_SELECT_ADDER_4_SC
	port map (i_A => i_A(3 downto 0),
				 i_B => i_B(3 downto 0),
				 i_C => i_C,
				 o_S => o_S(3 downto 0),
				 o_C => w_C1);

	u_CARRY_SELECT_ADDER_1: CARRY_SELECT_ADDER_4_SC
	port map (i_A => i_A(7 downto 4),
				 i_B => i_B(7 downto 4),
				 i_C => w_C1,
				 o_S => o_S(7 downto 4),
				 o_C => w_C2);
	
	u_CARRY_SELECT_ADDER_2: CARRY_SELECT_ADDER_4_SC
	port map (i_A => i_A(11 downto 8),
				 i_B => i_B(11 downto 8),
				 i_C => w_C2,
				 o_S => o_S(11 downto 8),
				 o_C => w_C3);

	u_CARRY_SELECT_ADDER_3: CARRY_SELECT_ADDER_4_SC
	port map (i_A => i_A(15 downto 12),
				 i_B => i_B(15 downto 12),
				 i_C => w_C3,
				 o_S => o_S(15 downto 12),
				 o_C => w_C4);
				 
	u_CARRY_SELECT_ADDER_4_SC: CARRY_SELECT_ADDER_4_SC
	port map (i_A => i_A(19 downto 16),
				 i_B => i_B(19 downto 16),
				 i_C => w_C4,
				 o_S => o_S(19 downto 16),
				 o_C => w_C5);
				 
	u_CARRY_SELECT_ADDER_5: CARRY_SELECT_ADDER_4_SC
	port map (i_A => i_A(23 downto 20),
				 i_B => i_B(23 downto 20),
				 i_C => w_C5,
				 o_S => o_S(23 downto 20),
				 o_C => w_C6);
				 
	u_CARRY_SELECT_ADDER_6: CARRY_SELECT_ADDER_4_SC
	port map (i_A => i_A(27 downto 24),
				 i_B => i_B(27 downto 24),
				 i_C => w_C6,
				 o_S => o_S(27 downto 24),
				 o_C => w_C7);
				 
	u_CARRY_SELECT_ADDER_7: CARRY_SELECT_ADDER_2_SC
	port map (i_A => i_A(29 downto 28),
				 i_B => i_B(29 downto 28),
				 i_C => w_C7,
				 o_S => o_S(29 downto 28),
				 o_C => o_C);
end a_CARRY_SELECT_ADDER_30_SC;