--| myReg1.vhd
--| Test 1-bit register
library IEEE;
use IEEE.std_logic_1164.all;

entity myReg1_TB is
end myReg1_TB;

architecture testbench of myReg1_TB is	
--| Declare components
	component myReg1 is
		port (i_clk		: in  std_logic;
				i_reset	: in  std_logic;
				i_D		: in  std_logic;
				o_Q		: out std_logic);
	end component;

--| Declare signals
	signal c_clk : std_logic := '0';
	signal w_reset : std_logic := '1';
	signal w_D : std_logic := '1';
	signal w_Q : std_logic;
begin
	u_myReg1: myReg1
	port map (i_clk => c_clk,
				 i_reset => w_reset,
				 i_D => w_D,
				 o_Q => w_Q);

	--| Generate the stimulus
	stimulus : process
   begin
		wait for 100 ns;
		w_reset <= '0';
		wait for 10 ns;
		w_D <= '0';
		wait for 20 ns;
		w_D <= '1';
		wait for 20 ns;
		w_D <= '0';
		wait for 20 ns;
		w_D <= '1';
		wait;
   end process;
				 
	--| Generate the clock signal
	clock_gen: process is
	begin
		c_clk <= '1' after 10 ns, '0' after 20 ns;
		wait for 20 ns;
	end process clock_gen;
end testbench;