--| CARRY_SELECT_ADDER_2_SC_TB
--| Tests CARRY_SELECT_ADDER_2_SC
library IEEE;
use IEEE.std_logic_1164.all;

entity CARRY_SELECT_ADDER_2_SC_TB is
end CARRY_SELECT_ADDER_2_SC_TB;

architecture testbench of CARRY_SELECT_ADDER_2_SC_TB is
	component CARRY_SELECT_ADDER_2_SC is
		port (i_A			: in  std_logic_vector(1 downto 0);
				i_B			: in  std_logic_vector(1 downto 0);
				i_C			: in  std_logic;
				o_S			: out std_logic_vector(1 downto 0);
				o_C			: out std_logic);
	end component;
	-- Declare signals
	signal w_A : std_logic_vector(1 downto 0) := (others =>'0');
	signal w_B : std_logic_vector(1 downto 0) := (others =>'0');
	signal w_C : std_logic := '0';
	signal w_S : std_logic_vector(1 downto 0);
	signal w_Cout  : std_logic;
begin
	-- Connect CARRY_SELECT_ADDER_2_SC
	u_CARRY_SELECT_ADDER_2_SC: CARRY_SELECT_ADDER_2_SC
	port map (i_A => w_A,
				 i_B => w_B,
				 i_C => w_C,
				 o_S => w_S,
				 o_C => w_Cout);
	
	-- Process for stimulating inputs		 
	stimulus: process is
	begin
		wait for 20 ns;
		w_A <= B"01";
		wait for 20 ns;
		w_A <= B"10";
		wait for 20 ns;
		w_A <= B"11";
		wait for 20 ns;
		w_A <= B"00";
		w_B <= B"01";
		wait for 20 ns;
		w_A <= B"01";
		wait for 20 ns;
		w_A <= B"10";
		wait for 20 ns;
		w_A <= B"11";
		wait for 20 ns;
		w_A <= B"00";
		w_B <= B"10";
		wait for 20 ns;
		w_A <= B"01";
		wait for 20 ns;
		w_A <= B"10";
		wait for 20 ns;
		w_A <= B"11";
		wait for 20 ns;
		w_A <= B"00";
		w_B <= B"11";
		wait for 20 ns;
		w_A <= B"01";
		wait for 20 ns;
		w_A <= B"10";
		wait for 20 ns;
		w_A <= B"11";
		wait for 20 ns;
		w_A <= B"00";
		w_B <= B"00";
		w_C <= '1';
		wait for 20 ns;
		w_A <= B"01";
		wait for 20 ns;
		w_A <= B"10";
		wait for 20 ns;
		w_A <= B"11";
		wait for 20 ns;
		w_A <= B"00";
		w_B <= B"01";
		wait for 20 ns;
		w_A <= B"01";
		wait for 20 ns;
		w_A <= B"10";
		wait for 20 ns;
		w_A <= B"11";
		wait for 20 ns;
		w_A <= B"00";
		w_B <= B"10";
		wait for 20 ns;
		w_A <= B"01";
		wait for 20 ns;
		w_A <= B"10";
		wait for 20 ns;
		w_A <= B"11";
		wait for 20 ns;
		w_A <= B"00";
		w_B <= B"11";
		wait for 20 ns;
		w_A <= B"01";
		wait for 20 ns;
		w_A <= B"10";
		wait for 20 ns;
		w_A <= B"11";
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;