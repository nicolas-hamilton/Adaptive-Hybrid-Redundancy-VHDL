--| myMUX2_N_TB
--| Tests myMUX2_N
library IEEE;
use IEEE.std_logic_1164.all;

entity myMUX2_N_TB is
end myMUX2_N_TB;

architecture testbench of myMUX2_N_TB is
	-- Declare Components
	component myMUX2_N is
		generic (m_width : integer := 32);
		port (i_0 : in  std_logic_vector(31 downto 0);
				i_1 : in  std_logic_vector(31 downto 0);
				i_S : in  std_logic;
				o_Z : out std_logic_vector(31 downto 0)
				);
	end component;

	-- Declare signals
	signal w_0 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_1111_1111_1111_1111";
	signal w_1 : std_logic_vector(31 downto 0) := B"1111_1111_1111_1111_0000_0000_0000_0000";
	signal w_S : std_logic := '0';
	signal w_Z : std_logic_vector(31 downto 0);

begin	
	-- Connect myMUX2_N
	u_myMUX2_N: myMUX2_N
	generic map (m_width => 32)
	port map (i_0 => w_0,
				 i_1 => w_1,
				 i_S => w_S,
				 o_Z => w_Z);
	
	-- Process for stimulating inputs		 
	stimulus: process is
	begin
		wait for 20 ns;
		w_S <= '1';
		wait for 20 ns;
		w_0 <= B"1111_0000_1111_0000_1111_0000_1111_0000";
		w_1 <= B"0000_1111_0000_1111_0000_1111_0000_1111";
		wait for 20 ns;
		w_S <= '0';
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;