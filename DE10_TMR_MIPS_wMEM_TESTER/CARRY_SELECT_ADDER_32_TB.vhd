--| CARRY_SELECT_ADDER_32_TB
--| Tests CARRY_SELECT_ADDER_32
library IEEE;
use IEEE.std_logic_1164.all;

entity CARRY_SELECT_ADDER_32_TB is
end CARRY_SELECT_ADDER_32_TB;

architecture testbench of CARRY_SELECT_ADDER_32_TB is
	component CARRY_SELECT_ADDER_32 is
		port (i_A			: in  std_logic_vector(31 downto 0);
				i_A_n			: in  std_logic_vector(31 downto 0);
				i_B			: in  std_logic_vector(31 downto 0);
				i_B_n			: in  std_logic_vector(31 downto 0);
				i_AB_AND		: in  std_logic_vector(31 downto 0);
				i_AB_NAND	: in  std_logic_vector(31 downto 0);
				i_AB_NOR		: in  std_logic_vector(31 downto 0);
				i_C			: in  std_logic;
				o_S			: out std_logic_vector(31 downto 0);
				o_C			: out std_logic);
	end component;
	-- Declare signals
	signal w_A : std_logic_vector(31 downto 0) := (others =>'0');
	signal w_A_n : std_logic_vector(31 downto 0);
	signal w_B : std_logic_vector(31 downto 0) := (others =>'0');
	signal w_B_n : std_logic_vector(31 downto 0);
	signal w_AB_AND : std_logic_vector(31 downto 0);
	signal w_AB_NAND : std_logic_vector(31 downto 0);
	signal w_AB_NOR : std_logic_vector(31 downto 0);
	signal w_C : std_logic := '0';
	signal w_S : std_logic_vector(31 downto 0);
	signal w_Cout  : std_logic;
	
begin
	-- Connect input wires
	
	w_A_n <= NOT w_A;
	w_B_n <= NOT w_B;
	w_AB_AND <= w_A AND w_B;
	w_AB_NAND <= NOT w_AB_AND;
	w_AB_NOR <= NOT (w_A OR w_B);
	-- Connect CARRY_SELECT_ADDER_32
	u_CARRY_SELECT_ADDER_32: CARRY_SELECT_ADDER_32
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
		w_A <= B"0000_0000_0000_0000_0000_0000_0000_1111";
		w_B <= B"0000_0000_0000_0000_0000_0000_0000_0001";
		wait for 20 ns;
		w_C <= '1';
		wait for 20 ns;
		w_A <= B"1111_1111_1111_1111_1111_1111_1111_1111";
		wait for 20 ns;
		w_C <= '0';
		wait for 20 ns;
		w_B <= B"0000_0000_0000_0000_0000_0000_0000_1111";
		wait for 20 ns;
		w_C <= '1';
		wait for 20 ns;
		w_A <= B"0000_0000_0000_0000_0000_0000_0000_1111";
		w_B <= B"0000_0000_0000_0000_0000_0000_1111_0000";
		wait;
	end process stimulus;
end testbench;