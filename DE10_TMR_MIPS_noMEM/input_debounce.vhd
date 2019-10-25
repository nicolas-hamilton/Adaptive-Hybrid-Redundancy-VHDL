--| input_debounce.vhd
--| 1-bit register
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

entity input_debounce is
	port (i_clk		: in  std_logic;
			i_reset	: in  std_logic;
			i_D		: in  std_logic;
			o_Q		: out std_logic);
end input_debounce;

architecture a_input_debounce of input_debounce is	
	--| Declare Components
	component myNAND2 is
		port (i_A : in  std_logic;
				i_B : in  std_logic;
				o_Z : out std_logic);
	end component;

	component myINV is
		port (i_A : in  std_logic;
				o_Z : out std_logic);
	end component;
	
	component myReg1 is
		port (i_clk		: in  std_logic;
				i_reset	: in  std_logic;
				i_D		: in  std_logic;
				o_Q		: out std_logic);
	end component;
	
	component myMUX2_1 is
		port (i_0 : in  std_logic;
				i_1 : in  std_logic;
				i_S : in  std_logic;
				o_Z : out std_logic);
	end component;
	--| Declare signals
	signal w_Dn		: std_logic; -- Inverted input
	signal w_0		: std_logic; -- Input delayed by 1 clock cylce
	signal w_1		: std_logic; -- Input delayed by 2 clock cylces
	signal w_2		: std_logic; -- Input delayed by 3 clock cylces
	signal w_3		: std_logic; -- Input delayed by 4 clock cylces
	signal w_4		: std_logic; -- Input delayed by 5 clock cylces
	signal w_5		: std_logic; -- NAND(w_Dn,w_0n)
	signal w_6		: std_logic; -- NAND(w_1n,w_2n)
	signal w_7		: std_logic; -- NAND(w_3n,w_4n)
	signal w_8		: std_logic; -- NAND(w_D,w_0n)
	signal w_9		: std_logic; -- NAND(w_1,w_2)
	signal w_10		: std_logic; -- NAND(w_3,w_4)
	signal w_11 	: std_logic; -- NAND(w_5n,w_6n)
	signal w_12 	: std_logic; -- NAND(w_8n,w_9n)
	signal w_13 	: std_logic; -- NAND(w_11n,w_7n)
	signal w_14 	: std_logic; -- NAND(w_12n,w_10n)
	signal w_15		: std_logic; -- NAND(w_13,w_14) - input to MUX
	signal w_16		: std_logic; -- Input to output flip-flop
	signal w_0n		: std_logic; -- Input delayed by 1 clock cylce inverted
	signal w_1n		: std_logic; -- Input delayed by 2 clock cylces inverted
	signal w_2n		: std_logic; -- Input delayed by 3 clock cylces inverted
	signal w_3n		: std_logic; -- Input delayed by 4 clock cylces inverted
	signal w_4n		: std_logic; -- Input delayed by 5 clock cylces inverted
	signal w_5n		: std_logic; -- INV(NAND(w_Dn,w_0n))
	signal w_6n		: std_logic; -- INV(NAND(w_1n,w_2n))
	signal w_7n		: std_logic; -- INV(NAND(w_3n,w_4n))
	signal w_8n		: std_logic; -- INV(NAND(w_D,w_0n))
	signal w_9n		: std_logic; -- INV(NAND(w_1,w_2))
	signal w_10n	: std_logic; -- INV(NAND(w_3,w_4))
	signal w_11n 	: std_logic; -- INV(NAND(w_5n,w_6n))
	signal w_12n 	: std_logic; -- INV(NAND(w_8n,w_9n))
	signal w_Q		: std_logic; -- Output flip-flop
begin
	o_Q <= w_Q;
	u_myINV_D: myINV
	port map (i_A => i_D,
				 o_Z => w_Dn);
	
	u_myINV_0: myINV
	port map (i_A => w_0,
				 o_Z => w_0n);
	
	u_myINV_1: myINV
	port map (i_A => w_1,
				 o_Z => w_1n);
	
	u_myINV_2: myINV
	port map (i_A => w_2,
				 o_Z => w_2n);
	
	u_myINV_3: myINV
	port map (i_A => w_3,
				 o_Z => w_3n);
	
	u_myINV_4: myINV
	port map (i_A => w_4,
				 o_Z => w_4n);
	
	u_myINV_5: myINV
	port map (i_A => w_5,
				 o_Z => w_5n);
	
	u_myINV_6: myINV
	port map (i_A => w_6,
				 o_Z => w_6n);
	
	u_myINV_7: myINV
	port map (i_A => w_7,
				 o_Z => w_7n);
	
	u_myINV_8: myINV
	port map (i_A => w_8,
				 o_Z => w_8n);
	
	u_myINV_9: myINV
	port map (i_A => w_9,
				 o_Z => w_9n);
	
	u_myINV_10: myINV
	port map (i_A => w_10,
				 o_Z => w_10n);
	
	u_myINV_11: myINV
	port map (i_A => w_11,
				 o_Z => w_11n);
	
	u_myINV_12: myINV
	port map (i_A => w_12,
				 o_Z => w_12n);
	
	u_myNAND_5: myNAND2
	port map (i_A => w_Dn,
				 i_B => w_0n,
				 o_Z => w_5);
	
	u_myNAND_6: myNAND2
	port map (i_A => w_1n,
				 i_B => w_2n,
				 o_Z => w_6);
	
	u_myNAND_7: myNAND2
	port map (i_A => w_3n,
				 i_B => w_4n,
				 o_Z => w_7);
	
	u_myNAND_8: myNAND2
	port map (i_A => i_D,
				 i_B => w_0,
				 o_Z => w_8);
	
	u_myNAND_9: myNAND2
	port map (i_A => w_1,
				 i_B => w_2,
				 o_Z => w_9);
	
	u_myNAND_10: myNAND2
	port map (i_A => w_3,
				 i_B => w_4,
				 o_Z => w_10);
	
	u_myNAND_11: myNAND2
	port map (i_A => w_5n,
				 i_B => w_6n,
				 o_Z => w_11);
	
	u_myNAND_12: myNAND2
	port map (i_A => w_8n,
				 i_B => w_9n,
				 o_Z => w_12);
	
	u_myNAND_13: myNAND2
	port map (i_A => w_11n,
				 i_B => w_7n,
				 o_Z => w_13);
	
	u_myNAND_14: myNAND2
	port map (i_A => w_12n,
				 i_B => w_10n,
				 o_Z => w_14);
	
	u_myNAND_15: myNAND2
	port map (i_A => w_13,
				 i_B => w_14,
				 o_Z => w_15);

	u_myReg1_0: myReg1
	port map (i_clk => i_clk,
				 i_reset => i_reset,
				 i_D => i_D,
				 o_Q => w_0);

	u_myReg1_1: myReg1
	port map (i_clk => i_clk,
				 i_reset => i_reset,
				 i_D => w_0,
				 o_Q => w_1);

	u_myReg1_2: myReg1
	port map (i_clk => i_clk,
				 i_reset => i_reset,
				 i_D => w_1,
				 o_Q => w_2);

	u_myReg1_3: myReg1
	port map (i_clk => i_clk,
				 i_reset => i_reset,
				 i_D => w_2,
				 o_Q => w_3);

	u_myReg1_4: myReg1
	port map (i_clk => i_clk,
				 i_reset => i_reset,
				 i_D => w_3,
				 o_Q => w_4);

	u_myMux2_1_out: myMUX2_1
	port map (i_0 => w_Q,
				 i_1 => w_4,
				 i_S => w_15,
				 o_Z => w_16);
				 
	u_myReg1_out: myReg1
	port map (i_clk => i_clk,
				 i_reset => i_reset,
				 i_D => w_16,
				 o_Q => w_Q);
end a_input_debounce;