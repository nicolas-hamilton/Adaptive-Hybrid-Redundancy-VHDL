--| myMUX32_N_TB
--| Tests myMUX32_N
library IEEE;
use IEEE.std_logic_1164.all;

entity myMUX32_N_TB is
end myMUX32_N_TB;

architecture testbench of myMUX32_N_TB is
	-- Declare Components
	component myMUX32_N is
		generic (m_width : integer := 32);
		port (i_0 : in  std_logic_vector(31 downto 0);
				i_1 : in  std_logic_vector(31 downto 0);
				i_2 : in  std_logic_vector(31 downto 0);
				i_3 : in  std_logic_vector(31 downto 0);
				i_4 : in  std_logic_vector(31 downto 0);
				i_5 : in  std_logic_vector(31 downto 0);
				i_6 : in  std_logic_vector(31 downto 0);
				i_7 : in  std_logic_vector(31 downto 0);
				i_8 : in  std_logic_vector(31 downto 0);
				i_9 : in  std_logic_vector(31 downto 0);
				i_10 : in  std_logic_vector(31 downto 0);
				i_11 : in  std_logic_vector(31 downto 0);
				i_12 : in  std_logic_vector(31 downto 0);
				i_13 : in  std_logic_vector(31 downto 0);
				i_14 : in  std_logic_vector(31 downto 0);
				i_15 : in  std_logic_vector(31 downto 0);
				i_16 : in  std_logic_vector(31 downto 0);
				i_17 : in  std_logic_vector(31 downto 0);
				i_18 : in  std_logic_vector(31 downto 0);
				i_19 : in  std_logic_vector(31 downto 0);
				i_20 : in  std_logic_vector(31 downto 0);
				i_21 : in  std_logic_vector(31 downto 0);
				i_22 : in  std_logic_vector(31 downto 0);
				i_23 : in  std_logic_vector(31 downto 0);
				i_24 : in  std_logic_vector(31 downto 0);
				i_25 : in  std_logic_vector(31 downto 0);
				i_26 : in  std_logic_vector(31 downto 0);
				i_27 : in  std_logic_vector(31 downto 0);
				i_28 : in  std_logic_vector(31 downto 0);
				i_29 : in  std_logic_vector(31 downto 0);
				i_30 : in  std_logic_vector(31 downto 0);
				i_31 : in  std_logic_vector(31 downto 0);
				i_S : in  std_logic_vector(4 downto 0);
				o_Z : out std_logic_vector(31 downto 0)
				);
	end component;

	-- Declare signals
	signal w_0 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_0000_0000_0001";
	signal w_1 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_0000_0000_0010";
	signal w_2 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_0000_0000_0100";
	signal w_3 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_0000_0000_1000";
	signal w_4 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_0000_0001_0000";
	signal w_5 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_0000_0010_0000";
	signal w_6 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_0000_0100_0000";
	signal w_7 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_0000_1000_0000";
	signal w_8 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_0001_0000_0000";
	signal w_9 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_0010_0000_0000";
	signal w_10 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_0100_0000_0000";
	signal w_11 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_1000_0000_0000";
	signal w_12 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0001_0000_0000_0000";
	signal w_13 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0010_0000_0000_0000";
	signal w_14 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0100_0000_0000_0000";
	signal w_15 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_1000_0000_0000_0000";
	signal w_16 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0001_0000_0000_0000_0000";
	signal w_17 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0010_0000_0000_0000_0000";
	signal w_18 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0100_0000_0000_0000_0000";
	signal w_19 : std_logic_vector(31 downto 0) := B"0000_0000_0000_1000_0000_0000_0000_0000";
	signal w_20 : std_logic_vector(31 downto 0) := B"0000_0000_0001_0000_0000_0000_0000_0000";
	signal w_21 : std_logic_vector(31 downto 0) := B"0000_0000_0010_0000_0000_0000_0000_0000";
	signal w_22 : std_logic_vector(31 downto 0) := B"0000_0000_0100_0000_0000_0000_0000_0000";
	signal w_23 : std_logic_vector(31 downto 0) := B"0000_0000_1000_0000_0000_0000_0000_0000";
	signal w_24 : std_logic_vector(31 downto 0) := B"0000_0001_0000_0000_0000_0000_0000_0000";
	signal w_25 : std_logic_vector(31 downto 0) := B"0000_0010_0000_0000_0000_0000_0000_0000";
	signal w_26 : std_logic_vector(31 downto 0) := B"0000_0100_0000_0000_0000_0000_0000_0000";
	signal w_27 : std_logic_vector(31 downto 0) := B"0000_1000_0000_0000_0000_0000_0000_0000";
	signal w_28 : std_logic_vector(31 downto 0) := B"0001_0000_0000_0000_0000_0000_0000_0000";
	signal w_29 : std_logic_vector(31 downto 0) := B"0010_0000_0000_0000_0000_0000_0000_0000";
	signal w_30 : std_logic_vector(31 downto 0) := B"0100_0000_0000_0000_0000_0000_0000_0000";
	signal w_31 : std_logic_vector(31 downto 0) := B"1000_0000_0000_0000_0000_0000_0000_0000";
	signal w_S : std_logic_vector(4 downto 0) := (others => '0');
	signal w_Z : std_logic_vector(31 downto 0);

begin	
	-- Connect myMUX32_N
	u_myMUX32_N: myMUX32_N
	generic map (m_width => 32)
	port map (i_0 => w_0,
				 i_1 => w_1,
				 i_2 => w_2,
				 i_3 => w_3,
				 i_4 => w_4,
				 i_5 => w_5,
				 i_6 => w_6,
				 i_7 => w_7,
				 i_8 => w_8,
				 i_9 => w_9,
				 i_10 => w_10,
				 i_11 => w_11,
				 i_12 => w_12,
				 i_13 => w_13,
				 i_14 => w_14,
				 i_15 => w_15,
				 i_16 => w_16,
				 i_17 => w_17,
				 i_18 => w_18,
				 i_19 => w_19,
				 i_20 => w_20,
				 i_21 => w_21,
				 i_22 => w_22,
				 i_23 => w_23,
				 i_24 => w_24,
				 i_25 => w_25,
				 i_26 => w_26,
				 i_27 => w_27,
				 i_28 => w_28,
				 i_29 => w_29,
				 i_30 => w_30,
				 i_31 => w_31,
				 i_S => w_S,
				 o_Z => w_Z);
	
	-- Process for stimulating inputs		 
	stimulus: process is
	begin
		wait for 20 ns;
		w_S <= B"00001";
		wait for 20 ns;
		w_S <= B"00010";
		wait for 20 ns;
		w_S <= B"00011";
		wait for 20 ns;
		w_S <= B"00100";
		wait for 20 ns;
		w_S <= B"00101";
		wait for 20 ns;
		w_S <= B"00110";
		wait for 20 ns;
		w_S <= B"00111";
		wait for 20 ns;
		w_S <= B"01000";
		wait for 20 ns;
		w_S <= B"01001";
		wait for 20 ns;
		w_S <= B"01010";
		wait for 20 ns;
		w_S <= B"01011";
		wait for 20 ns;
		w_S <= B"01100";
		wait for 20 ns;
		w_S <= B"01101";
		wait for 20 ns;
		w_S <= B"01110";
		wait for 20 ns;
		w_S <= B"01111";
		wait for 20 ns;
		w_S <= B"10000";
		wait for 20 ns;
		w_S <= B"10001";
		wait for 20 ns;
		w_S <= B"10010";
		wait for 20 ns;
		w_S <= B"10011";
		wait for 20 ns;
		w_S <= B"10100";
		wait for 20 ns;
		w_S <= B"10101";
		wait for 20 ns;
		w_S <= B"10110";
		wait for 20 ns;
		w_S <= B"10111";
		wait for 20 ns;
		w_S <= B"11000";
		wait for 20 ns;
		w_S <= B"11001";
		wait for 20 ns;
		w_S <= B"11010";
		wait for 20 ns;
		w_S <= B"11011";
		wait for 20 ns;
		w_S <= B"11100";
		wait for 20 ns;
		w_S <= B"11101";
		wait for 20 ns;
		w_S <= B"11110";
		wait for 20 ns;
		w_S <= B"11111";
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;