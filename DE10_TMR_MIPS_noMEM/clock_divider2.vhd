--| clock_divider2.vhd
--| Nicolas Hamilton
--| Takes a bouncy signal as an imput and provides a debounced output.
--| Upon detecting a change in the input signal from its previous value,
--| wait 1ms and check to see if the input is still different from its
--| previuos value.  If it is still different, then the output changes
--| to match the input.  If it is not still different, then the output
--| is unchanged.
--| INPUTS:
--| i_clk - 50MHz clock input
--| i_bouncy - bouncy input signal
--| OUTPUTS:
--| o_debounced - debounced version of input signal

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--| Entity Declaration
entity clock_divider2 is
	port (
		i_clk		: in  std_logic;
		i_reset	: in  std_logic;
		i_count	: in  unsigned(9 downto 0);
		o_clk		: out std_logic
		);
end clock_divider2;

--| Architecture Declaration
architecture a_clock_divider2 of clock_divider2 is
--| Define Signals
---| Register to keep track of time
signal f_counter : unsigned(24 downto 0) := (others => '0');
---| Register to store output clock
signal f_clk  : std_logic := '0';
---| Constant to augment the input count
constant k_zero : unsigned(13 downto 0) := (others => '0');
---| Wire to keep track of the max count for the clock
signal w_count : unsigned(24 downto 0);

begin
	o_clk <= f_clk;
	w_count <= '0' & i_count & k_zero;
	sm_moore: process(i_clk, i_reset, f_counter, w_count) is
	begin
		if i_reset = '1' then
				f_clk <= '0';
				f_counter <= (others => '0');
		elsif rising_edge(i_clk) then
			if (f_counter >= w_count) then
				f_counter <= (others => '0');
				f_clk <= not f_clk;
			else
				f_counter <= f_counter + 1;
				f_clk <= f_clk;
			end if;
		end if;
	end process;
	
end a_clock_divider2;