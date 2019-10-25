--| myINV_N_N_TB
--| Tests myINV_N
library IEEE;
use IEEE.std_logic_1164.all;

entity myINV_N_TB is
end myINV_N_TB;

architecture testbench of myINV_N_TB is
	component myINV_N is
		generic (m_width : integer := 32);
		port (i_A : in  std_logic_vector(m_width-1 downto 0);
				o_Z : out std_logic_vector(m_width-1 downto 0)
				);
	end component;
	-- Declare signals
	signal w_A : std_logic_vector(31 downto 0) := (others => '0');
	signal w_Z : std_logic_vector(31 downto 0);
begin
	-- Connect myNAND2
	u_myINV_N: myINV_N
	generic map(m_width => 32)
	port map (i_A => w_A,
				 o_Z => w_Z);
	
	-- Process for stimulating inputs		 
	stimulus: process is
	begin
		wait for 20 ns;
		w_A <= B"1111_0000_1111_0000_1111_0000_1111_0000";
		wait for 20 ns;
		w_A <= B"1111_1111_1111_1111_1111_1111_1111_1111";
		wait for 20 ns;
		w_A <= B"0000_0000_0000_0000_0000_0000_0000_0000";
		wait for 20 ns;
		w_A <= B"0000_0001_0010_0011_0100_0101_0110_0111";
		wait for 20 ns;
		w_A <= B"1000_1001_1010_1011_1100_1101_1110_1111";
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;