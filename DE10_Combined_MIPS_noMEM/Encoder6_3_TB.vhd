--| Encoder6_3_TB.vhd
--| Test the Encoder6_3
library IEEE;
use IEEE.std_logic_1164.all;

entity Encoder6_3_TB is
end Encoder6_3_TB;

architecture testbench of Encoder6_3_TB is	
--| Declare Components
	component Encoder6_3 is
		port (i_1 : in  std_logic;
				i_2 : in  std_logic;
				i_3 : in  std_logic;
				i_4 : in  std_logic;
				i_5 : in  std_logic;
				o_Z : out std_logic_vector(2 downto 0));
	end component;
	
--| Declare Signals
	signal w_1 : std_logic := '0'; -- Input 1
	signal w_2 : std_logic := '0'; -- Input 2
	signal w_3 : std_logic := '0'; -- Input 3
	signal w_4 : std_logic := '0'; -- Input 4
	signal w_5 : std_logic := '0'; -- Input 5
	signal w_Z : std_logic_vector(2 downto 0); -- Output

begin
	-- Connect the Encoder6_3
	u_Encoder6_3 : Encoder6_3
	port map (
		i_1 => w_1,
		i_2 => w_2,
		i_3 => w_3,
		i_4 => w_4,
		i_5 => w_5,
		o_Z => w_Z);
		
	stimulus: process is
	begin
		wait for 20 ns;
		w_1 <= '1';
		wait for 20 ns;
		w_1 <= '0';
		w_2 <= '1';
		wait for 20 ns;
		w_2 <= '0';
		w_3 <= '1';
		wait for 20 ns;
		w_3 <= '0';
		w_4 <= '1';
		wait for 20 ns;
		w_4 <= '0';
		w_5 <= '1';
		wait for 20 ns;
		wait;
	end process;
end testbench;