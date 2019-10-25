--| Encoder4_2_TB.vhd
--| Test the Encoder4_2
library IEEE;
use IEEE.std_logic_1164.all;

entity Encoder4_2_TB is
end Encoder4_2_TB;

architecture testbench of Encoder4_2_TB is	
--| Declare Components
	component Encoder4_2 is
		port (i_1 : in  std_logic;
				i_2 : in  std_logic;
				i_3 : in  std_logic;
				o_Z : out std_logic_vector(1 downto 0));
	end component;
	
--| Declare Signals
	signal w_1 : std_logic := '0'; -- Input 1
	signal w_2 : std_logic := '0'; -- Input 2
	signal w_3 : std_logic := '0'; -- Input 3
	signal w_Z : std_logic_vector(1 downto 0); -- Output

begin
	-- Connect the Encoder4_2
	u_Encoder4_2 : Encoder4_2
	port map (
		i_1 => w_1,
		i_2 => w_2,
		i_3 => w_3,
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
		wait;
	end process;
end testbench;