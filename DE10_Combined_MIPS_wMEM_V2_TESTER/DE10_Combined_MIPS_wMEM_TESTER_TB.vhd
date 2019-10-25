--| DE10_Combined_MIPS_wMEM_TESTER_TB.vhd
--| Test the functionality of the Combined_MIPS using the MEM_EMULATOR
--| so that the controller can "read" instructions from memory, transition
--| through the appropriate states, and send the proper control signals out
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity DE10_Combined_MIPS_wMEM_TESTER_TB is
end DE10_Combined_MIPS_wMEM_TESTER_TB;

architecture testbench of DE10_Combined_MIPS_wMEM_TESTER_TB is
--| Define Components
	component DE10_Combined_MIPS_wMEM_TESTER is
		port (i_clk					: in  std_logic;
				i_reset_Combined	: in  std_logic;
				i_reset_MEM			: in  std_logic;
				o_DONE				: out std_logic;
				o_UART_ERROR		: out std_logic);
	end component;
	
--| Define signals
	signal c_clk				: std_logic := '0';
	signal w_reset_Combined	: std_logic := '1';
	signal w_reset_MEM		: std_logic := '0';
	signal w_DONE				: std_logic;
	signal w_UART_ERROR		: std_logic;

	
begin
	-- Create Combined MIPS
	u_DE10_Combined_MIPS_wMEM_TESTER : DE10_Combined_MIPS_wMEM_TESTER
	port map (i_clk => c_clk,
				 i_reset_Combined => w_reset_Combined,
				 i_reset_MEM => w_reset_MEM,
				 o_DONE => w_DONE,
				 o_UART_ERROR => w_UART_ERROR);
				 
		--| Generate the stimulus
	stimulus : process is
   begin
		wait for 100 ns;
		w_reset_MEM <= '1';
   end process stimulus;
				 
	--| Generate the clock signal
	clock_gen: process is
	begin
		c_clk <= '1' after 10 ns, '0' after 20 ns;
		wait for 20 ns;
	end process clock_gen;
					
end testbench;