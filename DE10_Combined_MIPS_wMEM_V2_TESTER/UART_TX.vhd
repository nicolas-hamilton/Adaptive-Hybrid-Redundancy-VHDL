--| UART_TX.vhd
--| Provided an 8-bit input and a send signal, produces a serial output starting
--| from the LSB to the MSB at 25MHz.  Produces a "done" signal when the
--| signal has been sent
--|
--| INPUTS:
--| i_clk	- clock input
--| i_reset - reset input
--| i_data	- data to send
--| i_send	- instruct UART_TX to begin transmitting data on i_data signal
--|
--| OUTPUTS:
--| o_data - serial output data
--| o_done - signal is 1 when data transmit operation is complete
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity UART_TX is
	port (i_clk		: in  std_logic;
         i_reset	: in  std_logic;
         i_data	: in  std_logic_vector(7 downto 0);
         i_send	: in  std_logic;
         o_data	: out std_logic;
         o_done	: out std_logic);
end UART_TX;

architecture a_UART_TX of UART_TX is
	-- Build an enumerated type for the state machine
	type state_type is (s0, s1, s2, s3, s4);
	
	-- Register to hold the current state
	signal s_state : state_type := s0;
	signal f_count : unsigned(8 downto 0) := (others => '0');
	signal f_data : std_logic_vector(7 downto 0) := (others => '0');
	signal f_data_out : std_logic := '1';
	signal f_data_count : unsigned(2 downto 0) := (others => '0');
	signal f_done : std_logic := '0';
	
	-- Constant value to set baud rate
	constant k_baud : integer := 0;-- Set to 434 for 115200 baud

begin
	o_done <= f_done;
	o_data <= f_data_out;

	UART_FSM_process : process (i_clk, i_reset, i_send)
	begin
		if i_reset = '1' then
			f_data <= (others => '0');
         f_data_count <= (others => '0');
      elsif rising_edge(i_clk) then
			case s_state is
				-- Idle state - waiting for send signal
				when s0 =>
					if (i_send = '1') then
						s_state <= s1;
						f_data <= i_data;
					else
						s_state <= s0;
						f_count <= (others => '0');
						f_data_count <= (others => '0');
					end if;
				-- Transmit Start Bit
				when s1 =>
					-- Wait until k_baud clock cycles have occured
					if (f_count = k_baud) then
						s_state <= s2;
						f_count <= (others => '0');
					-- 1 clock cycles have not occured - Increment the counter
					else
						s_state <= s1;
						f_count <= f_count + 1;
					end if;
				-- Transmit Data Bits
				when s2 =>
					-- Wait until k_baud clock cycles have occured
					if (f_count = k_baud) then
						-- If the last data bit has been transmitted
						if (f_data_count = 7) then
							s_state <= s3;
							f_count <= (others => '0');
							f_data_count <= (others => '0');
						-- If the last data bit has NOT been transmitted
						else
							s_state <= s2;
							f_count <= (others => '0');
							f_data_count <= f_data_count + 1;
						end if;
					-- 1 clock cycles have not occured - Increment the counter
					else
						s_state <= s2;
						f_count <= f_count + 1;
					end if;
				-- Transmit Stop Bit
				when s3 =>
					-- Wait until k_baud clock cycles have occured
					if (f_count = k_baud) then
						s_state <= s4;
						f_count <= (others => '0');
					-- 1 clock cycles have not occured - Increment the counter
					else
						s_state <= s3;
						f_count <= f_count + 1;
					end if;
				-- Wait for send signal to return to 0
				when s4 =>
					if (i_send = '0') then
						s_state <= s0;
					else
						s_state <= s4;
					end if;
				-- An error has occured
				when others =>
					s_state <= s0;
					f_data <= (others => '0');
					f_data_count <= (others => '0');
			end case;
		end if;
	end process UART_FSM_process;
	 
	UART_TX_process : process (i_clk, s_state, f_data, f_data_count, f_done)
   begin
		case s_state is
			when s0 =>
				f_data_out <= '1';
				f_done <= '0';
			when s1 =>
				f_data_out <= '0';
				f_done <= '0';
			when s2 =>
				f_data_out <= f_data(to_integer(f_data_count));
				f_done <= '0';
			when s3 =>
				f_data_out <= '1';
				f_done <= '0';
			when s4 =>
				f_data_out <= '1';
				f_done <= '1';
			when others =>
				f_data_out <= '1';
				f_done <= '0';
		end case;
	end process UART_TX_process; 
end a_UART_TX;
