--| FULL_ADDER_1_TB
--| Tests FULL_ADDER_1
library IEEE;
use IEEE.std_logic_1164.all;

entity FULL_ADDER_1_TB is
end FULL_ADDER_1_TB;

architecture testbench of FULL_ADDER_1_TB is
	component FULL_ADDER_1 is
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
	end component;
	-- Declare signals
	signal w_A : std_logic := '0';
	signal w_A_n : std_logic;
	signal w_B : std_logic := '0';
	signal w_B_n : std_logic;
	signal w_AB_AND : std_logic;
	signal w_AB_NAND : std_logic;
	signal w_AB_NOR : std_logic;
	signal w_C : std_logic := '0';
	signal w_S : std_logic;
	signal w_Cout  : std_logic;
begin
	-- Connect input wires
	w_A_n <= NOT w_A;
	w_B_n <= NOT w_B;
	w_AB_AND <= w_A AND w_B;
	w_AB_NAND <= NOT w_AB_AND;
	w_AB_NOR <= NOT (w_A OR w_B);
	
	-- Connect FULL_ADDER_1
	u_FULL_ADDER_1: FULL_ADDER_1
	port map (i_A => w_A,
				 i_A_n => w_A_n,
				 i_B => w_B,
				 i_B_n => w_B_n,
				 i_AB_AND => w_AB_AND,
				 i_AB_NAND => w_AB_NAND,
				 i_AB_NOR => w_AB_NOR,
				 i_C => w_C,
				 o_S => w_S,
				 o_C => w_Cout);
	
	-- Process for stimulating inputs		 
	stimulus: process is
	begin
		wait for 20 ns;
		w_C <= '1';
		wait for 20 ns;
		w_C <= '0';
		w_B <= '1';
		wait for 20 ns;
		w_C <= '1';
		wait for 20 ns;
		w_C <= '0';
		w_B <= '0';
		w_A <= '1';
		wait for 20 ns;
		w_C <= '1';
		wait for 20 ns;
		w_C <= '0';
		w_B <= '1';
		wait for 20 ns;
		w_C <= '1';
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;