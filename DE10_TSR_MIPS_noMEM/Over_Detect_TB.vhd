--| Over_Detect_TB.vhd
--| Test the functionality of the Overflow Detection
library IEEE;
use IEEE.std_logic_1164.all;

entity Over_Detect_TB is
end Over_Detect_TB;

architecture testbench of Over_Detect_TB is
--| Declare Components
	component Over_Detect is
		port (i_AB_NAND	: in  std_logic;
				i_AB_OR		: in  std_logic;
				i_AB_XNOR	: in  std_logic;
				i_S			: in  std_logic_vector(31 downto 0);
				i_RD			: in  std_logic_vector(31 downto 0);
				i_RT			: in  std_logic_vector(31 downto 0);
				i_OVER_CTRL	: in  std_logic_vector(1 downto 0);
				o_Z			: out std_logic_vector(31 downto 0));
	end component;
	
	--| Declare Signals
	signal w_A : std_logic := '0';
	signal w_B : std_logic := '0';
	signal w_AB_NAND : std_logic;
	signal w_AB_OR : std_logic;
	signal w_AB_XNOR : std_logic;
	signal w_S : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_1010_0101_0110_1001";
	signal w_RD : std_logic_vector(31 downto 0) := B"1111_0000_1111_0000_1111_0000_1111_0000";
	signal w_RT : std_logic_vector(31 downto 0) := B"0101_0101_0101_0101_0101_0101_0101_0101";
	signal w_OVER_CTRL : std_logic_vector(1 downto 0) := B"00";
	signal w_Z : std_logic_vector(31 downto 0);
begin
	w_AB_NAND <= w_A NAND w_B;
	w_AB_OR <= w_A OR w_B;
	w_AB_XNOR <= w_A XNOR w_B;

	u_Over_Detect: Over_Detect
	port map(i_AB_NAND => w_AB_NAND,
				i_AB_OR => w_AB_OR,
				i_AB_XNOR => w_AB_XNOR,
				i_S => w_S,
				i_RD => w_RD,
				i_RT => w_RT,
				i_OVER_CTRL => w_OVER_CTRL,
				o_Z => w_Z);
	stimulus: process is
	begin
		-- A, B, and S Positive  - Should not cause an overflow
		wait for 20 ns;
		w_OVER_CTRL <= B"01";
		wait for 20 ns;
		w_OVER_CTRL <= B"10";
		wait for 20 ns;
		w_OVER_CTRL <= B"11";
		wait for 20 ns;
		-- A and B positive, S negative.  Should cause an overflow
		w_OVER_CTRL <= B"00";
		w_S <= B"1100_0000_0000_0000_1010_0101_0110_1001";
		wait for 20 ns;
		w_OVER_CTRL <= B"01";
		wait for 20 ns;
		w_OVER_CTRL <= B"10";
		wait for 20 ns;
		w_OVER_CTRL <= B"11";
		wait for 20 ns;
		-- A and B negative, S negative.  Should not cause an overflow
		w_OVER_CTRL <= B"00";
		w_A <= '1';
		w_B <= '1';
		wait for 20 ns;
		w_OVER_CTRL <= B"01";
		wait for 20 ns;
		w_OVER_CTRL <= B"10";
		wait for 20 ns;
		w_OVER_CTRL <= B"11";
		wait for 20 ns;
		-- A and B negative, S positive.  Should cause an overflow
		w_OVER_CTRL <= B"00";
		w_S <= B"0000_0000_0000_0000_1010_0101_0110_1001";
		wait for 20 ns;
		w_OVER_CTRL <= B"01";
		wait for 20 ns;
		w_OVER_CTRL <= B"10";
		wait for 20 ns;
		w_OVER_CTRL <= B"11";
		wait for 20 ns;
		-- A positive, B negative, and S positive.  Should not cause an overflow.
		w_OVER_CTRL <= B"00";
		w_A <= '0';
		wait for 20 ns;
		w_OVER_CTRL <= B"01";
		wait for 20 ns;
		w_OVER_CTRL <= B"10";
		wait for 20 ns;
		w_OVER_CTRL <= B"11";
		wait for 20 ns;
		-- A positive, B negative, and S negative.  Should not cause an overflow.
		w_OVER_CTRL <= B"00";
		w_S <= B"1100_0000_0000_0000_1010_0101_0110_1001";
		wait for 20 ns;
		w_OVER_CTRL <= B"01";
		wait for 20 ns;
		w_OVER_CTRL <= B"10";
		wait for 20 ns;
		w_OVER_CTRL <= B"11";
		wait for 20 ns;
		-- A negative, B positive, and S negative.  Should not cause an overflow.
		w_OVER_CTRL <= B"00";
		w_A <= '1';
		w_B <= '0';
		wait for 20 ns;
		w_OVER_CTRL <= B"01";
		wait for 20 ns;
		w_OVER_CTRL <= B"10";
		wait for 20 ns;
		w_OVER_CTRL <= B"11";
		wait for 20 ns;
		-- A negative, B positivie, and S positive.  Should not cause an overflow.
		w_OVER_CTRL <= B"00";
		w_S <= B"0000_0000_0000_0000_1010_0101_0110_1001";
		wait for 20 ns;
		w_OVER_CTRL <= B"01";
		wait for 20 ns;
		w_OVER_CTRL <= B"10";
		wait for 20 ns;
		w_OVER_CTRL <= B"11";
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;