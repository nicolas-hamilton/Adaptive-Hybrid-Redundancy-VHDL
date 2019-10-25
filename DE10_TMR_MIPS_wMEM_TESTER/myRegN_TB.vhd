--| myRegN.vhd
--| Test N-bit register
library IEEE;
use IEEE.std_logic_1164.all;

entity myRegN_TB is
end myRegN_TB;

architecture testbench of myRegN_TB is	
--| Declare components
	component myRegN is
		generic (m_width : integer := 32);
		port (i_clk		: in  std_logic;
				i_reset	: in  std_logic;
				i_D		: in  std_logic_vector (m_width-1 downto 0);
				o_Q		: out std_logic_vector (m_width-1 downto 0));
	end component;

--| Declare signals
	signal c_clk : std_logic := '0';
	signal w_reset : std_logic := '1';
	signal w_D : std_logic_vector (31 downto 0) := B"1111_1111_1111_1111_1111_1111_1111_1111";
	signal w_Q : std_logic_vector (31 downto 0);
begin
	u_myRegN: myRegN
	generic map (m_width => 32)
	port map (i_clk => c_clk,
				 i_reset => w_reset,
				 i_D => w_D,
				 o_Q => w_Q);

	--| Generate the stimulus
	stimulus : process
   begin
		wait for 100 ns;
		w_reset <= '0';
		wait for 20 ns;
		w_D <= (others => '0');
		wait for 20 ns;
		w_D <= B"0101_0101_0101_0101_0101_0101_0101_0101";
		wait for 20 ns;
		w_D <= B"1010_1010_1010_1010_1010_1010_1010_1010";
		wait for 20 ns;
		w_D <= B"0000_1111_0000_1111_0000_1111_0000_1111";
		wait;
   end process;
				 
	--| Generate the clock signal
	clock_gen: process is
	begin
		c_clk <= '1' after 10 ns, '0' after 20 ns;
		wait for 20 ns;
	end process clock_gen;
end testbench;