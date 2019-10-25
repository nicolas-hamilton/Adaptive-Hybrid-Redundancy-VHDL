--| Decoder5_32.vhd
--| Decodes a 5-bit input signal and activates one of 32 outputs.  For example:
--| 	B"00000" => Z(0) is 1 and other 31 outputs are 0
--| 	B"10100" => Z(20) is 1 and other 31 outputs are 0
--|	
--| INPUTS:
--| i_S - Encoded input signal
--|
--| OUTPUTS:
--| o_Z - Decoded output signal
library IEEE;
use IEEE.std_logic_1164.all;

entity Decoder5_32 is
	port (i_S	: in  std_logic_vector(4 downto 0);
			o_Z	: out std_logic_vector(31 downto 0));
end Decoder5_32;

architecture a_Decoder5_32 of Decoder5_32 is
--| Declare Components
	-- Declare NAND_2
	component myNAND2 is
		port (i_A : in  std_logic;
				i_B : in  std_logic;
				o_Z : out std_logic
				);
	end component;
	-- Declare Inverter
	component myINV is
		port (i_A : in  std_logic;
				o_Z : out std_logic
				);
	end component;

	component myINV_N is
		generic(m_width : integer := 32);  -- Number of bits in the inputs and output
		port (i_A	: in  std_logic_vector(m_width-1 downto 0);
				o_Z	: out std_logic_vector(m_width-1 downto 0));
	end component;
	
	--| Declare Signals
	-- Inverted Input Signals
	signal w_S_n : std_logic_vector(4 downto 0);
	
	-- Intermediate decoder signals
	signal w_dec_00, w_dec_00_n : std_logic;
	signal w_dec_01, w_dec_01_n : std_logic;
	signal w_dec_02, w_dec_02_n : std_logic;
	signal w_dec_03, w_dec_03_n : std_logic;
	signal w_dec_04, w_dec_04_n : std_logic;
	signal w_dec_05, w_dec_05_n : std_logic;
	signal w_dec_06, w_dec_06_n : std_logic;
	signal w_dec_07, w_dec_07_n : std_logic;
	signal w_dec_08, w_dec_08_n : std_logic;
	signal w_dec_09, w_dec_09_n : std_logic;
	signal w_dec_10, w_dec_10_n : std_logic;
	signal w_dec_11, w_dec_11_n : std_logic;
	signal w_dec_12, w_dec_12_n : std_logic;
	signal w_dec_13, w_dec_13_n : std_logic;
	signal w_dec_14, w_dec_14_n : std_logic;
	signal w_dec_15, w_dec_15_n : std_logic;
	signal w_dec_16, w_dec_16_n : std_logic;
	signal w_dec_17, w_dec_17_n : std_logic;
	signal w_dec_18, w_dec_18_n : std_logic;
	signal w_dec_19, w_dec_19_n : std_logic;
	signal w_dec_20, w_dec_20_n : std_logic;
	signal w_dec_21, w_dec_21_n : std_logic;
	signal w_dec_22, w_dec_22_n : std_logic;
	signal w_dec_23, w_dec_23_n : std_logic;
	
	-- Inverted Output Signal
	signal w_Z_n : std_logic_vector(31 downto 0);

begin
	--| Create inverted input signals
	u_myINV_S : myINV_N
	generic map (m_width => 5)
	port map (
		i_A => i_S,
		o_Z => w_S_n);
	
	--| Invert intermediate decoder signals
	u_myINV_00 : myINV
	port map (
		i_A => w_dec_00,
		o_Z => w_dec_00_n);
		
	u_myINV_01 : myINV
	port map (
		i_A => w_dec_01,
		o_Z => w_dec_01_n);
		
	u_myINV_02 : myINV
	port map (
		i_A => w_dec_02,
		o_Z => w_dec_02_n);
		
	u_myINV_03 : myINV
	port map (
		i_A => w_dec_03,
		o_Z => w_dec_03_n);
		
	u_myINV_04 : myINV
	port map (
		i_A => w_dec_04,
		o_Z => w_dec_04_n);
		
	u_myINV_05 : myINV
	port map (
		i_A => w_dec_05,
		o_Z => w_dec_05_n);
		
	u_myINV_06 : myINV
	port map (
		i_A => w_dec_06,
		o_Z => w_dec_06_n);
		
	u_myINV_07 : myINV
	port map (
		i_A => w_dec_07,
		o_Z => w_dec_07_n);
		
	u_myINV_08 : myINV
	port map (
		i_A => w_dec_08,
		o_Z => w_dec_08_n);
		
	u_myINV_09 : myINV
	port map (
		i_A => w_dec_09,
		o_Z => w_dec_09_n);
		
	u_myINV_10 : myINV
	port map (
		i_A => w_dec_10,
		o_Z => w_dec_10_n);
		
	u_myINV_11 : myINV
	port map (
		i_A => w_dec_11,
		o_Z => w_dec_11_n);
		
	u_myINV_12 : myINV
	port map (
		i_A => w_dec_12,
		o_Z => w_dec_12_n);
		
	u_myINV_13 : myINV
	port map (
		i_A => w_dec_13,
		o_Z => w_dec_13_n);
		
	u_myINV_14 : myINV
	port map (
		i_A => w_dec_14,
		o_Z => w_dec_14_n);
		
	u_myINV_15 : myINV
	port map (
		i_A => w_dec_15,
		o_Z => w_dec_15_n);
		
	u_myINV_16 : myINV
	port map (
		i_A => w_dec_16,
		o_Z => w_dec_16_n);
		
	u_myINV_17 : myINV
	port map (
		i_A => w_dec_17,
		o_Z => w_dec_17_n);
		
	u_myINV_18 : myINV
	port map (
		i_A => w_dec_18,
		o_Z => w_dec_18_n);
		
	u_myINV_19 : myINV
	port map (
		i_A => w_dec_19,
		o_Z => w_dec_19_n);
		
	u_myINV_20 : myINV
	port map (
		i_A => w_dec_20,
		o_Z => w_dec_20_n);
		
	u_myINV_21 : myINV
	port map (
		i_A => w_dec_21,
		o_Z => w_dec_21_n);
		
	u_myINV_22 : myINV
	port map (
		i_A => w_dec_22,
		o_Z => w_dec_22_n);
		
	u_myINV_23 : myINV
	port map (
		i_A => w_dec_23,
		o_Z => w_dec_23_n);
	
	--| Instantiate NAND gates to create intermediate control signals
	u_myNAND_00 : myNAND2
	port map (
		i_A => w_S_n(4),
		i_B => w_S_n(3),
		o_Z => w_dec_00);
		
	u_myNAND_01 : myNAND2
	port map (
		i_A => w_S_n(2),
		i_B => w_S_n(1),
		o_Z => w_dec_01);
		
	u_myNAND_02 : myNAND2
	port map (
		i_A => w_dec_00_n,
		i_B => w_dec_01_n,
		o_Z => w_dec_02);
		
	u_myNAND_03 : myNAND2
	port map (
		i_A => w_S_n(2),
		i_B => i_S(1),
		o_Z => w_dec_03);
		
	u_myNAND_04 : myNAND2
	port map (
		i_A => w_dec_00_n,
		i_B => w_dec_03_n,
		o_Z => w_dec_04);
		
	u_myNAND_05 : myNAND2
	port map (
		i_A => i_S(2),
		i_B => w_S_n(1),
		o_Z => w_dec_05);
		
	u_myNAND_06 : myNAND2
	port map (
		i_A => w_dec_00_n,
		i_B => w_dec_05_n,
		o_Z => w_dec_06);
		
	u_myNAND_07 : myNAND2
	port map (
		i_A => i_S(2),
		i_B => i_S(1),
		o_Z => w_dec_07);
		
	u_myNAND_08 : myNAND2
	port map (
		i_A => w_dec_00_n,
		i_B => w_dec_07_n,
		o_Z => w_dec_08);
		
	u_myNAND_09 : myNAND2
	port map (
		i_A => w_S_n(4),
		i_B => i_S(3),
		o_Z => w_dec_09);
		
	u_myNAND_10 : myNAND2
	port map (
		i_A => w_dec_09_n,
		i_B => w_dec_01_n,
		o_Z => w_dec_10);
		
	u_myNAND_11 : myNAND2
	port map (
		i_A => w_dec_09_n,
		i_B => w_dec_03_n,
		o_Z => w_dec_11);
		
	u_myNAND_12 : myNAND2
	port map (
		i_A => w_dec_09_n,
		i_B => w_dec_05_n,
		o_Z => w_dec_12);
		
	u_myNAND_13 : myNAND2
	port map (
		i_A => w_dec_09_n,
		i_B => w_dec_07_n,
		o_Z => w_dec_13);
		
	u_myNAND_14 : myNAND2
	port map (
		i_A => i_S(4),
		i_B => w_S_n(3),
		o_Z => w_dec_14);
		
	u_myNAND_15 : myNAND2
	port map (
		i_A => w_dec_14_n,
		i_B => w_dec_01_n,
		o_Z => w_dec_15);
		
	u_myNAND_16 : myNAND2
	port map (
		i_A => w_dec_14_n,
		i_B => w_dec_03_n,
		o_Z => w_dec_16);
		
	u_myNAND_17 : myNAND2
	port map (
		i_A => w_dec_14_n,
		i_B => w_dec_05_n,
		o_Z => w_dec_17);
		
	u_myNAND_18 : myNAND2
	port map (
		i_A => w_dec_14_n,
		i_B => w_dec_07_n,
		o_Z => w_dec_18);
		
	u_myNAND_19 : myNAND2
	port map (
		i_A => i_S(4),
		i_B => i_S(3),
		o_Z => w_dec_19);
		
	u_myNAND_20 : myNAND2
	port map (
		i_A => w_dec_19_n,
		i_B => w_dec_01_n,
		o_Z => w_dec_20);
		
	u_myNAND_21 : myNAND2
	port map (
		i_A => w_dec_19_n,
		i_B => w_dec_03_n,
		o_Z => w_dec_21);
		
	u_myNAND_22 : myNAND2
	port map (
		i_A => w_dec_19_n,
		i_B => w_dec_05_n,
		o_Z => w_dec_22);
		
	u_myNAND_23 : myNAND2
	port map (
		i_A => w_dec_19_n,
		i_B => w_dec_07_n,
		o_Z => w_dec_23);
		
	--| Instantiate Inverters and NAND gates to generate output signals
	u_myNAND_Z0 : myNAND2
	port map (
		i_A => w_dec_02_n,
		i_B => w_S_n(0),
		o_Z => w_Z_n(0));
		
	u_myNAND_Z1 : myNAND2
	port map (
		i_A => w_dec_02_n,
		i_B => i_S(0),
		o_Z => w_Z_n(1));
		
	u_myNAND_Z2 : myNAND2
	port map (
		i_A => w_dec_04_n,
		i_B => w_S_n(0),
		o_Z => w_Z_n(2));
		
	u_myNAND_Z3 : myNAND2
	port map (
		i_A => w_dec_04_n,
		i_B => i_S(0),
		o_Z => w_Z_n(3));
		
	u_myNAND_Z4 : myNAND2
	port map (
		i_A => w_dec_06_n,
		i_B => w_S_n(0),
		o_Z => w_Z_n(4));
		
	u_myNAND_Z5 : myNAND2
	port map (
		i_A => w_dec_06_n,
		i_B => i_S(0),
		o_Z => w_Z_n(5));
		
	u_myNAND_Z6 : myNAND2
	port map (
		i_A => w_dec_08_n,
		i_B => w_S_n(0),
		o_Z => w_Z_n(6));
		
	u_myNAND_Z7 : myNAND2
	port map (
		i_A => w_dec_08_n,
		i_B => i_S(0),
		o_Z => w_Z_n(7));
		
	u_myNAND_Z8 : myNAND2
	port map (
		i_A => w_dec_10_n,
		i_B => w_S_n(0),
		o_Z => w_Z_n(8));
		
	u_myNAND_Z9 : myNAND2
	port map (
		i_A => w_dec_10_n,
		i_B => i_S(0),
		o_Z => w_Z_n(9));
		
	u_myNAND_Z10 : myNAND2
	port map (
		i_A => w_dec_11_n,
		i_B => w_S_n(0),
		o_Z => w_Z_n(10));
		
	u_myNAND_Z11 : myNAND2
	port map (
		i_A => w_dec_11_n,
		i_B => i_S(0),
		o_Z => w_Z_n(11));
		
	u_myNAND_Z12 : myNAND2
	port map (
		i_A => w_dec_12_n,
		i_B => w_S_n(0),
		o_Z => w_Z_n(12));
		
	u_myNAND_Z13 : myNAND2
	port map (
		i_A => w_dec_12_n,
		i_B => i_S(0),
		o_Z => w_Z_n(13));
		
	u_myNAND_Z14 : myNAND2
	port map (
		i_A => w_dec_13_n,
		i_B => w_S_n(0),
		o_Z => w_Z_n(14));
		
	u_myNAND_Z15 : myNAND2
	port map (
		i_A => w_dec_13_n,
		i_B => i_S(0),
		o_Z => w_Z_n(15));
		
	u_myNAND_Z16 : myNAND2
	port map (
		i_A => w_dec_15_n,
		i_B => w_S_n(0),
		o_Z => w_Z_n(16));
		
	u_myNAND_Z17 : myNAND2
	port map (
		i_A => w_dec_15_n,
		i_B => i_S(0),
		o_Z => w_Z_n(17));
		
	u_myNAND_Z18 : myNAND2
	port map (
		i_A => w_dec_16_n,
		i_B => w_S_n(0),
		o_Z => w_Z_n(18));
		
	u_myNAND_Z19 : myNAND2
	port map (
		i_A => w_dec_16_n,
		i_B => i_S(0),
		o_Z => w_Z_n(19));
		
	u_myNAND_Z20 : myNAND2
	port map (
		i_A => w_dec_17_n,
		i_B => w_S_n(0),
		o_Z => w_Z_n(20));
		
	u_myNAND_Z21 : myNAND2
	port map (
		i_A => w_dec_17_n,
		i_B => i_S(0),
		o_Z => w_Z_n(21));
		
	u_myNAND_Z22 : myNAND2
	port map (
		i_A => w_dec_18_n,
		i_B => w_S_n(0),
		o_Z => w_Z_n(22));
		
	u_myNAND_Z23 : myNAND2
	port map (
		i_A => w_dec_18_n,
		i_B => i_S(0),
		o_Z => w_Z_n(23));
		
	u_myNAND_Z24 : myNAND2
	port map (
		i_A => w_dec_20_n,
		i_B => w_S_n(0),
		o_Z => w_Z_n(24));
		
	u_myNAND_Z25 : myNAND2
	port map (
		i_A => w_dec_20_n,
		i_B => i_S(0),
		o_Z => w_Z_n(25));
		
	u_myNAND_Z26 : myNAND2
	port map (
		i_A => w_dec_21_n,
		i_B => w_S_n(0),
		o_Z => w_Z_n(26));
		
	u_myNAND_Z27 : myNAND2
	port map (
		i_A => w_dec_21_n,
		i_B => i_S(0),
		o_Z => w_Z_n(27));
		
	u_myNAND_Z28 : myNAND2
	port map (
		i_A => w_dec_22_n,
		i_B => w_S_n(0),
		o_Z => w_Z_n(28));
		
	u_myNAND_Z29 : myNAND2
	port map (
		i_A => w_dec_22_n,
		i_B => i_S(0),
		o_Z => w_Z_n(29));
		
	u_myNAND_Z30 : myNAND2
	port map (
		i_A => w_dec_23_n,
		i_B => w_S_n(0),
		o_Z => w_Z_n(30));
		
	u_myNAND_Z31 : myNAND2
	port map (
		i_A => w_dec_23_n,
		i_B => i_S(0),
		o_Z => w_Z_n(31));
		
	-- Create output signal
	u_myINV_Z : myINV_N
	generic map (m_width => 32)
	port map (
		i_A => w_Z_n,
		o_Z => o_Z);
end a_Decoder5_32;