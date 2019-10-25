--| Comparator.vhd
--| Compare the input to zero and create equal, not equal, less than, less than or equal
--| to, greater than, and greater than or equal to signals.  Additionally, accept a control
--| signal that determines which of these signals should be output.  In the event that an
--| overflow occurs in the adder, the MSB of inputs A and B to the adder must be utilized
--| to determine if an overflow has occured.  This also depends on whether the operation
--| was a signed or unsigned operation.  The branch operations and set-on-less-than
--| (immediate) instructions all make use of signed values while the set-on-less-than
--| (immediate) unsigned operations make use of unsigned values.
--|	
--| INPUTS:
--| i_S - Data to compare to zero
--| i_NAND_AB	- AND(A(31),B(31))
--| i_OR_AB		- OR(A(31),B(31))
--| i_XNOR_AB	- XNOR(A(31),B(31))
--| i_unsigned - 1 if the adder operands are unsigned and 0 if they are signed
--| i_overflow	- Determine if the comparator is performing a Less Than comparison that will
--|              or will not produce an overflow.  No overflow can occur in BLTZ instructions,
--|				  but overflow can occur in SLT, SLTU, SLTI, and SLTIU instructions.  0 - no
--|				  overflow can occur, 1 - overflow can occur
--| i_COMP_SEL - Determine which of the signals to output.
--|	0 - Greater than or equal to zero
--|	1 - Less than zero
--|	2 - Equal to zero
--|	3 - Not equal to zero
--|	4 - Less than or equal to zero
--|	5 - Greater than zero
--|	6,7 - Greater than or equal to zero
--|
--| OUTPUTS:
--| o_Z - Selected comparison
library IEEE;
use IEEE.std_logic_1164.all;

entity Comparator is
	port (i_S			: in  std_logic_vector(31 downto 0);
			i_NAND_AB	: in  std_logic;
			i_OR_AB		: in  std_logic;
			i_XNOR_AB	: in  std_logic;
			i_unsigned	: in  std_logic;
			i_overflow	: in  std_logic;
			i_COMP_SEL	: in  std_logic_vector(2 downto 0);
			o_Z			: out std_logic);
end Comparator;

architecture a_Comparator of Comparator is
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
	
	-- Declare 2 input, 1-bit mux
	component myMUX2_1 is
		port (i_0 : in  std_logic;
				i_1 : in  std_logic;
				i_S : in  std_logic;
				o_Z : out std_logic
				);
	end component;
	
	-- Declare 8 input, 1-bit mux
	component myMUX8_1 is
		port (i_0 : in  std_logic;
				i_1 : in  std_logic;
				i_2 : in  std_logic;
				i_3 : in  std_logic;
				i_4 : in  std_logic;
				i_5 : in  std_logic;
				i_6 : in  std_logic;
				i_7 : in  std_logic;
				i_S : in  std_logic_vector(2 downto 0);
				o_Z : out std_logic
				);
	end component;
	
	--| Declare Signals
	signal w_GEZ						: std_logic; --w_GEZ0, w_GEZ1, w_GEZ	: std_logic; -- Greater than or equal to zero
	signal w_LTZ0, w_LTZ1, w_LTZ	: std_logic; -- Less than zero
	signal w_EQ							: std_logic; --w_EQ0, 	w_EQ				: std_logic; -- Equal to zero
	signal w_NE							: std_logic; --w_NE0, 	w_NE				: std_logic; -- Not equal to zero
	signal w_LEZ						: std_logic; --w_LEZ0, w_LEZ				: std_logic; -- Less than or equal to zero
	signal w_GTZ						: std_logic; --w_GTZ0, w_GTZ				: std_logic; -- Greater than zero
	-- Inverted Input Signals
	signal w_S31_n	: std_logic;
	signal w_S30_n	: std_logic;
	signal w_S29_n	: std_logic;
	signal w_S28_n	: std_logic;
	signal w_S27_n	: std_logic;
	signal w_S26_n	: std_logic;
	signal w_S25_n	: std_logic;
	signal w_S24_n	: std_logic;
	signal w_S23_n	: std_logic;
	signal w_S22_n	: std_logic;
	signal w_S21_n	: std_logic;
	signal w_S20_n	: std_logic;
	signal w_S19_n	: std_logic;
	signal w_S18_n	: std_logic;
	signal w_S17_n	: std_logic;
	signal w_S16_n	: std_logic;
	signal w_S15_n	: std_logic;
	signal w_S14_n	: std_logic;
	signal w_S13_n	: std_logic;
	signal w_S12_n	: std_logic;
	signal w_S11_n	: std_logic;
	signal w_S10_n	: std_logic;
	signal w_S09_n	: std_logic;
	signal w_S08_n	: std_logic;
	signal w_S07_n	: std_logic;
	signal w_S06_n	: std_logic;
	signal w_S05_n	: std_logic;
	signal w_S04_n	: std_logic;
	signal w_S03_n	: std_logic;
	signal w_S02_n	: std_logic;
	signal w_S01_n	: std_logic;
	signal w_S00_n	: std_logic;
	
	-- Intermediate terms in the 32-bit OR function
	signal w_S31_30, w_S31_30_n : std_logic;
	signal w_S29_28, w_S29_28_n : std_logic;
	signal w_S27_26, w_S27_26_n : std_logic;
	signal w_S25_24, w_S25_24_n : std_logic;
	signal w_S23_22, w_S23_22_n : std_logic;
	signal w_S21_20, w_S21_20_n : std_logic;
	signal w_S19_18, w_S19_18_n : std_logic;
	signal w_S17_16, w_S17_16_n : std_logic;
	signal w_S15_14, w_S15_14_n : std_logic;
	signal w_S13_12, w_S13_12_n : std_logic;
	signal w_S11_10, w_S11_10_n : std_logic;
	signal w_S09_08, w_S09_08_n : std_logic;
	signal w_S07_06, w_S07_06_n : std_logic;
	signal w_S05_04, w_S05_04_n : std_logic;
	signal w_S03_02, w_S03_02_n : std_logic;
	signal w_S01_00, w_S01_00_n : std_logic;
	
	signal w_S31_28, w_S31_28_n : std_logic;
	signal w_S27_24, w_S27_24_n : std_logic;
	signal w_S23_20, w_S23_20_n : std_logic;
	signal w_S19_16, w_S19_16_n : std_logic;
	signal w_S15_12, w_S15_12_n : std_logic;
	signal w_S11_08, w_S11_08_n : std_logic;
	signal w_S07_04, w_S07_04_n : std_logic;
	signal w_S03_00, w_S03_00_n : std_logic;
	
	signal w_S31_24, w_S31_24_n : std_logic;
	signal w_S23_16, w_S23_16_n : std_logic;
	signal w_S15_08, w_S15_08_n : std_logic;
	signal w_S07_00, w_S07_00_n : std_logic;
	
	signal w_S31_16, w_S31_16_n : std_logic;
	signal w_S15_00, w_S15_00_n : std_logic;
	-- Result of the 32-bit or function
	signal w_S_OR : std_logic;
	-- Intermediate signals to determine comparisons when an overflow is possible
--	signal w_comp0 : std_logic;
--	signal w_comp1 : std_logic;
--	signal w_comp2, w_comp2_n : std_logic;
--	signal w_comp3 : std_logic;
	signal w_comp4 : std_logic;
	signal w_comp5 : std_logic;
	signal w_comp6, w_comp6_n : std_logic;
	signal w_comp7 : std_logic;
	signal w_unsigned_n : std_logic; -- inverted i_unsigned
	signal w_overcheck : std_logic;
	signal w_overcheck_n : std_logic;
	
	-- Define Constants
	constant k_zero	: std_logic := '0'; -- w_EQ
	constant k_one		: std_logic := '1';
begin
	-- If i_S(31) is 1, the incoming number is negative and therefore less than 0.
	-- However, this can be erroneous if an overflow occured.  Another means is
	-- used to handle overflows and override this value
	w_LTZ0 <= i_S(31);
	
	--| Instantiate Inverters to create inverted signals
	u_myINV_31 : myINV
	port map (
		i_A => i_S(31),
		o_Z => w_S31_n);
		
	u_myINV_30 : myINV
	port map (
		i_A => i_S(30),
		o_Z => w_S30_n);
		
	u_myINV_29 : myINV
	port map (
		i_A => i_S(29),
		o_Z => w_S29_n);
		
	u_myINV_28 : myINV
	port map (
		i_A => i_S(28),
		o_Z => w_S28_n);
		
	u_myINV_27 : myINV
	port map (
		i_A => i_S(27),
		o_Z => w_S27_n);
		
	u_myINV_26 : myINV
	port map (
		i_A => i_S(26),
		o_Z => w_S26_n);
		
	u_myINV_25 : myINV
	port map (
		i_A => i_S(25),
		o_Z => w_S25_n);
	
	u_myINV_24 : myINV
	port map (
		i_A => i_S(24),
		o_Z => w_S24_n);
		
	u_myINV_23 : myINV
	port map (
		i_A => i_S(23),
		o_Z => w_S23_n);
		
	u_myINV_22 : myINV
	port map (
		i_A => i_S(22),
		o_Z => w_S22_n);
		
	u_myINV_21 : myINV
	port map (
		i_A => i_S(21),
		o_Z => w_S21_n);
		
	u_myINV_20 : myINV
	port map (
		i_A => i_S(20),
		o_Z => w_S20_n);
		
	u_myINV_19 : myINV
	port map (
		i_A => i_S(19),
		o_Z => w_S19_n);
		
	u_myINV_18 : myINV
	port map (
		i_A => i_S(18),
		o_Z => w_S18_n);
		
	u_myINV_17 : myINV
	port map (
		i_A => i_S(17),
		o_Z => w_S17_n);
		
	u_myINV_16 : myINV
	port map (
		i_A => i_S(16),
		o_Z => w_S16_n);
		
	u_myINV_15 : myINV
	port map (
		i_A => i_S(15),
		o_Z => w_S15_n);
	
	u_myINV_14 : myINV
	port map (
		i_A => i_S(14),
		o_Z => w_S14_n);
		
	u_myINV_13 : myINV
	port map (
		i_A => i_S(13),
		o_Z => w_S13_n);
		
	u_myINV_12 : myINV
	port map (
		i_A => i_S(12),
		o_Z => w_S12_n);
		
	u_myINV_11 : myINV
	port map (
		i_A => i_S(11),
		o_Z => w_S11_n);
		
	u_myINV_10 : myINV
	port map (
		i_A => i_S(10),
		o_Z => w_S10_n);
		
	u_myINV_09 : myINV
	port map (
		i_A => i_S(9),
		o_Z => w_S09_n);
		
	u_myINV_08 : myINV
	port map (
		i_A => i_S(8),
		o_Z => w_S08_n);
		
	u_myINV_07 : myINV
	port map (
		i_A => i_S(7),
		o_Z => w_S07_n);
		
	u_myINV_06 : myINV
	port map (
		i_A => i_S(6),
		o_Z => w_S06_n);
		
	u_myINV_05 : myINV
	port map (
		i_A => i_S(05),
		o_Z => w_S05_n);
	
	u_myINV_04 : myINV
	port map (
		i_A => i_S(4),
		o_Z => w_S04_n);
		
	u_myINV_03 : myINV
	port map (
		i_A => i_S(3),
		o_Z => w_S03_n);
		
	u_myINV_02 : myINV
	port map (
		i_A => i_S(2),
		o_Z => w_S02_n);
		
	u_myINV_01 : myINV
	port map (
		i_A => i_S(1),
		o_Z => w_S01_n);
		
	u_myINV_00 : myINV
	port map (
		i_A => i_S(0),
		o_Z => w_S00_n);
		
	u_myINV_31_30 : myINV
	port map (
		i_A => w_S31_30,
		o_Z => w_S31_30_n);
		
	u_myINV_29_28 : myINV
	port map (
		i_A => w_S29_28,
		o_Z => w_S29_28_n);
		
	u_myINV_27_26 : myINV
	port map (
		i_A => w_S27_26,
		o_Z => w_S27_26_n);
		
	u_myINV_25_24 : myINV
	port map (
		i_A => w_S25_24,
		o_Z => w_S25_24_n);
		
	u_myINV_23_22 : myINV
	port map (
		i_A => w_S23_22,
		o_Z => w_S23_22_n);
		
	u_myINV_21_20 : myINV
	port map (
		i_A => w_S21_20,
		o_Z => w_S21_20_n);
		
	u_myINV_19_18 : myINV
	port map (
		i_A => w_S19_18,
		o_Z => w_S19_18_n);
		
	u_myINV_17_16 : myINV
	port map (
		i_A => w_S17_16,
		o_Z => w_S17_16_n);
		
	u_myINV_15_14 : myINV
	port map (
		i_A => w_S15_14,
		o_Z => w_S15_14_n);
		
	u_myINV_13_12 : myINV
	port map (
		i_A => w_S13_12,
		o_Z => w_S13_12_n);
		
	u_myINV_11_10 : myINV
	port map (
		i_A => w_S11_10,
		o_Z => w_S11_10_n);
		
	u_myINV_09_08 : myINV
	port map (
		i_A => w_S09_08,
		o_Z => w_S09_08_n);
		
	u_myINV_07_06 : myINV
	port map (
		i_A => w_S07_06,
		o_Z => w_S07_06_n);
		
	u_myINV_05_04 : myINV
	port map (
		i_A => w_S05_04,
		o_Z => w_S05_04_n);
		
	u_myINV_03_02 : myINV
	port map (
		i_A => w_S03_02,
		o_Z => w_S03_02_n);
		
	u_myINV_01_00 : myINV
	port map (
		i_A => w_S01_00,
		o_Z => w_S01_00_n);
		
	u_myINV_31_28 : myINV
	port map (
		i_A => w_S31_28,
		o_Z => w_S31_28_n);
		
	u_myINV_27_24 : myINV
	port map (
		i_A => w_S27_24,
		o_Z => w_S27_24_n);
		
	u_myINV_23_20 : myINV
	port map (
		i_A => w_S23_20,
		o_Z => w_S23_20_n);
		
	u_myINV_19_16 : myINV
	port map (
		i_A => w_S19_16,
		o_Z => w_S19_16_n);
		
	u_myINV_15_12 : myINV
	port map (
		i_A => w_S15_12,
		o_Z => w_S15_12_n);
		
	u_myINV_11_08 : myINV
	port map (
		i_A => w_S11_08,
		o_Z => w_S11_08_n);
		
	u_myINV_07_04 : myINV
	port map (
		i_A => w_S07_04,
		o_Z => w_S07_04_n);
		
	u_myINV_03_00 : myINV
	port map (
		i_A => w_S03_00,
		o_Z => w_S03_00_n);
		
	u_myINV_31_24 : myINV
	port map (
		i_A => w_S31_24,
		o_Z => w_S31_24_n);
		
	u_myINV_23_16 : myINV
	port map (
		i_A => w_S23_16,
		o_Z => w_S23_16_n);
		
	u_myINV_15_08 : myINV
	port map (
		i_A => w_S15_08,
		o_Z => w_S15_08_n);
		
	u_myINV_07_00 : myINV
	port map (
		i_A => w_S07_00,
		o_Z => w_S07_00_n);
		
	u_myINV_31_16 : myINV
	port map (
		i_A => w_S31_16,
		o_Z => w_S31_16_n);
		
	u_myINV_15_00 : myINV
	port map (
		i_A => w_S15_00,
		o_Z => w_S15_00_n);
		
	u_myINV_overcheck : myINV
	port map (
		i_A => w_overcheck_n,
		o_Z => w_overcheck);
	
	u_myNAND_31_30 : myNAND2
	port map (
		i_A => w_S31_n,
		i_B => w_S30_n,
		o_Z => w_S31_30);
		
	u_myNAND_29_28 : myNAND2
	port map (
		i_A => w_S29_n,
		i_B => w_S28_n,
		o_Z => w_S29_28);
		
	u_myNAND_27_26 : myNAND2
	port map (
		i_A => w_S27_n,
		i_B => w_S26_n,
		o_Z => w_S27_26);
		
	u_myNAND_25_24 : myNAND2
	port map (
		i_A => w_S25_n,
		i_B => w_S24_n,
		o_Z => w_S25_24);
		
	u_myNAND_23_22 : myNAND2
	port map (
		i_A => w_S23_n,
		i_B => w_S22_n,
		o_Z => w_S23_22);
		
	u_myNAND_21_20 : myNAND2
	port map (
		i_A => w_S21_n,
		i_B => w_S20_n,
		o_Z => w_S21_20);
		
	u_myNAND_19_18 : myNAND2
	port map (
		i_A => w_S19_n,
		i_B => w_S18_n,
		o_Z => w_S19_18);
		
	u_myNAND_17_16 : myNAND2
	port map (
		i_A => w_S17_n,
		i_B => w_S16_n,
		o_Z => w_S17_16);
		
	u_myNAND_15_14 : myNAND2
	port map (
		i_A => w_S15_n,
		i_B => w_S14_n,
		o_Z => w_S15_14);
		
	u_myNAND_13_12 : myNAND2
	port map (
		i_A => w_S13_n,
		i_B => w_S12_n,
		o_Z => w_S13_12);
		
	u_myNAND_11_10 : myNAND2
	port map (
		i_A => w_S11_n,
		i_B => w_S10_n,
		o_Z => w_S11_10);
		
	u_myNAND_09_08 : myNAND2
	port map (
		i_A => w_S09_n,
		i_B => w_S08_n,
		o_Z => w_S09_08);
		
	u_myNAND_07_06 : myNAND2
	port map (
		i_A => w_S07_n,
		i_B => w_S06_n,
		o_Z => w_S07_06);
		
	u_myNAND_05_04 : myNAND2
	port map (
		i_A => w_S05_n,
		i_B => w_S04_n,
		o_Z => w_S05_04);
		
	u_myNAND_03_02 : myNAND2
	port map (
		i_A => w_S03_n,
		i_B => w_S02_n,
		o_Z => w_S03_02);
		
	u_myNAND_01_00 : myNAND2
	port map (
		i_A => w_S01_n,
		i_B => w_S00_n,
		o_Z => w_S01_00);
		
	u_myNAND_31_28 : myNAND2
	port map (
		i_A => w_S31_30_n,
		i_B => w_S29_28_n,
		o_Z => w_S31_28);
		
	u_myNAND_27_24 : myNAND2
	port map (
		i_A => w_S27_26_n,
		i_B => w_S25_24_n,
		o_Z => w_S27_24);
		
	u_myNAND_23_20 : myNAND2
	port map (
		i_A => w_S23_22_n,
		i_B => w_S21_20_n,
		o_Z => w_S23_20);
		
	u_myNAND_19_16 : myNAND2
	port map (
		i_A => w_S19_18_n,
		i_B => w_S17_16_n,
		o_Z => w_S19_16);
		
	u_myNAND_15_12 : myNAND2
	port map (
		i_A => w_S15_14_n,
		i_B => w_S13_12_n,
		o_Z => w_S15_12);
		
	u_myNAND_11_08 : myNAND2
	port map (
		i_A => w_S11_10_n,
		i_B => w_S09_08_n,
		o_Z => w_S11_08);
		
	u_myNAND_07_04 : myNAND2
	port map (
		i_A => w_S07_06_n,
		i_B => w_S05_04_n,
		o_Z => w_S07_04);
		
	u_myNAND_03_00 : myNAND2
	port map (
		i_A => w_S03_02_n,
		i_B => w_S01_00_n,
		o_Z => w_S03_00);
		
	u_myNAND_31_24 : myNAND2
	port map (
		i_A => w_S31_28_n,
		i_B => w_S27_24_n,
		o_Z => w_S31_24);
		
	u_myNAND_23_16 : myNAND2
	port map (
		i_A => w_S23_20_n,
		i_B => w_S19_16_n,
		o_Z => w_S23_16);
		
	u_myNAND_15_08 : myNAND2
	port map (
		i_A => w_S15_12_n,
		i_B => w_S11_08_n,
		o_Z => w_S15_08);
		
	u_myNAND_07_00 : myNAND2
	port map (
		i_A => w_S07_04_n,
		i_B => w_S03_00_n,
		o_Z => w_S07_00);
		
	u_myNAND_31_16 : myNAND2
	port map (
		i_A => w_S31_24_n,
		i_B => w_S23_16_n,
		o_Z => w_S31_16);
		
	u_myNAND_15_00 : myNAND2
	port map (
		i_A => w_S15_08_n,
		i_B => w_S07_00_n,
		o_Z => w_S15_00);
		
	u_myNAND_overcheck : myNAND2
	port map (
		i_A => i_overflow,
		i_B => i_XNOR_AB,
		o_z => w_overcheck_n);
	
	-- Compute value of Not Equal to Zero. This can be erroneous if an
	-- overflow occured.  Another means is used to handle overflows and
	-- override this value
	u_myNAND_NE : myNAND2
	port map (
		i_A => w_S31_16_n,
		i_B => w_S15_00_n,
		o_Z => w_NE);
		--o_Z => w_NE0);
		
	-- Compute value of Greater Than or Equal to Zero. This can be erroneous if an
	-- overflow occured.  Another means is used to handle overflows and
	-- override this value
	u_myINV_GEZ : myINV
	port map (
		i_A => w_LTZ0,
		o_Z => w_GEZ);
--	u_myINV_GEZ : myINV
--	port map (
--		i_A => w_LTZ0,
--		o_Z => w_GEZ0);
		
	-- Compute value of Equal to Zero. This can be erroneous if an
	-- overflow occured.  Another means is used to handle overflows and
	-- override this value
	u_myINV_EQ : myINV
	port map (
		i_A => w_NE,
		o_Z => w_EQ);
--	u_myINV_EQ : myINV
--	port map (
--		i_A => w_NE0,
--		o_Z => w_EQ0);
		
	-- Compute value of Less Than or Equal to Zero. This can be erroneous if an
	-- overflow occured.  Another means is used to handle overflows and
	-- override this value
	u_myNAND_LEZ : myNAND2
	port map (
		i_A => w_GEZ,
		i_B => w_NE,
		o_Z => w_LEZ);
--	u_myNAND_LEZ : myNAND2
--	port map (
--		i_A => w_GEZ0,
--		i_B => w_NE0,
--		o_Z => w_LEZ0);
		
	-- Compute value of Greater Than Zero. This can be erroneous if an
	-- overflow occured.  Another means is used to handle overflows and
	-- override this value
	u_myINV_GTZ : myINV
	port map (
		i_A => w_LEZ,
		o_Z => w_GTZ);
--	u_myINV_GTZ : myINV
--	port map (
--		i_A => w_LEZ0,
--		o_Z => w_GTZ0);
		
	-- Invert the i_signed input
	u_myINV_unsigned : myINV
	port map (
		i_A => i_unsigned,
		o_Z => w_unsigned_n);
	-- Compute GTZ, GEZ assuming an overflow occured
--	u_myNAND_comp0 : myNAND2
--	port map (
--		i_A => i_unsigned,
--		i_B => i_NAND_AB,
--		o_Z => w_comp0);
--		
--	u_myNAND_comp1 : myNAND2
--	port map (
--		i_A => w_unsigned_n,
--		i_B => i_OR_AB,
--		o_Z => w_comp1);
--		
--	u_myNAND_comp2 : myNAND2
--	port map (
--		i_A => w_comp0,
--		i_B => w_comp1,
--		o_Z => w_comp2);
--		
--	u_myINV_comp2_n : myINV
--	port map (
--		i_A => w_comp2,
--		o_Z => w_comp2_n);
--		
--	u_myNAND_comp3 : myNAND2
--	port map (
--		i_A => w_comp2_n,
--		i_B => i_XNOR_AB,
--		o_Z => w_comp3);
--		
--	u_myINV_GZ : myINV
--	port map (
--		i_A => w_comp3,
--		o_Z => w_GEZ1);
	
	-- Compute LTZ, LEZ assuming an overflow occured
	u_myNAND_comp4 : myNAND2
	port map (
		i_A => i_unsigned,
		i_B => i_OR_AB,
		o_Z => w_comp4);
		
	u_myNAND_comp5 : myNAND2
	port map (
		i_A => w_unsigned_n,
		i_B => i_NAND_AB,
		o_Z => w_comp5);
		
	u_myNAND_comp6 : myNAND2
	port map (
		i_A => w_comp4,
		i_B => w_comp5,
		o_Z => w_comp6);
		
	u_myINV_comp6_n : myINV
	port map (
		i_A => w_comp6,
		o_Z => w_comp6_n);
		
	u_myNAND_comp7 : myNAND2
	port map (
		i_A => w_comp6_n,
		i_B => i_XNOR_AB,
		o_Z => w_comp7);
		
	u_myINV_LZ : myINV
	port map (
		i_A => w_comp7,
		o_Z => w_LTZ1);
	
	-- Determine whether ALU comparisons or Overflow Comparisons should be used
--	u_myMUX2_GEZ : myMUX2_1
--	port map (i_0 => w_GEZ0,
--				 i_1 => w_GEZ1,
--				 i_S => i_XNOR_AB,
--				 o_Z => w_GEZ);
				 
	u_myMUX2_LTZ : myMUX2_1
	port map (i_0 => w_LTZ0,
				 i_1 => w_LTZ1,
				 i_S => w_overcheck,
--				 i_S => i_XNOR_AB,
				 o_Z => w_LTZ);
				 
--	u_myMUX2_EQ : myMUX2_1
--	port map (i_0 => w_EQ0,
--				 i_1 => k_zero,
--				 i_S => i_XNOR_AB,
--				 o_Z => w_EQ);
--				 
--	u_myMUX2_NE : myMUX2_1
--	port map (i_0 => w_NE0,
--				 i_1 => k_one,
--				 i_S => i_XNOR_AB,
--				 o_Z => w_NE);
--				 
--	u_myMUX2_LEZ : myMUX2_1
--	port map (i_0 => w_LEZ0,
--				 i_1 => w_LTZ1,
--				 i_S => i_XNOR_AB,
--				 o_Z => w_LEZ);
--				 
--	u_myMUX2_GTZ : myMUX2_1
--	port map (i_0 => w_GTZ0,
--				 i_1 => w_GEZ1,
--				 i_S => i_XNOR_AB,
--				 o_Z => w_GTZ);
				 
	-- Create MUX to select output.
	u_myMUX8_1: myMUX8_1
	port map (i_0 => w_GEZ,
				 i_1 => w_LTZ,
				 i_2 => w_EQ,
				 i_3 => w_NE,
				 i_4 => w_LEZ,
				 i_5 => w_GTZ,
				 i_6 => w_GEZ,
				 i_7 => w_GEZ,
				 i_S => i_COMP_SEL,
				 o_Z => o_Z);
end a_Comparator;