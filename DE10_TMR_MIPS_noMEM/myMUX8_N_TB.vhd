--| myMUX8_N_TB
--| Tests myMUX8_N
library IEEE;
use IEEE.std_logic_1164.all;

entity myMUX8_N_TB is
end myMUX8_N_TB;

architecture testbench of myMUX8_N_TB is
	-- Declare Components
	component myMUX8_N is
		generic (m_width : integer := 32);
		port (i_0 : in  std_logic_vector(31 downto 0);
				i_1 : in  std_logic_vector(31 downto 0);
				i_2 : in  std_logic_vector(31 downto 0);
				i_3 : in  std_logic_vector(31 downto 0);
				i_4 : in  std_logic_vector(31 downto 0);
				i_5 : in  std_logic_vector(31 downto 0);
				i_6 : in  std_logic_vector(31 downto 0);
				i_7 : in  std_logic_vector(31 downto 0);
				i_S : in  std_logic_vector(2 downto 0);
				o_Z : out std_logic_vector(31 downto 0)
				);
	end component;

	-- Declare signals
	signal w_0 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_0000_0000_1111";
	signal w_1 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_0000_1111_0000";
	signal w_2 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_1111_0000_0000";
	signal w_3 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_1111_0000_0000_0000";
	signal w_4 : std_logic_vector(31 downto 0) := B"0000_0000_0000_1111_0000_0000_0000_0000";
	signal w_5 : std_logic_vector(31 downto 0) := B"0000_0000_1111_0000_0000_0000_0000_0000";
	signal w_6 : std_logic_vector(31 downto 0) := B"0000_1111_0000_0000_0000_0000_0000_0000";
	signal w_7 : std_logic_vector(31 downto 0) := B"1111_0000_0000_0000_0000_0000_0000_0000";
	signal w_S : std_logic_vector(2 downto 0) := (others => '0');
	signal w_Z : std_logic_vector(31 downto 0);

begin	
	-- Connect myMUX8_N
	u_myMUX8_N: myMUX8_N
	generic map (m_width => 32)
	port map (i_0 => w_0,
				 i_1 => w_1,
				 i_2 => w_2,
				 i_3 => w_3,
				 i_4 => w_4,
				 i_5 => w_5,
				 i_6 => w_6,
				 i_7 => w_7,
				 i_S => w_S,
				 o_Z => w_Z);
	
	-- Process for stimulating inputs		 
	stimulus: process is
	begin
		wait for 20 ns;
		w_S <= B"001";
		wait for 20 ns;
		w_S <= B"010";
		wait for 20 ns;
		w_S <= B"011";
		wait for 20 ns;
		w_S <= B"100";
		wait for 20 ns;
		w_S <= B"101";
		wait for 20 ns;
		w_S <= B"110";
		wait for 20 ns;
		w_S <= B"111";
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;