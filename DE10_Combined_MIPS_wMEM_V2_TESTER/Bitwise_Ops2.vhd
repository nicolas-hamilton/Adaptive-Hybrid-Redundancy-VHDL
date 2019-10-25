--| Bitwise_Ops2
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

entity Bitwise_Ops2 is
	port (i_A	: in  std_logic;
			i_B	: in  std_logic;
			o_A_n	: out std_logic;
			o_B_n : out std_logic;
			o_AND	: out std_logic;
			o_NAND: out std_logic;
			o_OR	: out std_logic;
			o_XOR	: out std_logic;
			o_XNOR	: out std_logic;
			o_NOR	: out std_logic);
end Bitwise_Ops2;

architecture a_Bitwise_Ops2 of Bitwise_Ops2 is
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
	signal w_A_n		: std_logic; -- INV(A)
	signal w_B_n		: std_logic; -- INV(B)
	signal w_AB_n		: std_logic; -- INV(AB) = NAND(A,B)
	signal w_A_B 		: std_logic; -- OR(A,B)
	signal w_xorAB_n	: std_logic; -- INV(XOR(A,B))
begin
	o_A_n <= w_A_n;
	o_B_n <= w_B_n;
	o_OR <= w_A_B;
	o_NAND <= w_AB_n;
	o_XNOR <= w_xorAB_n;
	--| INV(A)
	u_myINV_A: myINV
	port map (i_A => i_A,
				 o_Z => w_A_n);
	--| INV(B)
	u_myINV_B: myINV
	port map (i_A => i_B,
				 o_Z => w_B_n);
	--| NAND(A,B)
	u_myNAND2_AB_n: myNAND2
	port map (i_A => i_A,
				 i_B => i_B,
				 o_Z => w_AB_n);
	--| INV(NAND(A,B)) = AND(A,B)
	u_myINV_AB: myINV
	port map (i_A => w_AB_n,
				 o_Z => o_AND);
	--| NAND(INV(A),INV(B)) = OR(A,B)
	u_myNAND2_A_B: myNAND2
	port map (i_A => w_A_n,
				 i_B => w_B_n,
				 o_Z => w_A_B);
	--| INV(NAND(INV(A),INV(B))) = NOR(A,B)
	u_myINV_A_B_n: myINV
	port map (i_A => w_A_B,
				 o_Z => o_NOR);
	--| NAND(NAND(A,B),NOR(A,B)) = INV(XOR(A,B))
	u_myNAND2_XORAB_n: myNAND2
	port map (i_A => w_AB_n,
				 i_B => w_A_B,
				 o_Z => w_xorAB_n);
	--| XOR(A,B)
	u_myINV_XORAB: myINV
	port map (i_A => w_xorAB_n,
				 o_Z => o_XOR);
end a_Bitwise_Ops2;