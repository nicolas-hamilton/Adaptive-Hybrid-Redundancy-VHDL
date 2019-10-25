--| myMUX4_N_TB
--| Tests myMUX4_N
library IEEE;
use IEEE.std_logic_1164.all;

entity myMUX4_N_TB is
end myMUX4_N_TB;

architecture testbench of myMUX4_N_TB is
	-- Declare Components
	component myMUX4_N is
		generic (m_width : integer := 32);
		port (i_0 : in  std_logic_vector(31 downto 0);
				i_1 : in  std_logic_vector(31 downto 0);
				i_2 : in  std_logic_vector(31 downto 0);
				i_3 : in  std_logic_vector(31 downto 0);
				i_S : in  std_logic_vector(1 downto 0);
				o_Z : out std_logic_vector(31 downto 0)
				);
	end component;

	-- Declare signals
	signal w_0 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_0000_1111_1111";
	signal w_1 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_1111_1111_0000_0000";
	signal w_2 : std_logic_vector(31 downto 0) := B"0000_0000_1111_1111_0000_0000_0000_0000";
	signal w_3 : std_logic_vector(31 downto 0) := B"1111_1111_0000_0000_0000_0000_0000_0000";
	signal w_S : std_logic_vector(1 downto 0) := (others => '0');
	signal w_Z : std_logic_vector(31 downto 0);

begin	
	-- Connect myMUX4_N
	u_myMUX4_N: myMUX4_N
	generic map (m_width => 32)
	port map (i_0 => w_0,
				 i_1 => w_1,
				 i_2 => w_2,
				 i_3 => w_3,
				 i_S => w_S,
				 o_Z => w_Z);
	
	-- Process for stimulating inputs		 
	stimulus: process is
	begin
		wait for 20 ns;
		w_S <= B"01";
		wait for 20 ns;
		w_S <= B"10";
		wait for 20 ns;
		w_S <= B"11";
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;