--| debouncer.vhd
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
entity debouncer is
	port (
		i_clk: 		 in std_logic;
		i_reset:		 in std_logic;
		i_bouncy: 	 in std_logic;
		o_debounced: out std_logic
		);
end debouncer;

--| Architecture Declaration
architecture a_debouncer of debouncer is
--| Define Signals
---| Create States for the Debouncer State Machine
type   sm_deb is (s_idle, s_wait);
---| Initialize the state register
signal f_state : sm_deb := s_idle;
---| Initialize a counter to keep track of time
signal f_counter : unsigned(15 downto 0) := (others => '0');
---| Initialize a register to store the last input value
signal f_bouncy  : std_logic := '0';
begin
	--| Start a Moore Process triggered on the rising edge of the clock
	sm_moore: process(i_clk) is
	begin
		if rising_edge(i_clk) then
			--| If reset is asserted, set the debouncer output, previous
			--| value, output, and counter to 0.
			if i_reset = '1' then
				f_state <= s_idle;
				o_debounced <= '0';
				f_bouncy <= '0';
				f_counter <= (others => '0');
			--| If reset is not asserted, continue
			else
				case f_state is
					--| When the current state is the idle state
					when s_idle =>
						--| The output is the same as the previous output
						o_debounced <= f_bouncy;
						--| The counter is zeroed out
						f_counter <= (others => '0');
						--| If the input is different than the current output
						--| transition to the wait state.
						if (i_bouncy = not f_bouncy) then
							f_state <= s_wait;
						--| If the input is not different than the current output
						--| remain in the idle state.
						else 
							f_state <= s_idle;
						end if;
					--| When the current state is the wait state
					when s_wait =>
						--| The output is the same as the previous output
						o_debounced <= f_bouncy;
						--| If the counter has reached 1ms and...
						if (f_counter = 50000-1) then
							--| If the input is still different than the current
							--| output, update the register that stores the last
							--| input value to be the input value
							if i_bouncy = not f_bouncy then
								f_bouncy <= i_bouncy;
							end if;
							--| Return to the idle state
							f_state <= s_idle;
							--| The counter is zeroed out
							f_counter <= (others => '0');
						--| If the counter has not reached 1ms, remain in the
						--| wait state and increment the counter.
						else
							f_state <= s_wait;
							f_counter <= f_counter + 1;
						end if;
					--| When the current state is neither wait nor idle, return
					--| to the idle state and zero out the counter.  The output
					--| is the same as the previous output.
					when others =>
						o_debounced <= f_bouncy;
						f_state <= s_wait;
						f_counter <= (others => '0');
				end case;
			end if;
		end if;
	end process;
	
end a_debouncer;