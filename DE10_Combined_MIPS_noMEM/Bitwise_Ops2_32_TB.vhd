--| Bitwise_Ops2_32_TB
--| Tests Bitwise_Ops2_32
library IEEE;
use IEEE.std_logic_1164.all;

entity Bitwise_Ops2_32_TB is
end Bitwise_Ops2_32_TB;

architecture testbench of Bitwise_Ops2_32_TB is
	component Bitwise_Ops2_32 is
		port (i_A		: in  std_logic_vector(31 downto 0);
				i_B		: in  std_logic_vector(31 downto 0);
				o_A_n		: out std_logic_vector(31 downto 0);
				o_B_n 	: out std_logic_vector(31 downto 0);
				o_AND		: out std_logic_vector(31 downto 0);
				o_NAND	: out std_logic_vector(31 downto 0);
				o_OR		: out std_logic_vector(31 downto 0);
				o_XOR		: out std_logic_vector(31 downto 0);
				o_XNOR	: out std_logic_vector(31 downto 0);
				o_NOR		: out std_logic_vector(31 downto 0));
	end component;
	-- Declare signals
	signal w_A : std_logic_vector(31 downto 0) := (others => '0');
	signal w_A_n : std_logic_vector(31 downto 0) := (others => '0');
	signal w_B : std_logic_vector(31 downto 0) := (others => '0');
	signal w_B_n : std_logic_vector(31 downto 0) := (others => '0');
	signal w_AND : std_logic_vector(31 downto 0);
	signal w_NAND : std_logic_vector(31 downto 0);
	signal w_OR  : std_logic_vector(31 downto 0);
	signal w_XOR : std_logic_vector(31 downto 0);
	signal w_XNOR : std_logic_vector(31 downto 0);
	signal w_NOR : std_logic_vector(31 downto 0);
begin
	-- Connect Bitwise_Ops2_32
	u_Bitwise_Ops2_32: Bitwise_Ops2_32
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
		w_A <= B"1111_1111_1111_1111_1111_1111_1111_1111";
		wait for 20 ns;
		w_B <= B"1111_1111_1111_1111_1111_1111_1111_1111";
		wait for 20 ns;
		w_A <= (others => '0');
		wait for 20 ns;
		w_A <= B"1010_1010_1010_1010_1010_1010_1010_1010";
		w_B <= B"0101_0101_0101_0101_0101_0101_0101_0101";
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;