--| CARRY_SELECT_ADDER_4
--| Add two 4-bit numbers along with a carry in bit.  Produce
--| a 4-bit sum and a carry out bit.
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

entity CARRY_SELECT_ADDER_4 is
	port (i_A			: in  std_logic_vector(3 downto 0);
			i_A_n			: in  std_logic_vector(3 downto 0);
			i_B			: in  std_logic_vector(3 downto 0);
			i_B_n			: in  std_logic_vector(3 downto 0);
			i_AB_AND		: in  std_logic_vector(3 downto 0);
			i_AB_NAND	: in  std_logic_vector(3 downto 0);
			i_AB_NOR		: in  std_logic_vector(3 downto 0);
			i_C			: in  std_logic;
			o_S			: out std_logic_vector(3 downto 0);
			o_C			: out std_logic);
end CARRY_SELECT_ADDER_4;

architecture a_CARRY_SELECT_ADDER_4 of CARRY_SELECT_ADDER_4 is
--| Declare components
	component FULL_ADDER_4 is
		port (i_A			: in  std_logic_vector(3 downto 0);
				i_A_n			: in  std_logic_vector(3 downto 0);
				i_B			: in  std_logic_vector(3 downto 0);
				i_B_n			: in  std_logic_vector(3 downto 0);
				i_AB_AND		: in  std_logic_vector(3 downto 0);
				i_AB_NAND	: in  std_logic_vector(3 downto 0);
				i_AB_NOR		: in  std_logic_vector(3 downto 0);
				i_C			: in  std_logic;
				o_S			: out std_logic_vector(3 downto 0);
				o_C			: out std_logic);
	end component;
	
	component myMUX2_N is
		generic (m_width : integer := 4);
		port (i_0 : in  std_logic_vector(3 downto 0);
				i_1 : in  std_logic_vector(3 downto 0);
				i_S : in  std_logic;
				o_Z : out std_logic_vector(3 downto 0)
				);
	end component;

	component myNAND2 is
		port (i_A : in  std_logic;
				i_B : in  std_logic;
				o_Z : out std_logic
				);
	end component;

	component myINV is
		port (i_A : in  std_logic;
				o_Z : out std_logic
				);
	end component;
--| Declare Constants
	constant k_zero : std_logic := '0';
	constant k_one : std_logic := '1';

--| Declare signals
	signal w_S0 : std_logic_vector(3 downto 0); -- Sum from FULL_ADDER with 0 carry in
	signal w_S1 : std_logic_vector(3 downto 0); -- Sum from FULL_ADDER with 1 carry in
	signal w_C0, w_C0_n : std_logic; -- Carry out from FULL_ADDER with 0 carry in
	signal w_C1 : std_logic; -- Carry out from FULL_ADDER with 1 carry in
	signal w_C11 : std_logic; -- NAND(C1,i_C)
	
begin
	-- Connect FULL_ADDER_4
	u_FULL_ADDER_0: FULL_ADDER_4
	port map (i_A => i_A,
				 i_A_n => i_A_n,
				 i_B => i_B,
				 i_B_n => i_B_n,
				 i_AB_AND => i_AB_AND,
				 i_AB_NAND => i_AB_NAND,
				 i_AB_NOR => i_AB_NOR,
				 i_C => k_zero,
				 o_S => w_S0,
				 o_C => w_C0);

	u_FULL_ADDER_1: FULL_ADDER_4
	port map (i_A => i_A,
				 i_A_n => i_A_n,
				 i_B => i_B,
				 i_B_n => i_B_n,
				 i_AB_AND => i_AB_AND,
				 i_AB_NAND => i_AB_NAND,
				 i_AB_NOR => i_AB_NOR,
				 i_C => k_one,
				 o_S => w_S1,
				 o_C => w_C1);
	
	u_myMUX2_4_S: myMUX2_N
	generic map (m_width => 4)
	port map (i_0 => w_S0,
				 i_1 => w_S1,
				 i_S => i_C,
				 o_Z => o_S);
				 
	u_myINV_C0 : myINV
	port map (
		i_A => w_C0,
		o_Z => w_C0_n);
		
	u_myNAND_C11 : myNAND2
	port map (
		i_A => w_C1,
		i_B => i_C,
		o_Z => w_C11);
		
	u_myNAND_Cout : myNAND2
	port map (
		i_A => w_C11,
		i_B => w_C0_n,
		o_Z => o_C);
end a_CARRY_SELECT_ADDER_4;