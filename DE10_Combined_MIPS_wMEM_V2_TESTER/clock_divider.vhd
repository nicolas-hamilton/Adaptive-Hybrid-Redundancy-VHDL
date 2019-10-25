--| clock_divider.vhd
--| Nicolas Hamilton
--| Divides a clock by 2
--| INPUTS:
--| i_clk - 50MHz clock
--| i_reset - reset the clock divider
--| OUTPUTS:
--| o_clk - 25MHz clock

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--| Entity Declaration
entity clock_divider is
	port (
		i_clk		: in  std_logic;
		i_reset	: in  std_logic;
		o_clk		: out std_logic
		);
end clock_divider;

--| Architecture Declaration
architecture a_clock_divider of clock_divider is
--| Define Signals
---| Initialize a register to store the last output value
signal f_clk		: std_logic := '0';
begin
	o_clk <= f_clk;
	sm_moore: process(i_clk, i_reset) is
	begin
		if i_reset = '1' then
				f_clk <= '0';
		elsif rising_edge(i_clk) then
			f_clk <= not f_clk;
		end if;
	end process;
	
end a_clock_divider;