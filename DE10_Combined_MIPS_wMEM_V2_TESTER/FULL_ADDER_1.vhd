--| FULL_ADDER_1.vhd
--| Single bit full adder
--| Add two 1-bit numbers along with a carry in bit.  Produce
--| a 1-bit sum and a carry out bit.
--|
--| INPUTS:
--| i_A			- Input A
--| i_A_n		- Inverted input A
--| i_B			- Input B
--| i_B_n		- Inverted input B
--| i_AB_AND	- AND(A,B)
--| i_AB_NAND	- NAND(A,B)
--| i_AB_NOR	- NOR(A,B)
--| i_C			- Carry In
--|
--| OUTPUTS:
--| o_S			- i_A+i_B+i_C (sum)
--| o_C			- 1 if (i_A)(i_B) OR (i_A)(i_C) OR (i_B)(i_C) and 0 otherwise
library IEEE;
use IEEE.std_logic_1164.all;

entity FULL_ADDER_1 is
	port (i_A			: in  std_logic;
			i_A_n			: in  std_logic;
			i_B			: in  std_logic;
			i_B_n			: in  std_logic;
			i_AB_AND		: in  std_logic;
			i_AB_NAND	: in  std_logic;
			i_AB_NOR		: in  std_logic;
			i_C			: in  std_logic;
			o_S			: out std_logic;
			o_C			: out std_logic);
end FULL_ADDER_1;

architecture a_FULL_ADDER_1 of FULL_ADDER_1 is
--| Declare components
	component myNAND2 is
		port (i_A : in  std_logic;
				i_B : in  std_logic;
				o_Z : out std_logic
				);
	end component;
	
	component myINV is
		port (i_A : in  std_logic;
				o_Z : out std_logic);
	end component;
--| Declare signals
	
	-- Inverted Inputs
	signal w_C_n : std_logic;
	
	-- Intermediate Signals
	signal w_add_01 : std_logic;
	signal w_add_02 : std_logic;
	signal w_add_03, w_add_03_n : std_logic;
	signal w_add_05, w_add_05_n : std_logic;
	signal w_add_06, w_add_06_n : std_logic;
	signal w_add_07 : std_logic;
	signal w_add_08 : std_logic;
	signal w_add_09 : std_logic;
	signal w_add_10 : std_logic;
	signal w_add_11, w_add_11_n : std_logic;
	signal w_add_12, w_add_12_n : std_logic;
begin
	
	--| INV(i_C)
	u_myINV_C: myINV
	port map (i_A => i_C,
				 o_Z => w_C_n);
	--| Create Inverted Intermediate Signals
	u_myINV_03: myINV
	port map (i_A => w_add_03,
				 o_Z => w_add_03_n);
				 
	u_myINV_05: myINV
	port map (i_A => w_add_05,
				 o_Z => w_add_05_n);
				 
	u_myINV_06: myINV
	port map (i_A => w_add_06,
				 o_Z => w_add_06_n);
				 
	u_myINV_11: myINV
	port map (i_A => w_add_11,
				 o_Z => w_add_11_n);
				 
	u_myINV_12: myINV
	port map (i_A => w_add_12,
				 o_Z => w_add_12_n);
				 
	u_myNAND2_01: myNAND2
	port map (i_A => i_A,
				 i_B => i_C,
				 o_Z => w_add_01);
				 
	u_myNAND2_02: myNAND2
	port map (i_A => i_B,
				 i_B => i_C,
				 o_Z => w_add_02);
				 
	u_myNAND2_03: myNAND2
	port map (i_A => i_AB_NAND,
				 i_B => w_add_01,
				 o_Z => w_add_03);
	
	u_myNAND2_05: myNAND2
	port map (i_A => i_A_n,
				 i_B => i_B,
				 o_Z => w_add_05);
				 
	u_myNAND2_06: myNAND2
	port map (i_A => i_A,
				 i_B => i_B_n,
				 o_Z => w_add_06);
				 
	u_myNAND2_07: myNAND2
	port map (i_A => i_AB_NOR,
				 i_B => i_C,
				 o_Z => w_add_07);
				 
	u_myNAND2_08: myNAND2
	port map (i_A => w_add_05_n,
				 i_B => w_C_n,
				 o_Z => w_add_08);
				 
	u_myNAND2_09: myNAND2
	port map (i_A => w_add_06_n,
				 i_B => w_C_n,
				 o_Z => w_add_09);
				 
	u_myNAND2_10: myNAND2
	port map (i_A => i_AB_AND,
				 i_B => i_C,
				 o_Z => w_add_10);
				 
	u_myNAND2_11: myNAND2
	port map (i_A => w_add_07,
				 i_B => w_add_08,
				 o_Z => w_add_11);
				 
	u_myNAND2_12: myNAND2
	port map (i_A => w_add_09,
				 i_B => w_add_10,
				 o_Z => w_add_12);
	
	--| Generate Outputs
	u_myNAND2_S: myNAND2
	port map (i_A => w_add_11_n,
				 i_B => w_add_12_n,
				 o_Z => o_S);
				 
	u_myNAND2_CO: myNAND2
	port map (i_A => w_add_03_n,
				 i_B => w_add_02,
				 o_Z => o_C);
	
end a_FULL_ADDER_1;