--| Enabled_Register_TB.vhd
--| Bank of 32, 32-bit registers.  On the rising clock edge, only the contents of
--| the selected register are modified to be equal to the value of i_data.  All
--| other registers retain their previous value.
--|
--| INPUTS:
--| i_clk	- Clock
--| i_reset	- Reset
--| i_data	- Data
--| i_sel	- Encoded select signal to determine which register should be enabled
--|
--| OUTPUTS:
--| o_Q00 - Output of register 0
--| o_Q01 - Output of register 1
--| ...
--| o_Q30 - Output of register 30
--| o_Q31 - Output of register 31
library IEEE;
use IEEE.std_logic_1164.all;

entity Enabled_Register_TB is
end Enabled_Register_TB;

architecture test_bench of Enabled_Register_TB is	
--| Declare Components
	component Enabled_Register is
		port (i_clk		: in  std_logic;
				i_reset	: in  std_logic;
				i_data	: in  std_logic_vector(31 downto 0);
				i_en		: in  std_logic;
				o_Q		: out std_logic_vector(31 downto 0));
	end component;
	
--| Declare Signals
	signal c_clk : std_logic := '0';
	signal w_reset : std_logic := '1';
	signal w_data : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_0000_0000_0001";
	signal w_en : std_logic := '0';
	signal w_Q : std_logic_vector(31 downto 0);
begin
	-- Connect the Enabled_Register
	u_Enabled_Register: Enabled_Register
	port map (i_clk => c_clk,
				 i_reset => w_reset,
				 i_data => w_data,
				 i_en => w_en,
				 o_Q => w_Q);
				 
	stimulus : process
   begin
		wait for 100 ns;
		w_reset <= '0';
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0000_0000_0010";
		w_en <= '1';
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0000_0000_0100";
		w_en <= '0';
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0000_0000_1000";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0000_0001_0000";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0000_0010_0000";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0000_0100_0000";
		w_en <= '1';
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0000_1000_0000";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0001_0000_0000";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0010_0000_0000";
		w_en <= '0';
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0100_0000_0000";
		wait for 20 ns;
		wait;
   end process;
				 
	--| Generate the clock signal
	clock_gen: process is
	begin
		c_clk <= '1' after 10 ns, '0' after 20 ns;
		wait for 20 ns;
	end process clock_gen;
	
end test_bench;