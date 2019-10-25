--| display.vhd
--| Test the functionality of the Basic_MIPS using the MEM_EMULATOR
--| so that the controller can "read" instructions from memory, transition
--| through the appropriate states, and send the proper control signals out
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity display is
	port (i_clk				: in  std_logic;
				i_reset			: in  std_logic;
				i_DONE			: in  std_logic;
				i_CLK_CYCLES	: in  unsigned(31 downto 0);
				i_next			: in  std_logic;
				o_LEDs			: out unsigned(3 downto 0));
end display;

architecture a_display of display is
--| Define signals
	signal f_count	: unsigned (2 downto 0) := (others => '0');
	signal f_LEDs  : unsigned (3 downto 0) := (others => '0');
	signal f_next : std_logic := '0';

	
begin
	o_LEDs <= f_LEDs;
	count_process : process (i_clk, i_reset, i_DONE, i_CLK_CYCLES, i_next)
	begin
		if (i_reset = '1') then
			f_count <= (others => '0');
			f_next <= '0';
		elsif rising_edge(i_clk) then
			f_next <= i_next;
			if (i_DONE = '1') then
				if (i_next = '1') then
					if (f_next = '0') then
						if (f_count = 7) then
							f_count <= (others => '0');
						else
							f_count <= f_count + 1;
						end if;
					else
						f_count <= f_count;
					end if;
				else
					f_count <= f_count;
				end if;
			else
				f_count <= (others => '0');
			end if;
		end if;
	end process;
	
	display_process : process (f_count, i_CLK_CYCLES, i_reset)
	begin
		if (i_reset = '1') then
			f_LEDs <= (others => '0');
		else
			case to_integer(f_count) is
				when 0 =>
					f_LEDs <= i_CLK_CYCLES(3 downto 0);
				when 1 =>
					f_LEDs <= i_CLK_CYCLES(7 downto 4);
				when 2 =>
					f_LEDs <= i_CLK_CYCLES(11 downto 8);
				when 3 =>
					f_LEDs <= i_CLK_CYCLES(15 downto 12);
				when 4 =>
					f_LEDs <= i_CLK_CYCLES(19 downto 16);
				when 5 =>
					f_LEDs <= i_CLK_CYCLES(23 downto 20);
				when 6 =>
					f_LEDs <= i_CLK_CYCLES(27 downto 24);
				when 7 =>
					f_LEDs <= i_CLK_CYCLES(31 downto 28);
				when others =>
					f_LEDs <= (others => '0');
			end case;
		end if;
	end process;
					
end a_display;