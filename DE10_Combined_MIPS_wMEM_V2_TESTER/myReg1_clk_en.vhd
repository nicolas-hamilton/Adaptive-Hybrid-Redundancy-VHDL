--| myReg1_clk_en.vhd
--| 1-bit register
--|
--| INPUTS:
--| i_clk	- Clock
--| i_reset	- Reset
--| i_D		- Data
--|
--| OUTPUTS:
--| o_Q - Output
library IEEE;
use IEEE.std_logic_1164.all;

entity myReg1_clk_en is
	port (i_clk		: in  std_logic;
			i_reset	: in  std_logic;
			i_clk_en	: in  std_logic;
			i_D		: in  std_logic;
			o_Q		: out std_logic);
end myReg1_clk_en;

architecture a_myReg1_clk_en of myReg1_clk_en is	
--| Declare signals
	signal f_data : std_logic := '0';
begin
	o_Q <= f_data;

	d_flip_flop: process(i_clk, i_reset)
	begin
		if (i_reset = '1') then
			f_data <= '0';
		elsif (rising_edge(i_clk) and (i_clk_en = '1')) then
			f_data <= i_D;
		end if;
	end process;
end a_myReg1_clk_en;