--| Error_Buffer.vhd
--| Provided a 40-bit error and an error detected signal, buffers the errors and sends
--| each error over a serial connection one byte at a time.  Buffer is first-in-first-out (FIFO).
--|
--| INPUTS:
--| i_clk	- clock input
--| i_reset - reset input
--| i_error	- 40-bit error data
--| i_error_detected	- signals that an error has been detected
--| i_done - signal from UART_TX that the data to be transmitted has been sent
--|
--| OUTPUTS:
--| o_data - Byte to be transmitted over the serial connection
--| o_send - Signal to tell URAT_TX to send the data
--| o_ack  - signal to tell the memulator that the error was received
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Error_Buffer is
	port (i_clk					: in  std_logic;
         i_reset				: in  std_logic;
         i_error				: in  std_logic_vector(39 downto 0);
			i_error_detected	: in  std_logic;
         i_done				: in  std_logic;
         o_data				: out std_logic_vector(7 downto 0);
         o_send				: out std_logic;
			o_ack					: out std_logic);
end Error_Buffer;

architecture a_Error_Buffer of Error_Buffer is
	-- Build an enumerated type for the state machines
	type state_type_in is (s0_in, s1_in);
	type state_type_out is (s0_out, s1_out, s2_out, s3_out, s4_out, s5_out, s6_out, s7_out, s8_out, s9_out, s10_out, s11_out, s12_out, s13_out);
	
	
	-- Register to hold the current state
	signal s_state_in : state_type_in := s0_in;
	signal s_state_out : state_type_out := s0_out;
	
	-- Registers to store errors
	type my_registers is array (6 downto 0) of std_logic_vector(39 downto 0);
	signal f_reg : my_registers;
	
	-- Signal to index where next incoming error should be stored
	signal f_err_buff_index : unsigned(2 downto 0) := (others => '0');
	
	-- Registers to store output signals
	signal f_data : std_logic_vector(7 downto 0) := (others => '0');
	signal f_send : std_logic := '0';
	signal f_ack : std_logic := '0';
	
	-- Signal to determine if f_r0 contains an error
	signal f_err0 : std_logic;
	
	-- Constant for newline character
	constant k_newline : std_logic_vector(7 downto 0) := "00001101";
	
begin
	o_data <= f_data;
	o_send <= f_send;
	o_ack <= f_ack;
	f_err0 <= f_reg(0)(39) or f_reg(0)(38) or f_reg(0)(37) or f_reg(0)(36) or f_reg(0)(35) or f_reg(0)(34) or f_reg(0)(33) or f_reg(0)(32);

	Buffer_FSM_process : process (i_clk, i_reset, i_error, i_error_detected, i_done, f_err0, f_err_buff_index)
	begin
		if (i_reset = '1') then
			s_state_in <= s0_in;
			s_state_out <= s0_out;
			f_reg(0) <= (others => '0');
			f_reg(1) <= (others => '0');
			f_reg(2) <= (others => '0');
			f_reg(3) <= (others => '0');
			f_reg(4) <= (others => '0');
			f_reg(5) <= (others => '0');
			f_reg(6) <= (others => '0');
			f_err_buff_index <= (others => '0');
      elsif rising_edge(i_clk) then
			case s_state_out is
				-- Idle state - waiting for there to be an error in f_reg(0)
				when s0_out =>
					-- If an error is stored in f_reg(0)
					if (f_err0 = '1') then
						s_state_out <= s1_out;
						f_reg(0) <= f_reg(0);
						f_reg(1) <= f_reg(1);
						f_reg(2) <= f_reg(2);
						f_reg(3) <= f_reg(3);
						f_reg(4) <= f_reg(4);
						f_reg(5) <= f_reg(5);
						f_reg(6) <= f_reg(6);
						
						-- Run input state machine
						case s_state_in is
							when s0_in =>
								-- If an error has been detected
								if (i_error_detected = '1') then
									-- Determine if the buffer has space available
									if (f_err_buff_index < 7) then
										s_state_in <= s1_in;
										f_reg(to_integer(f_err_buff_index)) <= i_error;
										f_err_buff_index <= f_err_buff_index + 1;
									-- The buffer is full - remain in state 0
									else
										s_state_in <= s0_in;
										f_err_buff_index <= f_err_buff_index;
									end if;
								-- No error has been detected
								else
									s_state_in <= s0_in;
								end if;
							when s1_in =>
								-- If the error signal is now back to 0
								if (i_error_detected = '0') then
									s_state_in <= s0_in;
								else
									s_state_in <= s1_in;
								end if;
							when others =>
								s_state_in <= s0_in;
						end case;
						
					-- If no error is stored in f_reg(0) (no errors are stored in the buffer)
					else
						s_state_out <= s0_out;
						f_reg(1) <= f_reg(1);
						f_reg(2) <= f_reg(2);
						f_reg(3) <= f_reg(3);
						f_reg(4) <= f_reg(4);
						f_reg(5) <= f_reg(5);
						f_reg(6) <= f_reg(6);
						-- Run input state machine
						case s_state_in is
							when s0_in =>
								-- If an error has been detected
								if (i_error_detected = '1') then
									s_state_in <= s1_in;
									f_reg(0) <= i_error;
									f_err_buff_index <= f_err_buff_index + 1;
								-- No error has been detected
								else
									s_state_in <= s0_in;
								end if;
							when s1_in =>
								-- If the error signal is now back to 0
								if (i_error_detected = '0') then
									s_state_in <= s0_in;
								else
									s_state_in <= s1_in;
								end if;
							when others =>
								s_state_in <= s0_in;
						end case;
					end if;
					
				-- Transmit first byte of error in f_reg(0) via serial connection (i.e. 39 downto 32)
				when s1_out =>
					if (i_done = '1') then
						s_state_out <= s2_out;
					else
						s_state_out <= s1_out;
					end if;
					
					-- Run input state machine
					case s_state_in is
						when s0_in =>
							-- If an error has been detected
							if (i_error_detected = '1') then
								-- Determine if the buffer has space available
								if (f_err_buff_index < 7) then
									s_state_in <= s1_in;
									f_reg(to_integer(f_err_buff_index)) <= i_error;
									f_err_buff_index <= f_err_buff_index + 1;
								-- The buffer is full - remain in state 0
								else
									s_state_in <= s0_in;
									f_err_buff_index <= f_err_buff_index;
								end if;
							-- No error has been detected
							else
								s_state_in <= s0_in;
							end if;
						when s1_in =>
							-- If the error signal is now back to 0
							if (i_error_detected = '0') then
								s_state_in <= s0_in;
							else
								s_state_in <= s1_in;
							end if;
						when others =>
							s_state_in <= s0_in;
					end case;
						
				-- Stop transmitting first byte
				when s2_out =>
					s_state_out <= s3_out;
					
					-- Run input state machine
					case s_state_in is
						when s0_in =>
							-- If an error has been detected
							if (i_error_detected = '1') then
								-- Determine if the buffer has space available
								if (f_err_buff_index < 7) then
									s_state_in <= s1_in;
									f_reg(to_integer(f_err_buff_index)) <= i_error;
									f_err_buff_index <= f_err_buff_index + 1;
								-- The buffer is full - remain in state 0
								else
									s_state_in <= s0_in;
									f_err_buff_index <= f_err_buff_index;
								end if;
							-- No error has been detected
							else
								s_state_in <= s0_in;
							end if;
						when s1_in =>
							-- If the error signal is now back to 0
							if (i_error_detected = '0') then
								s_state_in <= s0_in;
							else
								s_state_in <= s1_in;
							end if;
						when others =>
							s_state_in <= s0_in;
					end case;
				
				-- Transmit second byte of error in f_reg(0) via serial connection (i.e. 31 downto 24)
				when s3_out =>
					if (i_done = '1') then
						s_state_out <= s4_out;
					else
						s_state_out <= s3_out;
					end if;
					
					-- Run input state machine
					case s_state_in is
						when s0_in =>
							-- If an error has been detected
							if (i_error_detected = '1') then
								-- Determine if the buffer has space available
								if (f_err_buff_index < 7) then
									s_state_in <= s1_in;
									f_reg(to_integer(f_err_buff_index)) <= i_error;
									f_err_buff_index <= f_err_buff_index + 1;
								-- The buffer is full - remain in state 0
								else
									s_state_in <= s0_in;
									f_err_buff_index <= f_err_buff_index;
								end if;
							-- No error has been detected
							else
								s_state_in <= s0_in;
							end if;
						when s1_in =>
							-- If the error signal is now back to 0
							if (i_error_detected = '0') then
								s_state_in <= s0_in;
							else
								s_state_in <= s1_in;
							end if;
						when others =>
							s_state_in <= s0_in;
					end case;
				
				-- Stop transmitting second byte
				when s4_out =>
					s_state_out <= s5_out;
					
					-- Run input state machine
					case s_state_in is
						when s0_in =>
							-- If an error has been detected
							if (i_error_detected = '1') then
								-- Determine if the buffer has space available
								if (f_err_buff_index < 7) then
									s_state_in <= s1_in;
									f_reg(to_integer(f_err_buff_index)) <= i_error;
									f_err_buff_index <= f_err_buff_index + 1;
								-- The buffer is full - remain in state 0
								else
									s_state_in <= s0_in;
									f_err_buff_index <= f_err_buff_index;
								end if;
							-- No error has been detected
							else
								s_state_in <= s0_in;
							end if;
						when s1_in =>
							-- If the error signal is now back to 0
							if (i_error_detected = '0') then
								s_state_in <= s0_in;
							else
								s_state_in <= s1_in;
							end if;
						when others =>
							s_state_in <= s0_in;
					end case;
				
				-- Transmit third byte of error in f_reg(0) via serial connection (i.e. 23 downto 16)
				when s5_out =>
					if (i_done = '1') then
						s_state_out <= s6_out;
					else
						s_state_out <= s5_out;
					end if;
					
					-- Run input state machine
					case s_state_in is
						when s0_in =>
							-- If an error has been detected
							if (i_error_detected = '1') then
								-- Determine if the buffer has space available
								if (f_err_buff_index < 7) then
									s_state_in <= s1_in;
									f_reg(to_integer(f_err_buff_index)) <= i_error;
									f_err_buff_index <= f_err_buff_index + 1;
								-- The buffer is full - remain in state 0
								else
									s_state_in <= s0_in;
									f_err_buff_index <= f_err_buff_index;
								end if;
							-- No error has been detected
							else
								s_state_in <= s0_in;
							end if;
						when s1_in =>
							-- If the error signal is now back to 0
							if (i_error_detected = '0') then
								s_state_in <= s0_in;
							else
								s_state_in <= s1_in;
							end if;
						when others =>
							s_state_in <= s0_in;
					end case;
				
				-- Stop transmitting third byte
				when s6_out =>
					s_state_out <= s7_out;
					
					-- Run input state machine
					case s_state_in is
						when s0_in =>
							-- If an error has been detected
							if (i_error_detected = '1') then
								-- Determine if the buffer has space available
								if (f_err_buff_index < 7) then
									s_state_in <= s1_in;
									f_reg(to_integer(f_err_buff_index)) <= i_error;
									f_err_buff_index <= f_err_buff_index + 1;
								-- The buffer is full - remain in state 0
								else
									s_state_in <= s0_in;
									f_err_buff_index <= f_err_buff_index;
								end if;
							-- No error has been detected
							else
								s_state_in <= s0_in;
							end if;
						when s1_in =>
							-- If the error signal is now back to 0
							if (i_error_detected = '0') then
								s_state_in <= s0_in;
							else
								s_state_in <= s1_in;
							end if;
						when others =>
							s_state_in <= s0_in;
					end case;
				
				-- Transmit fourth byte of error in f_reg(0) via serial connection (i.e. 15 downto 8)
				when s7_out =>
					if (i_done = '1') then
						s_state_out <= s8_out;
					else
						s_state_out <= s7_out;
					end if;
					
					-- Run input state machine
					case s_state_in is
						when s0_in =>
							-- If an error has been detected
							if (i_error_detected = '1') then
								-- Determine if the buffer has space available
								if (f_err_buff_index < 7) then
									s_state_in <= s1_in;
									f_reg(to_integer(f_err_buff_index)) <= i_error;
									f_err_buff_index <= f_err_buff_index + 1;
								-- The buffer is full - remain in state 0
								else
									s_state_in <= s0_in;
									f_err_buff_index <= f_err_buff_index;
								end if;
							-- No error has been detected
							else
								s_state_in <= s0_in;
							end if;
						when s1_in =>
							-- If the error signal is now back to 0
							if (i_error_detected = '0') then
								s_state_in <= s0_in;
							else
								s_state_in <= s1_in;
							end if;
						when others =>
							s_state_in <= s0_in;
					end case;
				
				-- Stop transmitting fourth byte
				when s8_out =>
					s_state_out <= s9_out;
					
					-- Run input state machine
					case s_state_in is
						when s0_in =>
							-- If an error has been detected
							if (i_error_detected = '1') then
								-- Determine if the buffer has space available
								if (f_err_buff_index < 7) then
									s_state_in <= s1_in;
									f_reg(to_integer(f_err_buff_index)) <= i_error;
									f_err_buff_index <= f_err_buff_index + 1;
								-- The buffer is full - remain in state 0
								else
									s_state_in <= s0_in;
									f_err_buff_index <= f_err_buff_index;
								end if;
							-- No error has been detected
							else
								s_state_in <= s0_in;
							end if;
						when s1_in =>
							-- If the error signal is now back to 0
							if (i_error_detected = '0') then
								s_state_in <= s0_in;
							else
								s_state_in <= s1_in;
							end if;
						when others =>
							s_state_in <= s0_in;
					end case;
				
				-- Transmit fifth byte of error in f_reg(0) via serial connection (i.e. 7 downto 0)
				when s9_out =>
					if (i_done = '1') then
						s_state_out <= s10_out;
					else
						s_state_out <= s9_out;
					end if;
					
					-- Run input state machine
					case s_state_in is
						when s0_in =>
							-- If an error has been detected
							if (i_error_detected = '1') then
								-- Determine if the buffer has space available
								if (f_err_buff_index < 7) then
									s_state_in <= s1_in;
									f_reg(to_integer(f_err_buff_index)) <= i_error;
									f_err_buff_index <= f_err_buff_index + 1;
								-- The buffer is full - remain in state 0
								else
									s_state_in <= s0_in;
									f_err_buff_index <= f_err_buff_index;
								end if;
							-- No error has been detected
							else
								s_state_in <= s0_in;
							end if;
						when s1_in =>
							-- If the error signal is now back to 0
							if (i_error_detected = '0') then
								s_state_in <= s0_in;
							else
								s_state_in <= s1_in;
							end if;
						when others =>
							s_state_in <= s0_in;
					end case;
				
				-- Stop transmitting fifth byte
				when s10_out =>
					s_state_out <= s11_out;
					
					-- Run input state machine
					case s_state_in is
						when s0_in =>
							-- If an error has been detected
							if (i_error_detected = '1') then
								-- Determine if the buffer has space available
								if (f_err_buff_index < 7) then
									s_state_in <= s1_in;
									f_reg(to_integer(f_err_buff_index)) <= i_error;
									f_err_buff_index <= f_err_buff_index + 1;
								-- The buffer is full - remain in state 0
								else
									s_state_in <= s0_in;
									f_err_buff_index <= f_err_buff_index;
								end if;
							-- No error has been detected
							else
								s_state_in <= s0_in;
							end if;
						when s1_in =>
							-- If the error signal is now back to 0
							if (i_error_detected = '0') then
								s_state_in <= s0_in;
							else
								s_state_in <= s1_in;
							end if;
						when others =>
							s_state_in <= s0_in;
					end case;
				
				-- Transmit newline character via serial connection
				when s11_out =>
					if (i_done = '1') then
						s_state_out <= s12_out;
					else
						s_state_out <= s11_out;
					end if;
					
					-- Run input state machine
					case s_state_in is
						when s0_in =>
							-- If an error has been detected
							if (i_error_detected = '1') then
								-- Determine if the buffer has space available
								if (f_err_buff_index < 7) then
									s_state_in <= s1_in;
									f_reg(to_integer(f_err_buff_index)) <= i_error;
									f_err_buff_index <= f_err_buff_index + 1;
								-- The buffer is full - remain in state 0
								else
									s_state_in <= s0_in;
									f_err_buff_index <= f_err_buff_index;
								end if;
							-- No error has been detected
							else
								s_state_in <= s0_in;
							end if;
						when s1_in =>
							-- If the error signal is now back to 0
							if (i_error_detected = '0') then
								s_state_in <= s0_in;
							else
								s_state_in <= s1_in;
							end if;
						when others =>
							s_state_in <= s0_in;
					end case;
				
				-- Stop transmitting newline character
				when s12_out =>
					s_state_out <= s13_out;
					
					-- Run input state machine
					case s_state_in is
						when s0_in =>
							-- If an error has been detected
							if (i_error_detected = '1') then
								-- Determine if the buffer has space available
								if (f_err_buff_index < 7) then
									s_state_in <= s1_in;
									f_reg(to_integer(f_err_buff_index)) <= i_error;
									f_err_buff_index <= f_err_buff_index + 1;
								-- The buffer is full - remain in state 0
								else
									s_state_in <= s0_in;
									f_err_buff_index <= f_err_buff_index;
								end if;
							-- No error has been detected
							else
								s_state_in <= s0_in;
							end if;
						when s1_in =>
							-- If the error signal is now back to 0
							if (i_error_detected = '0') then
								s_state_in <= s0_in;
							else
								s_state_in <= s1_in;
							end if;
						when others =>
							s_state_in <= s0_in;
					end case;
				
				-- Shift registers down by 1 as needed
				when s13_out =>
					s_state_out <= s0_out;
					
					-- Run input state machine
					case s_state_in is
						when s0_in =>
							-- If an error has been detected
							if (i_error_detected = '1') then
								-- The buffer always has space available when new data arrives at the end of transmitting f_reg(0)
								-- Store new error to f_reg(0)
								if (f_err_buff_index = 1) then
									s_state_in <= s1_in;
									f_reg(0) <= i_error;
									f_reg(1) <= f_reg(1);
									f_reg(2) <= f_reg(2);
									f_reg(3) <= f_reg(3);
									f_reg(4) <= f_reg(4);
									f_reg(5) <= f_reg(5);
									f_reg(6) <= f_reg(6);
									f_err_buff_index <= f_err_buff_index;
								-- Store new error to f_reg(1)
								elsif (f_err_buff_index = 2) then
									s_state_in <= s1_in;
									f_reg(0) <= f_reg(1);
									f_reg(1) <= i_error;
									f_reg(2) <= f_reg(2);
									f_reg(3) <= f_reg(3);
									f_reg(4) <= f_reg(4);
									f_reg(5) <= f_reg(5);
									f_reg(6) <= f_reg(6);
									f_err_buff_index <= f_err_buff_index;
								-- Store new error to f_reg(2)
								elsif (f_err_buff_index = 3) then
									f_reg(0) <= f_reg(1);
									s_state_in <= s1_in;
									f_reg(1) <= f_reg(2);
									f_reg(2) <= i_error;
									f_reg(3) <= f_reg(3);
									f_reg(4) <= f_reg(4);
									f_reg(5) <= f_reg(5);
									f_reg(6) <= f_reg(6);
									f_err_buff_index <= f_err_buff_index;
								-- Store new error to f_reg(3)
								elsif (f_err_buff_index = 4) then
									s_state_in <= s1_in;
									f_reg(0) <= f_reg(1);
									f_reg(1) <= f_reg(2);
									f_reg(2) <= f_reg(3);
									f_reg(3) <= i_error;
									f_reg(4) <= f_reg(4);
									f_reg(5) <= f_reg(5);
									f_reg(6) <= f_reg(6);
									f_err_buff_index <= f_err_buff_index;
								-- Store new error to f_reg(4)
								elsif (f_err_buff_index = 5) then
									s_state_in <= s1_in;
									f_reg(0) <= f_reg(1);
									f_reg(1) <= f_reg(2);
									f_reg(2) <= f_reg(3);
									f_reg(3) <= f_reg(4);
									f_reg(4) <= i_error;
									f_reg(5) <= f_reg(5);
									f_reg(6) <= f_reg(6);
									f_err_buff_index <= f_err_buff_index;
								-- Store new error to f_reg(5)
								elsif (f_err_buff_index = 6) then
									s_state_in <= s1_in;
									f_reg(0) <= f_reg(1);
									f_reg(1) <= f_reg(2);
									f_reg(2) <= f_reg(3);
									f_reg(3) <= f_reg(4);
									f_reg(4) <= f_reg(5);
									f_reg(5) <= i_error;
									f_reg(6) <= f_reg(6);
									f_err_buff_index <= f_err_buff_index;
								-- Store new error to f_reg(6)
								elsif (f_err_buff_index = 7) then
									s_state_in <= s1_in;
									f_reg(0) <= f_reg(1);
									f_reg(1) <= f_reg(2);
									f_reg(2) <= f_reg(3);
									f_reg(3) <= f_reg(4);
									f_reg(4) <= f_reg(5);
									f_reg(5) <= f_reg(6);
									f_reg(6) <= i_error;
									f_err_buff_index <= f_err_buff_index;
								-- f_err_buff_index has encountered a problem, but this should never happen
								else
									s_state_in <= s0_in;									
									f_reg(0) <= (others => '0');
									f_reg(1) <= (others => '0');
									f_reg(2) <= (others => '0');
									f_reg(3) <= (others => '0');
									f_reg(4) <= (others => '0');
									f_reg(5) <= (others => '0');
									f_reg(6) <= (others => '0');
								end if;
							-- No error has been detected
							else
								s_state_in <= s0_in;
								f_reg(0) <= f_reg(1);
								f_reg(1) <= f_reg(2);
								f_reg(2) <= f_reg(3);
								f_reg(3) <= f_reg(4);
								f_reg(4) <= f_reg(5);
								f_reg(5) <= f_reg(6);
								f_reg(6) <= (others => '0');
								f_err_buff_index <= f_err_buff_index - 1;
							end if;
						when s1_in =>
							-- If the error signal is now back to 0
							if (i_error_detected = '0') then
								s_state_in <= s0_in;
							else
								s_state_in <= s1_in;
							end if;
							f_reg(0) <= f_reg(1);
							f_reg(1) <= f_reg(2);
							f_reg(2) <= f_reg(3);
							f_reg(3) <= f_reg(4);
							f_reg(4) <= f_reg(5);
							f_reg(5) <= f_reg(6);
							f_reg(6) <= (others => '0');
							f_err_buff_index <= f_err_buff_index - 1;
						when others =>
							s_state_in <= s0_in;
							f_reg(0) <= f_reg(1);
							f_reg(1) <= f_reg(2);
							f_reg(2) <= f_reg(3);
							f_reg(3) <= f_reg(4);
							f_reg(4) <= f_reg(5);
							f_reg(5) <= f_reg(6);
							f_reg(6) <= (others => '0');
							f_err_buff_index <= f_err_buff_index - 1;
					end case;
				
				-- An error has occured
				when others =>
					s_state_out <= s0_out;
					f_reg(0) <= (others => '0');
					f_reg(1) <= (others => '0');
					f_reg(2) <= (others => '0');
					f_reg(3) <= (others => '0');
					f_reg(4) <= (others => '0');
					f_reg(5) <= (others => '0');
					f_reg(6) <= (others => '0');
			end case;
		end if;
	end process Buffer_FSM_process;
	 
	Buffer_output_process : process (i_clk, s_state_out, f_reg(0))
   begin
		case s_state_out is
			-- Idle state - waiting for there to be an error in f_reg(0)
			when s0_out =>
				f_send <= '0';
				f_data <= (others => '0');
			
			-- Transmit first byte of error in f_reg(0) via serial connection (i.e. 39 downto 32)
			when s1_out =>
				f_send <= '1';
				f_data <= f_reg(0)(39 downto 32);
			
			-- Stop transmitting first byte
			when s2_out =>
				f_send <= '0';
				f_data <= f_reg(0)(39 downto 32);
			
			-- Transmit second byte of error in f_reg(0) via serial connection (i.e. 31 downto 24)
			when s3_out =>
				f_send <= '1';
				f_data <= f_reg(0)(31 downto 24);
			
			-- Stop transmitting second byte
			when s4_out =>
				f_send <= '0';
				f_data <= f_reg(0)(31 downto 24);
			
			-- Transmit third byte of error in f_reg(0) via serial connection (i.e. 23 downto 16)
			when s5_out =>
				f_send <= '1';
				f_data <= f_reg(0)(23 downto 16);
			
			-- Stop transmitting third byte
			when s6_out =>
				f_send <= '0';
				f_data <= f_reg(0)(23 downto 16);
			
			-- Transmit fourth byte of error in f_reg(0) via serial connection (i.e. 15 downto 8)
			when s7_out =>
				f_send <= '1';
				f_data <= f_reg(0)(15 downto 8);
			
			-- Stop transmitting fourth byte
			when s8_out =>
				f_send <= '0';
				f_data <= f_reg(0)(15 downto 8);
			
			-- Transmit fifth byte of error in f_reg(0) via serial connection (i.e. 7 downto 0)
			when s9_out =>
				f_send <= '1';
				f_data <= f_reg(0)(7 downto 0);
			
			-- Stop transmitting fifth byte
			when s10_out =>
				f_send <= '0';
				f_data <= f_reg(0)(7 downto 0);
			
			-- Transmit newline character via serial connection
			when s11_out =>
				f_send <= '1';
				f_data <= k_newline;
			
			-- Stop transmitting newline character
			when s12_out =>
				f_send <= '0';
				f_data <= f_reg(0)(7 downto 0);
			
			-- Shift registers down by 1
			when s13_out =>
				f_send <= '0';
				f_data <=(others => '0');
			
			-- An error has occured
			when others =>
				f_send <= '0';
				f_data <=(others => '0');
		end case;
	end process Buffer_output_process;
	
	Buffer_input_process : process(s_state_in)
	begin
		case s_state_in is
			when s0_in =>
				f_ack <= '0';
			when s1_in =>
				f_ack <= '1';
			when others =>
				f_ack <= '0';
		end case;
	end process Buffer_input_process;
end a_Error_Buffer;
