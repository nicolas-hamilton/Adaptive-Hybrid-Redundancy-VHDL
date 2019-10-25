--| Bitwise_Ops2_TB
--| Tests Bitwise_Ops2
library IEEE;
use IEEE.std_logic_1164.all;

entity Bitwise_Ops2_TB is
end Bitwise_Ops2_TB;

architecture testbench of Bitwise_Ops2_TB is
	component Bitwise_Ops2 is
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
	end component;
	-- Declare signals
	signal w_A : std_logic := '0';
	signal w_A_n : std_logic := '0';
	signal w_B : std_logic := '0';
	signal w_B_n : std_logic := '0';
	signal w_AND : std_logic;
	signal w_NAND : std_logic;
	signal w_OR  : std_logic;
	signal w_XOR : std_logic;
	signal w_XNOR : std_logic;
	signal w_NOR : std_logic;
begin
	-- Connect Bitwise_Ops2
	u_Bitwise_Ops2: Bitwise_Ops2
	port map (i_A => w_A,
				 i_B => w_B,
				 o_A_n => w_A_n,
				 o_B_n => w_B_n,
				 o_AND => w_AND,
				 o_NAND => w_NAND,
				 o_OR => w_OR,
				 o_XOR => w_XOR,
				 o_XNOR => w_XNOR,
				 o_NOR => w_NOR);
	
	-- Process for stimulating inputs		 
	stimulus: process is
	begin
		wait for 20 ns;
		w_A <= '1';
		wait for 20 ns;
		w_B <= '1';
		wait for 20 ns;
		w_A <= '0';
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;