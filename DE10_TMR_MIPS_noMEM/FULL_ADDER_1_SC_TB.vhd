--| FULL_ADDER_1_SC_TB
--| Tests FULL_ADDER_1_SC
library IEEE;
use IEEE.std_logic_1164.all;

entity FULL_ADDER_1_SC_TB is
end FULL_ADDER_1_SC_TB;

architecture testbench of FULL_ADDER_1_SC_TB is
	component FULL_ADDER_1_SC is
		port (i_A			: in  std_logic;
				i_B			: in  std_logic;
				i_C			: in  std_logic;
				o_S			: out std_logic;
				o_C			: out std_logic);
	end component;
	-- Declare signals
	signal w_A : std_logic := '0';
	signal w_B : std_logic := '0';
	signal w_C : std_logic := '0';
	signal w_S : std_logic;
	signal w_Cout  : std_logic;
begin
	-- Connect FULL_ADDER_1_SC
	u_FULL_ADDER_1_SC: FULL_ADDER_1_SC
	port map (i_A => w_A,
				 i_B => w_B,
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