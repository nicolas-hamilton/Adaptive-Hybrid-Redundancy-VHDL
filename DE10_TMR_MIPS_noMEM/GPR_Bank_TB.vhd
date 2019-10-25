--| GPR_Bank_TB.vhd
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

entity GPR_Bank_TB is
end GPR_Bank_TB;

architecture test_bench of GPR_Bank_TB is	
--| Declare Components
	component GPR_Bank is
		port (i_clk		: in  std_logic;
				i_reset	: in  std_logic;
				i_data	: in  std_logic_vector(31 downto 0);
				i_sel		: in  std_logic_vector(4 downto 0);
				o_Q00		: out std_logic_vector(31 downto 0);
				o_Q01		: out std_logic_vector(31 downto 0);
				o_Q02		: out std_logic_vector(31 downto 0);
				o_Q03		: out std_logic_vector(31 downto 0);
				o_Q04		: out std_logic_vector(31 downto 0);
				o_Q05		: out std_logic_vector(31 downto 0);
				o_Q06		: out std_logic_vector(31 downto 0);
				o_Q07		: out std_logic_vector(31 downto 0);
				o_Q08		: out std_logic_vector(31 downto 0);
				o_Q09		: out std_logic_vector(31 downto 0);
				o_Q10		: out std_logic_vector(31 downto 0);
				o_Q11		: out std_logic_vector(31 downto 0);
				o_Q12		: out std_logic_vector(31 downto 0);
				o_Q13		: out std_logic_vector(31 downto 0);
				o_Q14		: out std_logic_vector(31 downto 0);
				o_Q15		: out std_logic_vector(31 downto 0);
				o_Q16		: out std_logic_vector(31 downto 0);
				o_Q17		: out std_logic_vector(31 downto 0);
				o_Q18		: out std_logic_vector(31 downto 0);
				o_Q19		: out std_logic_vector(31 downto 0);
				o_Q20		: out std_logic_vector(31 downto 0);
				o_Q21		: out std_logic_vector(31 downto 0);
				o_Q22		: out std_logic_vector(31 downto 0);
				o_Q23		: out std_logic_vector(31 downto 0);
				o_Q24		: out std_logic_vector(31 downto 0);
				o_Q25		: out std_logic_vector(31 downto 0);
				o_Q26		: out std_logic_vector(31 downto 0);
				o_Q27		: out std_logic_vector(31 downto 0);
				o_Q28		: out std_logic_vector(31 downto 0);
				o_Q29		: out std_logic_vector(31 downto 0);
				o_Q30		: out std_logic_vector(31 downto 0);
				o_Q31		: out std_logic_vector(31 downto 0));
	end component;
	
--| Declare Signals

	signal c_clk : std_logic := '0';
	signal w_reset : std_logic := '1';
	signal w_data : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_0000_0000_0001";
	signal w_sel : std_logic_vector(4 downto 0) := (others => '0');
	signal w_Q00 : std_logic_vector(31 downto 0);
	signal w_Q01 : std_logic_vector(31 downto 0);
	signal w_Q02 : std_logic_vector(31 downto 0);
	signal w_Q03 : std_logic_vector(31 downto 0);
	signal w_Q04 : std_logic_vector(31 downto 0);
	signal w_Q05 : std_logic_vector(31 downto 0);
	signal w_Q06 : std_logic_vector(31 downto 0);
	signal w_Q07 : std_logic_vector(31 downto 0);
	signal w_Q08 : std_logic_vector(31 downto 0);
	signal w_Q09 : std_logic_vector(31 downto 0);
	signal w_Q10 : std_logic_vector(31 downto 0);
	signal w_Q11 : std_logic_vector(31 downto 0);
	signal w_Q12 : std_logic_vector(31 downto 0);
	signal w_Q13 : std_logic_vector(31 downto 0);
	signal w_Q14 : std_logic_vector(31 downto 0);
	signal w_Q15 : std_logic_vector(31 downto 0);
	signal w_Q16 : std_logic_vector(31 downto 0);
	signal w_Q17 : std_logic_vector(31 downto 0);
	signal w_Q18 : std_logic_vector(31 downto 0);
	signal w_Q19 : std_logic_vector(31 downto 0);
	signal w_Q20 : std_logic_vector(31 downto 0);
	signal w_Q21 : std_logic_vector(31 downto 0);
	signal w_Q22 : std_logic_vector(31 downto 0);
	signal w_Q23 : std_logic_vector(31 downto 0);
	signal w_Q24 : std_logic_vector(31 downto 0);
	signal w_Q25 : std_logic_vector(31 downto 0);
	signal w_Q26 : std_logic_vector(31 downto 0);
	signal w_Q27 : std_logic_vector(31 downto 0);
	signal w_Q28 : std_logic_vector(31 downto 0);
	signal w_Q29 : std_logic_vector(31 downto 0);
	signal w_Q30 : std_logic_vector(31 downto 0);
	signal w_Q31 : std_logic_vector(31 downto 0);
begin
	-- Connect the GPR_BANK
	u_GPR_BANK: GPR_BANK
	port map (i_clk => c_clk,
				 i_reset => w_reset,
				 i_data => w_data,
				 i_sel => w_sel,
				 o_Q00 => w_Q00,
				 o_Q01 => w_Q01,
				 o_Q02 => w_Q02,
				 o_Q03 => w_Q03,
				 o_Q04 => w_Q04,
				 o_Q05 => w_Q05,
				 o_Q06 => w_Q06,
				 o_Q07 => w_Q07,
				 o_Q08 => w_Q08,
				 o_Q09 => w_Q09,
				 o_Q10 => w_Q10,
				 o_Q11 => w_Q11,
				 o_Q12 => w_Q12,
				 o_Q13 => w_Q13,
				 o_Q14 => w_Q14,
				 o_Q15 => w_Q15,
				 o_Q16 => w_Q16,
				 o_Q17 => w_Q17,
				 o_Q18 => w_Q18,
				 o_Q19 => w_Q19,
				 o_Q20 => w_Q20,
				 o_Q21 => w_Q21,
				 o_Q22 => w_Q22,
				 o_Q23 => w_Q23,
				 o_Q24 => w_Q24,
				 o_Q25 => w_Q25,
				 o_Q26 => w_Q26,
				 o_Q27 => w_Q27,
				 o_Q28 => w_Q28,
				 o_Q29 => w_Q29,
				 o_Q30 => w_Q30,
				 o_Q31 => w_Q31);
				 
	stimulus : process
   begin
		wait for 100 ns;
		w_reset <= '0';
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0000_0000_0010";
		w_sel <= B"00001";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0000_0000_0100";
		w_sel <= B"00010";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0000_0000_1000";
		w_sel <= B"00011";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0000_0001_0000";
		w_sel <= B"00100";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0000_0010_0000";
		w_sel <= B"00101";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0000_0100_0000";
		w_sel <= B"00110";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0000_1000_0000";
		w_sel <= B"00111";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0001_0000_0000";
		w_sel <= B"01000";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0010_0000_0000";
		w_sel <= B"01001";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_0100_0000_0000";
		w_sel <= B"01010";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0000_1000_0000_0000";
		w_sel <= B"01011";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0001_0000_0000_0000";
		w_sel <= B"01100";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0010_0000_0000_0000";
		w_sel <= B"01101";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_0100_0000_0000_0000";
		w_sel <= B"01110";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0000_1000_0000_0000_0000";
		w_sel <= B"01111";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0001_0000_0000_0000_0000";
		w_sel <= B"10000";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0010_0000_0000_0000_0000";
		w_sel <= B"10001";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_0100_0000_0000_0000_0000";
		w_sel <= B"10010";
		wait for 20 ns;
		w_data <= B"0000_0000_0000_1000_0000_0000_0000_0000";
		w_sel <= B"10011";
		wait for 20 ns;
		w_data <= B"0000_0000_0001_0000_0000_0000_0000_0000";
		w_sel <= B"10100";
		wait for 20 ns;
		w_data <= B"0000_0000_0010_0000_0000_0000_0000_0000";
		w_sel <= B"10101";
		wait for 20 ns;
		w_data <= B"0000_0000_0100_0000_0000_0000_0000_0000";
		w_sel <= B"10110";
		wait for 20 ns;
		w_data <= B"0000_0000_1000_0000_0000_0000_0000_0000";
		w_sel <= B"10111";
		wait for 20 ns;
		w_data <= B"0000_0001_0000_0000_0000_0000_0000_0000";
		w_sel <= B"11000";
		wait for 20 ns;
		w_data <= B"0000_0010_0000_0000_0000_0000_0000_0000";
		w_sel <= B"11001";
		wait for 20 ns;
		w_data <= B"0000_0100_0000_0000_0000_0000_0000_0000";
		w_sel <= B"11010";
		wait for 20 ns;
		w_data <= B"0000_1000_0000_0000_0000_0000_0000_0000";
		w_sel <= B"11011";
		wait for 20 ns;
		w_data <= B"0001_0000_0000_0000_0000_0000_0000_0000";
		w_sel <= B"11100";
		wait for 20 ns;
		w_data <= B"0010_0000_0000_0000_0000_0000_0000_0000";
		w_sel <= B"11101";
		wait for 20 ns;
		w_data <= B"0100_0000_0000_0000_0000_0000_0000_0000";
		w_sel <= B"11110";
		wait for 20 ns;
		w_data <= B"1000_0000_0000_0000_0000_0000_0000_0000";
		w_sel <= B"11111";
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