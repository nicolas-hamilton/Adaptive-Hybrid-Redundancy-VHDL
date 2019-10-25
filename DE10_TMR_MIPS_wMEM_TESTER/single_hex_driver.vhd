--| single_hex_driver.vhd
--| Based on 4 bit input, display 0 to 15 in hexadecimal
--| on 7-segment display output.
--|  0 - 0
--|  1 - 1
--|  2 - 2
--|  ...
--|  9 - 9
--| 10 - A
--| 11 - b
--| 12 - C
--| 13 - d
--| 14 - E
--| 15 - F
--| to memory.
library IEEE;
use IEEE.std_logic_1164.all;

entity single_hex_driver is
	port (i_clk		: in  std_logic;
			i_reset	: in  std_logic;
			i_data	: in  std_logic_vector(3 downto 0);
			o_HEX		: out std_logic_vector(6 downto 0));
end single_hex_driver;

architecture a_single_hex_driver of single_hex_driver is
	--| Define signals
	signal w_data0_n : std_logic;
	signal w_data1_n : std_logic;
	signal w_data2_n : std_logic;
	signal w_data3_n : std_logic;
	signal w_00 : std_logic;
	signal w_01 : std_logic;
	signal w_02 : std_logic;
	signal w_03 : std_logic;
	signal w_04 : std_logic;
	signal w_05 : std_logic;
	signal w_06 : std_logic;
	signal w_07 : std_logic;
	signal w_08 : std_logic;
	signal w_09 : std_logic;
	signal w_10 : std_logic;
	signal w_11 : std_logic;
	signal w_12 : std_logic;
	signal w_13 : std_logic;
	signal w_14 : std_logic;
	signal w_15 : std_logic;
	signal w_16 : std_logic;
	signal w_17 : std_logic;
	signal w_18 : std_logic;
	signal w_19 : std_logic;
	signal w_20 : std_logic;
	
begin
	w_data0_n <= not i_data(0);
	w_data1_n <= not i_data(1);
	w_data2_n <= not i_data(2);
	w_data3_n <= not i_data(3);
	w_00 <= i_data(2) and i_data(1) and w_data0_n;					
	w_01 <= w_data2_n and w_data1_n and i_data(0);					
	w_02 <= i_data(2) and i_data(1) and i_data(0);					
	w_03 <= w_data3_n and i_data(0);					
	w_04 <= i_data(3) and i_data(1) and i_data(0);					
	w_05 <= w_data3_n and i_data(1) and i_data(0);					
	w_06 <= i_data(3) and i_data(2) and w_data0_n;					
	w_07 <= w_data3_n and w_data2_n and i_data(0);					
	w_08 <= w_data3_n and i_data(2) and w_data1_n;					
	w_09 <= w_data3_n and w_data2_n and i_data(1);					
	w_10 <= w_data3_n and w_data2_n and w_data1_n;					
	w_11 <= w_data3_n and w_data2_n and w_data1_n and i_data(0);					
	w_12 <= w_data3_n and i_data(2) and w_data1_n and w_data0_n;					
	w_13 <= i_data(3) and i_data(2) and w_data1_n and i_data(0);					
	w_14 <= i_data(3) and w_data2_n and i_data(1) and i_data(0);					
	w_15 <= i_data(3) and i_data(2) and w_data1_n and w_data0_n;					
	w_16 <= w_data3_n and i_data(2) and w_data1_n and i_data(0);					
	w_17 <= w_data3_n and w_data2_n and i_data(1) and w_data0_n;					
	w_18 <= i_data(3) and w_data2_n and i_data(1) and w_data0_n;					
	w_19 <= w_data3_n and i_data(2) and i_data(1) and i_data(0);					
	w_20 <= i_data(3) and i_data(2) and i_data(1);					
	o_HEX(0) <= w_11 or w_12 or w_13 or w_14;
	o_HEX(1) <= w_15 or w_16 or w_04 or w_00;
	o_HEX(2) <= w_06 or w_20 or w_17;
	o_HEX(3) <= w_01 or w_12 or w_02 or w_18;
	o_HEX(4) <= w_03 or w_08 or w_01;
	o_HEX(5) <= w_07 or w_09 or w_05 or w_13;
	o_HEX(6) <= w_10 or w_19 or w_15;

end a_single_hex_driver;