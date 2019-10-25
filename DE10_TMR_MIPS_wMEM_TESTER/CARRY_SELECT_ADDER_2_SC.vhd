--| CARRY_SELECT_ADDER_2_SC
--| Self Contained 2-bit version of the 4-bit carry select adder
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

entity CARRY_SELECT_ADDER_2_SC is
	port (i_A			: in  std_logic_vector(1 downto 0);
			i_B			: in  std_logic_vector(1 downto 0);
			i_C			: in  std_logic;
			o_S			: out std_logic_vector(1 downto 0);
			o_C			: out std_logic);
end CARRY_SELECT_ADDER_2_SC;

architecture a_CARRY_SELECT_ADDER_2_SC of CARRY_SELECT_ADDER_2_SC is
--| Declare components
	component FULL_ADDER_2_SC is
		port (i_A			: in  std_logic_vector(1 downto 0);
				i_B			: in  std_logic_vector(1 downto 0);
				i_C			: in  std_logic;
				o_S			: out std_logic_vector(1 downto 0);
				o_C			: out std_logic);
	end component;
	
	component myMUX2_N is
		generic (m_width : integer := 4);
		port (i_0 : in  std_logic_vector(1 downto 0);
				i_1 : in  std_logic_vector(1 downto 0);
				i_S : in  std_logic;
				o_Z : out std_logic_vector(1 downto 0)
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
	signal w_S0 : std_logic_vector(1 downto 0); -- Sum from FULL_ADDER with 0 carry in
	signal w_S1 : std_logic_vector(1 downto 0); -- Sum from FULL_ADDER with 1 carry in
	signal w_C0, w_C0_n : std_logic; -- Carry out from FULL_ADDER with 0 carry in
	signal w_C1 : std_logic; -- Carry out from FULL_ADDER with 1 carry in
	signal w_C11 : std_logic; -- NAND(C1,i_C)
	
begin
	-- Connect FULL_ADDER_2_SC
	u_FULL_ADDER_0: FULL_ADDER_2_SC
	port map (i_A => i_A,
				 i_B => i_B,
				 i_C => k_zero,
				 o_S => w_S0,
				 o_C => w_C0);

	u_FULL_ADDER_1: FULL_ADDER_2_SC
	port map (i_A => i_A,
				 i_B => i_B,
				 i_C => k_one,
				 o_S => w_S1,
				 o_C => w_C1);
	
	u_myMUX2_2_S: myMUX2_N
	generic map (m_width => 2)
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
end a_CARRY_SELECT_ADDER_2_SC;