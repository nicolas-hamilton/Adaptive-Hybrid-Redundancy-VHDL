--| myMUX16_1_TB
--| Tests myMUX16_1
library IEEE;
use IEEE.std_logic_1164.all;

entity myMUX16_1_TB is
end myMUX16_1_TB;

architecture testbench of myMUX16_1_TB is
	-- Declare Components
	component myMUX16_1 is
		port (i_0	: in  std_logic;
				i_1	: in  std_logic;
				i_2	: in  std_logic;
				i_3	: in  std_logic;
				i_4	: in  std_logic;
				i_5	: in  std_logic;
				i_6	: in  std_logic;
				i_7	: in  std_logic;
				i_8	: in  std_logic;
				i_9	: in  std_logic;
				i_10	: in  std_logic;
				i_11	: in  std_logic;
				i_12	: in  std_logic;
				i_13	: in  std_logic;
				i_14	: in  std_logic;
				i_15	: in  std_logic;
				i_S : in  std_logic_vector(3 downto 0);
				o_Z : out std_logic
				);
	end component;

	-- Declare signals
	signal w_0	: std_logic := '0';
	signal w_1	: std_logic := '1';
	signal w_2	: std_logic := '1';
	signal w_3	: std_logic := '0';
	signal w_4	: std_logic := '1';
	signal w_5	: std_logic := '0';
	signal w_6	: std_logic := '1';
	signal w_7	: std_logic := '0';
	signal w_8	: std_logic := '0';
	signal w_9	: std_logic := '1';
	signal w_10	: std_logic := '0';
	signal w_11	: std_logic := '1';
	signal w_12	: std_logic := '1';
	signal w_13	: std_logic := '0';
	signal w_14	: std_logic := '0';
	signal w_15	: std_logic := '1';
	signal w_S	: std_logic_vector(3 downto 0) := B"0000";
	signal w_Z	: std_logic;

begin	
	-- Connect myMUX16_1
	u_myMUX16_1: myMUX16_1
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
				 i_S => w_S,
				 o_Z => w_Z);
	
	-- Process for stimulating inputs		 
	stimulus: process is
	begin
		wait for 20 ns;
		w_S <= B"0001";
		wait for 20 ns;
		w_S <= B"0010";
		wait for 20 ns;
		w_S <= B"0011";
		wait for 20 ns;
		w_S <= B"0100";
		wait for 20 ns;
		w_S <= B"0101";
		wait for 20 ns;
		w_S <= B"0110";
		wait for 20 ns;
		w_S <= B"0111";
		wait for 20 ns;
		w_S <= B"1000";
		wait for 20 ns;
		w_S <= B"1001";
		wait for 20 ns;
		w_S <= B"1010";
		wait for 20 ns;
		w_S <= B"1011";
		wait for 20 ns;
		w_S <= B"1100";
		wait for 20 ns;
		w_S <= B"1101";
		wait for 20 ns;
		w_S <= B"1110";
		wait for 20 ns;
		w_S <= B"1111";
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;