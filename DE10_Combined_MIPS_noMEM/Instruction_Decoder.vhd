--| Instruction_Decoder
--| Decodes the 32-bit MIPS instruction to determine which portions of the ALU to activate.
--| 	ALU_SRC_A determines whether the A input to the ALU is the regester specified by RS, SA, or
--| 		the Program Counter (PC)
--|
--| 	ALU_SRC_B determines whether the B input to the ALU is the register specified by RT or if
--|		the input is zero, a 16 bit sign extended immediate or offset value, or a 16 bit sign
--|		extended offset value shifted left by 2 bits.
--|
--|	INV_B determines whether the B input should be negated to perform a subtraction rather
--|		than an addition
--|
--|	Comparison Outputs
--|	LTZ is high if the output of the comparator should be the less than zero output
--|	EQ is high if the output of the comparator should be the equal to zero output
--|	NE is high if the output of the comparator should be the not equal to zero output
--|	LEZ is high if the output of the comparator should be the less than or equal to zero output
--|	GTZ is high if the output of the comparator should be the greater than or equal to zero output
--|		Note that there is no outputput for greater than or equal to zero.  There is separate
--|		encoder outside the Instruction_Decoder that takes the 5 comparison signals and encodes them
--|		as a 3-bit signal.  If all of these signals are 0, it is assumed that the greater than or
--|		equal to zero output should be selected.  Additionally, these comarisons are performed on
--|		the output of the adder, so in reality, the comparison is performed on the result of S = A+B
--|		where B may be inverted and then the comparison is really between A and B since (or S and 0).
--|
--|	ALU Output Selection
--|	RIGHT_SHIFT is high if the ALU output should come from the right shifter
--|	ADDER is high if the ALU output should come from the adder
--|	AND is high if the ALU output should come from the bitwise and
--|	OR is high if the ALU output should come from the bitwise or
--|	XOR is high if the ALU output should come from the bitwise xor
--|	NOR is high if the ALU output should come from the bitwise nor
--|	COMPARE is high if the ALU output should come from the comparator
--|		(i.e. output a 32-bit 0 if the comparison is false or a 32-bit 1 if the comparison is true)
--|	LUI is high if the ALU output should come from the load upper immediate
--|		If all of the ALU output selection values are 0, the default output of LEFT_SHIFT is
--|		selected.  This is accomplished in a separate encoder which converts these individual
--|		signals into a 4-bit encoded signal.
--|
--|	REG_SEL determines the regester to which the results of the ALU computation will be
--|		writen.  This could be the zero register, the PC register, or the register specified by
--|		RT or RD.
--|
--|	OVER_CTRL determines whether the output of the adder should be checked for an overflow.
--|		The only instructions requiring overflow detection are add (ADD), add immediate (ADDI),
--|		and subtract (SUB).
--|
--|	FSM_CTRL determines what the next state of the FSM should be after the instruction is stored
--|		from memory.  It depends on whether the instruction is a branch, load word, or store word
--|		instruction.  If it is none of these, FSM_CTRL = B"00".  For a branch, FSM_CTRL = B"01".
--|		For a load word, FSM_CTRL = B"10".  For a store word, FSM_CTRL = B"11".
--|
--| INPUTS:
--| i_instr31 - Instruction inputs
--| ...
--| i_instr00
--|
--| OUTPUTS:
--| o_ALU_SRC_A0		- ALU Source of Input A Selector Signal bit 0
--| o_ALU_SRC_B		- ALU Source of Input B Selector SIgnal
--| o_INV_B				- Invert ALU Input B Signal
--| o_LTZ				- Less than zero
--| o_EQ					- Equal to zero
--| o_NE					- Not equal to zero
--| o_LEZ				- Less than or equal to zero
--| o_GTZ				- Greater than zero
--| o_RIGHT_SHIFT		- ALU Output = Right Shift Output
--| o_ADDER				- ALU Output = Adder Output
--| o_AND				- ALU Output = AND output
--| o_OR					- ALU Output = OR output
--| o_XOR				- ALU Output = XOR output
--| o_NOR				- ALU Output = NOR output
--| o_COMPARE			- ALU Output = Comparator output
--| o_LUI				- ALU Output = Load upper immediate output
--| o_REG_SEL			- Register selct Signal
--| o_OVER_CTRL		- Overflow Control Signal
--| o_UNSIGNED			- Determine if the comparator is comparing sigend numbers (0) or unsigned
--|					     numbers (1).
--| o_overflow			- Determine if the comparator is performing a Less Than comparison that will
--|                 	  or will not produce an overflow.  No overflow can occur in BLTZ instructions,
--|					  	  but overflow can occur in SLT, SLTU, SLTI, and SLTIU instructions.  0 - no
--|					     overflow can occur, 1 - overflow can occur
--| o_imm_extend		- Determine if the immediate value should be 0 extended or sign extended
--| o_FSM_CTRL			- Finite State Machine Control Signal
--| o_INVALID_INSTR	- Signals when an invalid instruction is received
library IEEE;
use IEEE.std_logic_1164.all;

entity Instruction_Decoder is
	port (i_instr31		: in  std_logic;
			i_instr30		: in  std_logic;
			i_instr29		: in  std_logic;
			i_instr28		: in  std_logic;
			i_instr27		: in  std_logic;
			i_instr26		: in  std_logic;
			i_instr20		: in  std_logic;
			i_instr19		: in  std_logic;
			i_instr18		: in  std_logic;
			i_instr17		: in  std_logic;
			i_instr16		: in  std_logic;
			i_instr05		: in  std_logic;
			i_instr04		: in  std_logic;
			i_instr03		: in  std_logic;
			i_instr02		: in  std_logic;
			i_instr01		: in  std_logic;
			i_instr00		: in  std_logic;
			o_ALU_SRC_A0	: out std_logic;
			o_ALU_SRC_B		: out std_logic_vector(1 downto 0);
			o_INV_B			: out std_logic;
			o_LTZ				: out std_logic;
			o_EQ				: out std_logic;
			o_NE				: out std_logic;
			o_LEZ				: out std_logic;
			o_GTZ				: out std_logic;
			o_RIGHT_SHIFT	: out std_logic;
			o_ADDER			: out std_logic;
			o_AND				: out std_logic;
			o_OR				: out std_logic;
			o_XOR				: out std_logic;
			o_NOR				: out std_logic;
			o_COMPARE		: out std_logic;
			o_LUI				: out std_logic;
			o_REG_SEL		: out std_logic_vector(1 downto 0);
			o_OVER_CTRL		: out std_logic_vector(1 downto 0);
			o_UNSIGNED		: out std_logic;
			o_overflow		: out std_logic;
			o_imm_extend	: out std_logic;
			o_FSM_CTRL		: out std_logic_vector(1 downto 0);
			o_INVALID_INSTR: out std_logic);
end Instruction_Decoder;

architecture a_Instruction_Decoder of Instruction_Decoder is
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

	--| Declare Signals
	-- Inverted Instruction Signals
	signal w_instr31_n : std_logic;
	signal w_instr30_n : std_logic;
	signal w_instr29_n : std_logic;
	signal w_instr28_n : std_logic;
	signal w_instr27_n : std_logic;
	signal w_instr26_n : std_logic;
	signal w_instr20_n : std_logic;
	signal w_instr19_n : std_logic;
	signal w_instr18_n : std_logic;
	signal w_instr17_n : std_logic;
	signal w_instr16_n : std_logic;
	signal w_instr05_n : std_logic;
	signal w_instr04_n : std_logic;
	signal w_instr03_n : std_logic;
	signal w_instr02_n : std_logic;
	signal w_instr01_n : std_logic;
	signal w_instr00_n : std_logic;
	-- Intermediate control signals (and inverted control signals) used to compute outputs
	signal w_ctrl_000, w_ctrl_000_n : std_logic;
	signal w_ctrl_001, w_ctrl_001_n : std_logic;
	signal w_ctrl_002, w_ctrl_002_n : std_logic;
	signal w_ctrl_003, w_ctrl_003_n : std_logic;
	signal w_ctrl_004, w_ctrl_004_n : std_logic;
	signal w_ctrl_005, w_ctrl_005_n : std_logic;
	signal w_ctrl_006, w_ctrl_006_n : std_logic;
	signal w_ctrl_007, w_ctrl_007_n : std_logic;
	signal w_ctrl_008 : std_logic;
	signal w_ctrl_009, w_ctrl_009_n : std_logic;
	signal w_ctrl_010 : std_logic;
	signal w_ctrl_011, w_ctrl_011_n : std_logic;
	signal w_ctrl_012 : std_logic;
	signal w_ctrl_013 : std_logic;
	signal w_ctrl_014, w_ctrl_014_n : std_logic;
	signal w_ctrl_015, w_ctrl_015_n : std_logic;
	signal w_ctrl_018, w_ctrl_018_n : std_logic;
	signal w_ctrl_020, w_ctrl_020_n : std_logic;
	signal w_ctrl_025 : std_logic;
	signal w_ctrl_028, w_ctrl_028_n : std_logic;
	signal w_ctrl_029, w_ctrl_029_n : std_logic;
	signal w_ctrl_030 : std_logic;
	signal w_ctrl_031 : std_logic;
	signal w_ctrl_032 : std_logic;
	signal w_ctrl_033 : std_logic;
	signal w_ctrl_034, w_ctrl_034_n : std_logic;
	signal w_ctrl_035 : std_logic;
	signal w_ctrl_036 : std_logic;
	signal w_ctrl_037, w_ctrl_037_n : std_logic;
	signal w_ctrl_038, w_ctrl_038_n : std_logic;
	signal w_ctrl_039, w_ctrl_039_n : std_logic;
	signal w_ctrl_040 : std_logic;
	signal w_ctrl_041, w_ctrl_041_n : std_logic;
	signal w_ctrl_042 : std_logic;
	signal w_ctrl_043, w_ctrl_043_n : std_logic;
	signal w_ctrl_044, w_ctrl_044_n : std_logic;
	signal w_ctrl_046, w_ctrl_046_n : std_logic;
	signal w_ctrl_047 : std_logic;
	signal w_ctrl_048, w_ctrl_048_n : std_logic;
	signal w_ctrl_049 : std_logic;
	signal w_ctrl_050 : std_logic;
	signal w_ctrl_051, w_ctrl_051_n : std_logic;
	signal w_ctrl_052 : std_logic;
	signal w_ctrl_053, w_ctrl_053_n : std_logic;
	signal w_ctrl_054, w_ctrl_054_n : std_logic;
	signal w_ctrl_055, w_ctrl_055_n : std_logic;
	signal w_ctrl_056, w_ctrl_056_n : std_logic;
	signal w_ctrl_057, w_ctrl_057_n : std_logic;
	signal w_ctrl_058, w_ctrl_058_n : std_logic;
	signal w_ctrl_059 : std_logic;
	signal w_ctrl_060 : std_logic;
	signal w_ctrl_061 : std_logic;
	signal w_ctrl_062, w_ctrl_062_n : std_logic;
	signal w_ctrl_063, w_ctrl_063_n : std_logic;
	signal w_ctrl_064 : std_logic;
	signal w_ctrl_065, w_ctrl_065_n : std_logic;
	signal w_ctrl_066, w_ctrl_066_n : std_logic;
	signal w_ctrl_067 : std_logic;
	signal w_ctrl_068 : std_logic;
	signal w_ctrl_069 : std_logic;
	signal w_ctrl_070, w_ctrl_070_n : std_logic;
	signal w_ctrl_071, w_ctrl_071_n : std_logic;
	signal w_ctrl_072 : std_logic;
	signal w_ctrl_073, w_ctrl_073_n : std_logic;
	signal w_ctrl_074, w_ctrl_074_n : std_logic;
	signal w_ctrl_075 : std_logic;
	signal w_ctrl_076 : std_logic;
	signal w_ctrl_077, w_ctrl_077_n : std_logic;
	signal w_ctrl_078, w_ctrl_078_n : std_logic;
	signal w_ctrl_079, w_ctrl_079_n : std_logic;
	signal w_ctrl_080, w_ctrl_080_n : std_logic;
	signal w_ctrl_081 : std_logic;
	signal w_ctrl_082, w_ctrl_082_n : std_logic;
	signal w_ctrl_083 : std_logic;
	signal w_ctrl_084 : std_logic;
	signal w_ctrl_085, w_ctrl_085_n : std_logic;
	signal w_ctrl_086, w_ctrl_086_n : std_logic;
	signal w_ctrl_087, w_ctrl_087_n : std_logic;
	signal w_ctrl_094 : std_logic;
	signal w_ctrl_095 : std_logic;
	signal w_ctrl_098 : std_logic;
	signal w_ctrl_099 : std_logic;
	signal w_ctrl_100 : std_logic;
	signal w_ctrl_101 : std_logic;
	signal w_ctrl_102, w_ctrl_102_n : std_logic;
	signal w_ctrl_103 : std_logic;
	signal w_ctrl_106, w_ctrl_106_n : std_logic;
	signal w_ctrl_107 : std_logic;
	signal w_ctrl_108 : std_logic;
	signal w_ctrl_109 : std_logic;
	signal w_ctrl_110 : std_logic;
	signal w_ctrl_111 : std_logic;
	signal w_ctrl_112 : std_logic;
	signal w_ctrl_113 : std_logic;
	signal w_ctrl_114 : std_logic;
	signal w_ctrl_115 : std_logic;
	signal w_ctrl_116 : std_logic;
	signal w_ctrl_117 : std_logic;
	signal w_ctrl_118, w_ctrl_118_n : std_logic;
	signal w_ctrl_119 : std_logic;
	signal w_ctrl_120, w_ctrl_120_n : std_logic;
	signal w_ctrl_121 : std_logic;
	signal w_ctrl_122 : std_logic;
	signal w_ctrl_123 : std_logic;
	signal w_ctrl_124 : std_logic;
	signal w_ctrl_125, w_ctrl_125_n : std_logic;
	signal w_ctrl_126, w_ctrl_126_n : std_logic;
	signal w_ctrl_127, w_ctrl_127_n : std_logic;
	signal w_ctrl_128 : std_logic;
	signal w_ctrl_129 : std_logic;
	signal w_ctrl_130, w_ctrl_130_n : std_logic;
	signal w_ctrl_131 : std_logic;
	signal w_ctrl_132, w_ctrl_132_n : std_logic;
	signal w_ctrl_133 : std_logic;
	signal w_ctrl_134 : std_logic;
	signal w_ctrl_135 : std_logic;
	signal w_ctrl_136 : std_logic;
	signal w_ctrl_137, w_ctrl_137_n : std_logic;
	signal w_ctrl_138 : std_logic;
	signal w_ctrl_139 : std_logic;
	signal w_ctrl_140 : std_logic;
	signal w_ctrl_141 : std_logic;
	signal w_ctrl_142 : std_logic;
	signal w_ctrl_143, w_ctrl_143_n : std_logic;
	signal w_ctrl_144, w_ctrl_144_n : std_logic;
	signal w_ctrl_145 : std_logic;
	signal w_ctrl_146 : std_logic;
	signal w_ctrl_147 : std_logic;
	signal w_ctrl_148 : std_logic;
	
	

begin
	--| Instantiate Inverters to create inverted signals where needed
	u_myINV_31 : myINV
	port map (
		i_A => i_instr31,
		o_Z => w_instr31_n);
	
	u_myINV_30 : myINV
	port map (
		i_A => i_instr30,
		o_Z => w_instr30_n);
	
	u_myINV_29 : myINV
	port map (
		i_A => i_instr29,
		o_Z => w_instr29_n);
	
	u_myINV_28 : myINV
	port map (
		i_A => i_instr28,
		o_Z => w_instr28_n);
	
	u_myINV_27 : myINV
	port map (
		i_A => i_instr27,
		o_Z => w_instr27_n);
	
	u_myINV_26 : myINV
	port map (
		i_A => i_instr26,
		o_Z => w_instr26_n);
	
	u_myINV_20 : myINV
	port map (
		i_A => i_instr20,
		o_Z => w_instr20_n);
	
	u_myINV_19 : myINV
	port map (
		i_A => i_instr19,
		o_Z => w_instr19_n);
	
	u_myINV_18 : myINV
	port map (
		i_A => i_instr18,
		o_Z => w_instr18_n);
	
	u_myINV_17 : myINV
	port map (
		i_A => i_instr17,
		o_Z => w_instr17_n);
	
	u_myINV_16 : myINV
	port map (
		i_A => i_instr16,
		o_Z => w_instr16_n);
	
	u_myINV_05 : myINV
	port map (
		i_A => i_instr05,
		o_Z => w_instr05_n);
	
	u_myINV_04 : myINV
	port map (
		i_A => i_instr04,
		o_Z => w_instr04_n);
	u_myINV_03 : myINV
	port map (
		i_A => i_instr03,
		o_Z => w_instr03_n);
	
	u_myINV_02 : myINV
	port map (
		i_A => i_instr02,
		o_Z => w_instr02_n);
	
	u_myINV_01 : myINV
	port map (
		i_A => i_instr01,
		o_Z => w_instr01_n);
	
	u_myINV_00 : myINV
	port map (
		i_A => i_instr00,
		o_Z => w_instr00_n);
	
	u_myINV_000 : myINV
	port map (
		i_A => w_ctrl_000,
		o_Z => w_ctrl_000_n);
		
	u_myINV_001 : myINV
	port map (
		i_A => w_ctrl_001,
		o_Z => w_ctrl_001_n);
	
	u_myINV_002 : myINV
	port map (
		i_A => w_ctrl_002,
		o_Z => w_ctrl_002_n);
		
	u_myINV_003 : myINV
	port map (
		i_A => w_ctrl_003,
		o_Z => w_ctrl_003_n);
	
	u_myINV_004 : myINV
	port map (
		i_A => w_ctrl_004,
		o_Z => w_ctrl_004_n);
		
	u_myINV_005 : myINV
	port map (
		i_A => w_ctrl_005,
		o_Z => w_ctrl_005_n);
		
	u_myINV_006 : myINV
	port map (
		i_A => w_ctrl_006,
		o_Z => w_ctrl_006_n);
	
	u_myINV_007 : myINV
	port map (
		i_A => w_ctrl_007,
		o_Z => w_ctrl_007_n);
	
	u_myINV_009 : myINV
	port map (
		i_A => w_ctrl_009,
		o_Z => w_ctrl_009_n);

	u_myINV_011 : myINV
	port map (
		i_A => w_ctrl_011,
		o_Z => w_ctrl_011_n);
	
	u_myINV_014 : myINV
	port map (
		i_A => w_ctrl_014,
		o_Z => w_ctrl_014_n);
		
	u_myINV_015 : myINV
	port map (
		i_A => w_ctrl_015,
		o_Z => w_ctrl_015_n);
		
	u_myINV_018 : myINV
	port map (
		i_A => w_ctrl_018,
		o_Z => w_ctrl_018_n);
		
	u_myINV_020 : myINV
	port map (
		i_A => w_ctrl_020,
		o_Z => w_ctrl_020_n);
		
	u_myINV_028 : myINV
	port map (
		i_A => w_ctrl_028,
		o_Z => w_ctrl_028_n);
		
	u_myINV_029 : myINV
	port map (
		i_A => w_ctrl_029,
		o_Z => w_ctrl_029_n);
		
	u_myINV_034 : myINV
	port map (
		i_A => w_ctrl_034,
		o_Z => w_ctrl_034_n);
		
	u_myINV_037 : myINV
	port map (
		i_A => w_ctrl_037,
		o_Z => w_ctrl_037_n);
		
	u_myINV_038 : myINV
	port map (
		i_A => w_ctrl_038,
		o_Z => w_ctrl_038_n);
		
	u_myINV_039 : myINV
	port map (
		i_A => w_ctrl_039,
		o_Z => w_ctrl_039_n);
		
	u_myINV_041 : myINV
	port map (
		i_A => w_ctrl_041,
		o_Z => w_ctrl_041_n);
		
	u_myINV_043 : myINV
	port map (
		i_A => w_ctrl_043,
		o_Z => w_ctrl_043_n);
		
	u_myINV_044 : myINV
	port map (
		i_A => w_ctrl_044,
		o_Z => w_ctrl_044_n);
		
	u_myINV_046 : myINV
	port map (
		i_A => w_ctrl_046,
		o_Z => w_ctrl_046_n);
		
	u_myINV_048 : myINV
	port map (
		i_A => w_ctrl_048,
		o_Z => w_ctrl_048_n);
	
	u_myINV_051 : myINV
	port map (
		i_A => w_ctrl_051,
		o_Z => w_ctrl_051_n);
		
	u_myINV_053 : myINV
	port map (
		i_A => w_ctrl_053,
		o_Z => w_ctrl_053_n);
	
	u_myINV_054 : myINV
	port map (
		i_A => w_ctrl_054,
		o_Z => w_ctrl_054_n);
	
	u_myINV_055 : myINV
	port map (
		i_A => w_ctrl_055,
		o_Z => w_ctrl_055_n);
	
	u_myINV_056 : myINV
	port map (
		i_A => w_ctrl_056,
		o_Z => w_ctrl_056_n);
		
	u_myINV_057 : myINV
	port map (
		i_A => w_ctrl_057,
		o_Z => w_ctrl_057_n);
		
	u_myINV_058 : myINV
	port map (
		i_A => w_ctrl_058,
		o_Z => w_ctrl_058_n);
		
	u_myINV_062 : myINV
	port map (
		i_A => w_ctrl_062,
		o_Z => w_ctrl_062_n);
	
	u_myINV_063 : myINV
	port map (
		i_A => w_ctrl_063,
		o_Z => w_ctrl_063_n);
		
	u_myINV_065 : myINV
	port map (
		i_A => w_ctrl_065,
		o_Z => w_ctrl_065_n);
		
	u_myINV_066 : myINV
	port map (
		i_A => w_ctrl_066,
		o_Z => w_ctrl_066_n);
		
	u_myINV_070 : myINV
	port map (
		i_A => w_ctrl_070,
		o_Z => w_ctrl_070_n);
		
	u_myINV_071 : myINV
	port map (
		i_A => w_ctrl_071,
		o_Z => w_ctrl_071_n);
		
	u_myINV_073 : myINV
	port map (
		i_A => w_ctrl_073,
		o_Z => w_ctrl_073_n);
		
	u_myINV_074 : myINV
	port map (
		i_A => w_ctrl_074,
		o_Z => w_ctrl_074_n);
	
	u_myINV_077 : myINV
	port map (
		i_A => w_ctrl_077,
		o_Z => w_ctrl_077_n);
	
	u_myINV_078 : myINV
	port map (
		i_A => w_ctrl_078,
		o_Z => w_ctrl_078_n);
		
	u_myINV_079 : myINV
	port map (
		i_A => w_ctrl_079,
		o_Z => w_ctrl_079_n);
		
	u_myINV_080 : myINV
	port map (
		i_A => w_ctrl_080,
		o_Z => w_ctrl_080_n);
		
	u_myINV_082 : myINV
	port map (
		i_A => w_ctrl_082,
		o_Z => w_ctrl_082_n);
		
	u_myINV_085 : myINV
	port map (
		i_A => w_ctrl_085,
		o_Z => w_ctrl_085_n);
		
	u_myINV_086 : myINV
	port map (
		i_A => w_ctrl_086,
		o_Z => w_ctrl_086_n);
		
	u_myINV_087 : myINV
	port map (
		i_A => w_ctrl_087,
		o_Z => w_ctrl_087_n);
		
	u_myINV_102 : myINV
	port map (
		i_A => w_ctrl_102,
		o_Z => w_ctrl_102_n);
		
	u_myINV_106 : myINV
	port map (
		i_A => w_ctrl_106,
		o_Z => w_ctrl_106_n);
		
	u_myINV_118 : myINV
	port map (
		i_A => w_ctrl_118,
		o_Z => w_ctrl_118_n);
		
	u_myINV_120 : myINV
	port map (
		i_A => w_ctrl_120,
		o_Z => w_ctrl_120_n);
		
	u_myINV_125 : myINV
	port map (
		i_A => w_ctrl_125,
		o_Z => w_ctrl_125_n);
		
	u_myINV_126 : myINV
	port map (
		i_A => w_ctrl_126,
		o_Z => w_ctrl_126_n);
		
	u_myINV_127 : myINV
	port map (
		i_A => w_ctrl_127,
		o_Z => w_ctrl_127_n);
		
	u_myINV_130 : myINV
	port map (
		i_A => w_ctrl_130,
		o_Z => w_ctrl_130_n);
		
	u_myINV_132 : myINV
	port map (
		i_A => w_ctrl_132,
		o_Z => w_ctrl_132_n);
		
	u_myINV_137 : myINV
	port map (
		i_A => w_ctrl_137,
		o_Z => w_ctrl_137_n);
		
	u_myINV_143 : myINV
	port map (
		i_A => w_ctrl_143,
		o_Z => w_ctrl_143_n);
		
	u_myINV_144 : myINV
	port map (
		i_A => w_ctrl_144,
		o_Z => w_ctrl_144_n);
	
	--| Instantiate NAND gates to create intermediate control signals
	u_myNAND_000 : myNAND2
	port map (
		i_A => w_instr31_n,
		i_B => w_instr30_n,
		o_Z => w_ctrl_000);
	
	u_myNAND_001 : myNAND2
	port map (
		i_A => w_instr29_n,
		i_B => w_instr28_n,
		o_Z => w_ctrl_001);
	
	u_myNAND_002 : myNAND2
	port map (
		i_A => w_instr27_n,
		i_B => w_instr26_n,
		o_Z => w_ctrl_002);
	
	u_myNAND_003 : myNAND2
	port map (
		i_A => w_instr05_n,
		i_B => w_instr04_n,
		o_Z => w_ctrl_003);
	
	u_myNAND_004 : myNAND2
	port map (
		i_A => w_instr03_n,
		i_B => w_instr02_n,
		o_Z => w_ctrl_004);

	u_myNAND_005 : myNAND2
	port map (
		i_A => w_ctrl_000_n,
		i_B => w_ctrl_001_n,
		o_Z => w_ctrl_005);
		
	u_myNAND_006 : myNAND2
	port map (
		i_A => w_ctrl_002_n,
		i_B => w_ctrl_003_n,
		o_Z => w_ctrl_006);
	
	u_myNAND_007 : myNAND2
	port map (
		i_A => w_ctrl_005_n,
		i_B => w_ctrl_006_n,
		o_Z => w_ctrl_007);
	
	u_myNAND_008 : myNAND2
	port map (
		i_A => w_ctrl_007_n,
		i_B => w_ctrl_004_n,
		o_Z => w_ctrl_008);
	
	u_myNAND_009 : myNAND2
	port map (
		i_A => w_ctrl_000_n,
		i_B => w_instr29_n,
		o_Z => w_ctrl_009);
	
	u_myNAND_010 : myNAND2
	port map (
		i_A => w_instr28_n,
		i_B => w_ctrl_002_n,
		o_Z => w_ctrl_010);
		
	u_myNAND_011 : myNAND2
	port map (
		i_A => i_instr28,
		i_B => w_instr27_n,
		o_Z => w_ctrl_011);
		
	u_myNAND_012 : myNAND2
	port map (
		i_A => w_ctrl_010,
		i_B => w_ctrl_011,
		o_Z => w_ctrl_012);
	
	u_myNAND_013 : myNAND2
	port map (
		i_A => w_ctrl_009_n,
		i_B => w_ctrl_012,
		o_Z => w_ctrl_013);
		
	u_myNAND_014 : myNAND2
	port map (
		i_A => w_instr29_n,
		i_B => w_instr27_n,
		o_Z => w_ctrl_014);
		
	u_myNAND_015 : myNAND2
	port map (
		i_A => w_instr29_n,
		i_B => w_ctrl_011_n,
		o_Z => w_ctrl_015);
		
	u_myNAND_018 : myNAND2
	port map (
		i_A => w_instr26_n,
		i_B => i_instr05,
		o_Z => w_ctrl_018);
		
	u_myNAND_020 : myNAND2
	port map (
		i_A => w_ctrl_018_n,
		i_B => w_instr04_n,
		o_Z => w_ctrl_020);
		
	u_myNAND_025 : myNAND2
	port map (
		i_A => w_instr27_n,
		i_B => i_instr26,
		o_Z => w_ctrl_025);
		
	u_myNAND_028 : myNAND2
	port map (
		i_A => w_ctrl_000_n,
		i_B => w_instr28_n,
		o_Z => w_ctrl_028);
		
	u_myNAND_029 : myNAND2
	port map (
		i_A => i_instr29,
		i_B => i_instr27,
		o_Z => w_ctrl_029);
		
	u_myNAND_030 : myNAND2
	port map (
		i_A => i_instr26,
		i_B => i_instr16,
		o_Z => w_ctrl_030);
		
	u_myNAND_031 : myNAND2
	port map (
		i_A => w_ctrl_014_n,
		i_B => w_ctrl_030,
		o_Z => w_ctrl_031);
		
	u_myNAND_032 : myNAND2
	port map (
		i_A => w_ctrl_029,
		i_B => w_ctrl_031,
		o_Z => w_ctrl_032);
		
	u_myNAND_033 : myNAND2
	port map (
		i_A => w_ctrl_028_n,
		i_B => w_ctrl_032,
		o_Z => w_ctrl_033);
		
	u_myNAND_034 : myNAND2
	port map (
		i_A => w_ctrl_000_n,
		i_B => w_ctrl_015_n,
		o_Z => w_ctrl_034);
		
	u_myNAND_035 : myNAND2
	port map (
		i_A => w_ctrl_034_n,
		i_B => w_instr26_n,
		o_Z => w_ctrl_035);
		
	u_myNAND_036 : myNAND2
	port map (
		i_A => w_ctrl_034_n,
		i_B => i_instr26,
		o_Z => w_ctrl_036);
		
	u_myNAND_037 : myNAND2
	port map (
		i_A => w_instr29_n,
		i_B => i_instr28,
		o_Z => w_ctrl_037);
		
	u_myNAND_038 : myNAND2
	port map (
		i_A => i_instr27,
		i_B => w_instr26_n,
		o_Z => w_ctrl_038);
		
	u_myNAND_039 : myNAND2
	port map (
		i_A => w_ctrl_000_n,
		i_B => w_ctrl_037_n,
		o_Z => w_ctrl_039);
		
	u_myNAND_040 : myNAND2
	port map (
		i_A => w_ctrl_039_n,
		i_B => w_ctrl_038_n,
		o_Z => w_ctrl_040);
	
	u_myNAND_041 : myNAND2
	port map (
		i_A => i_instr27,
		i_B => i_instr26,
		o_Z => w_ctrl_041);
		
	u_myNAND_042 : myNAND2
	port map (
		i_A => w_ctrl_039_n,
		i_B => w_ctrl_041_n,
		o_Z => w_ctrl_042);
		
	u_myNAND_043 : myNAND2
	port map (
		i_A => w_instr01_n,
		i_B => w_instr00_n,
		o_Z => w_ctrl_043);
		
	u_myNAND_044 : myNAND2
	port map (
		i_A => w_ctrl_004_n,
		i_B => w_ctrl_043_n,
		o_Z => w_ctrl_044);
		
	u_myNAND_046 : myNAND2
	port map (
		i_A => w_instr03_n,
		i_B => i_instr01,
		o_Z => w_ctrl_046);
		
	u_myNAND_047 : myNAND2
	port map (
		i_A => w_ctrl_007_n,
		i_B => w_ctrl_046_n,
		o_Z => w_ctrl_047);
		
	u_myNAND_048 : myNAND2
	port map (
		i_A => w_instr30_n,
		i_B => w_instr27_n,
		o_Z => w_ctrl_048);
		
	u_myNAND_049 : myNAND2
	port map (
		i_A => w_ctrl_020_n,
		i_B => w_ctrl_004_n,
		o_Z => w_ctrl_049);
		
	u_myNAND_050 : myNAND2
	port map (
		i_A => w_instr29_n,
		i_B => w_ctrl_049,
		o_Z => w_ctrl_050);
		
	u_myNAND_051 : myNAND2
	port map (
		i_A => w_instr28_n,
		i_B => w_ctrl_048_n,
		o_Z => w_ctrl_051);
		
	u_myNAND_052 : myNAND2
	port map (
		i_A => w_ctrl_051_n,
		i_B => w_ctrl_050,
		o_Z => w_ctrl_052);
		
	u_myNAND_053 : myNAND2
	port map (
		i_A => w_ctrl_000_n,
		i_B => w_ctrl_002_n,
		o_Z => w_ctrl_053);
	
	u_myNAND_054 : myNAND2
	port map (
		i_A => i_instr29,
		i_B => i_instr28,
		o_Z => w_ctrl_054);
		
	u_myNAND_055 : myNAND2
	port map (
		i_A => i_instr05,
		i_B => w_instr04_n,
		o_Z => w_ctrl_055);
		
	u_myNAND_056 : myNAND2
	port map (
		i_A => w_instr03_n,
		i_B => i_instr02,
		o_Z => w_ctrl_056);
		
	u_myNAND_057 : myNAND2
	port map (
		i_A => w_ctrl_001_n,
		i_B => w_ctrl_055_n,
		o_Z => w_ctrl_057);
		
	u_myNAND_058 : myNAND2
	port map (
		i_A => w_ctrl_056_n,
		i_B => w_ctrl_043_n,
		o_Z => w_ctrl_058);
		
	u_myNAND_059 : myNAND2
	port map (
		i_A => w_ctrl_057_n,
		i_B => w_ctrl_058_n,
		o_Z => w_ctrl_059);
		
	u_myNAND_060 : myNAND2
	port map (
		i_A => w_ctrl_054,
		i_B => w_ctrl_059,
		o_Z => w_ctrl_060);
		
	u_myNAND_061 : myNAND2
	port map (
		i_A => w_ctrl_053_n,
		i_B => w_ctrl_060,
		o_Z => w_ctrl_061);
		
	u_myNAND_062 : myNAND2
	port map (
		i_A => w_instr01_n,
		i_B => i_instr00,
		o_Z => w_ctrl_062);
		
	u_myNAND_063 : myNAND2
	port map (
		i_A => w_ctrl_000_n,
		i_B => w_instr27_n,
		o_Z => w_ctrl_063);
		
	u_myNAND_064 : myNAND2
	port map (
		i_A => w_ctrl_054_n,
		i_B => i_instr26,
		o_Z => w_ctrl_064);
		
	u_myNAND_065 : myNAND2
	port map (
		i_A => w_ctrl_056_n,
		i_B => w_ctrl_062_n,
		o_Z => w_ctrl_065);
		
	u_myNAND_066 : myNAND2
	port map (
		i_A => w_ctrl_057_n,
		i_B => w_instr26_n,
		o_Z => w_ctrl_066);
		
	u_myNAND_067 : myNAND2
	port map (
		i_A => w_ctrl_066_n,
		i_B => w_ctrl_065_n,
		o_Z => w_ctrl_067);
		
	u_myNAND_068 : myNAND2
	port map (
		i_A => w_ctrl_064,
		i_B => w_ctrl_067,
		o_Z => w_ctrl_068);
		
	u_myNAND_069 : myNAND2
	port map (
		i_A => w_ctrl_063_n,
		i_B => w_ctrl_068,
		o_Z => w_ctrl_069);
		
	u_myNAND_070 : myNAND2
	port map (
		i_A => i_instr01,
		i_B => w_instr00_n,
		o_Z => w_ctrl_070);
		
	u_myNAND_071 : myNAND2
	port map (
		i_A => w_ctrl_000_n,
		i_B => w_instr26_n,
		o_Z => w_ctrl_071);
		
	u_myNAND_072 : myNAND2
	port map (
		i_A => w_ctrl_054_n,
		i_B => i_instr27,
		o_Z => w_ctrl_072);
		
	u_myNAND_073 : myNAND2
	port map (
		i_A => w_ctrl_056_n,
		i_B => w_ctrl_070_n,
		o_Z => w_ctrl_073);
		
	u_myNAND_074 : myNAND2
	port map (
		i_A => w_ctrl_057_n,
		i_B => w_ctrl_073_n,
		o_Z => w_ctrl_074);
		
	u_myNAND_075 : myNAND2
	port map (
		i_A => w_ctrl_072,
		i_B => w_ctrl_148,
		o_Z => w_ctrl_075);
		
	u_myNAND_076 : myNAND2
	port map (
		i_A => w_ctrl_071_n,
		i_B => w_ctrl_075,
		o_Z => w_ctrl_076);
		
	u_myNAND_077 : myNAND2
	port map (
		i_A => i_instr01,
		i_B => i_instr00,
		o_Z => w_ctrl_077);
		
	u_myNAND_078 : myNAND2
	port map (
		i_A => w_ctrl_002_n,
		i_B => w_ctrl_055_n,
		o_Z => w_ctrl_078);
		
	u_myNAND_079 : myNAND2
	port map (
		i_A => w_ctrl_056_n,
		i_B => w_ctrl_077_n,
		o_Z => w_ctrl_079);
		
	u_myNAND_080 : myNAND2
	port map (
		i_A => w_ctrl_005_n,
		i_B => w_ctrl_078_n,
		o_Z => w_ctrl_080);
		
	u_myNAND_081 : myNAND2
	port map (
		i_A => w_ctrl_080_n,
		i_B => w_ctrl_079_n,
		o_Z => w_ctrl_081);
		
	u_myNAND_082 : myNAND2
	port map (
		i_A => w_ctrl_000_n,
		i_B => w_ctrl_054_n,
		o_Z => w_ctrl_082);
		
	u_myNAND_083 : myNAND2
	port map (
		i_A => w_ctrl_082_n,
		i_B => w_ctrl_041_n,
		o_Z => w_ctrl_083);
		
	u_myNAND_084 : myNAND2
	port map (
		i_A => w_ctrl_029_n,
		i_B => w_instr28_n,
		o_Z => w_ctrl_084);
		
	u_myNAND_085 : myNAND2
	port map (
		i_A => i_instr03,
		i_B => w_instr02_n,
		o_Z => w_ctrl_085);
		
	u_myNAND_086 : myNAND2
	port map (
		i_A => w_ctrl_055_n,
		i_B => w_ctrl_085_n,
		o_Z => w_ctrl_086);
		
	u_myNAND_087 : myNAND2
	port map (
		i_A => w_instr26_n,
		i_B => i_instr01,
		o_Z => w_ctrl_087);
		
	u_myNAND_094 : myNAND2
	port map (
		i_A => w_ctrl_005_n,
		i_B => w_ctrl_002_n,
		o_Z => w_ctrl_094);
		
	u_myNAND_095 : myNAND2
	port map (
		i_A => i_instr31,
		i_B => i_instr29,
		o_Z => w_ctrl_095);
		
	u_myNAND_098 : myNAND2
	port map (
		i_A => i_instr31,
		i_B => w_instr29_n,
		o_Z => w_ctrl_098);
		
	u_myNAND_099 : myNAND2
	port map (
		i_A => w_ctrl_000_n,
		i_B => i_instr29,
		o_Z => w_ctrl_099);
		
	u_myNAND_100 : myNAND2
	port map (
		i_A => w_instr28_n,
		i_B => w_ctrl_025,
		o_Z => w_ctrl_100);
		
	u_myNAND_101 : myNAND2
	port map (
		i_A => w_ctrl_009_n,
		i_B => w_ctrl_100,
		o_Z => w_ctrl_101);
		
	u_myNAND_102 : myNAND2
	port map (
		i_A => i_instr29,
		i_B => w_instr28_n,
		o_Z => w_ctrl_102);
		
	u_myNAND_103 : myNAND2
	port map (
		i_A => w_ctrl_053_n,
		i_B => w_ctrl_102_n,
		o_Z => w_ctrl_103);
		
	u_myNAND_106 : myNAND2
	port map (
		i_A => w_ctrl_014_n,
		i_B => w_ctrl_087_n,
		o_Z => w_ctrl_106);
		
	u_myNAND_107 : myNAND2
	port map (
		i_A => w_ctrl_086_n,
		i_B => w_ctrl_106_n,
		o_Z => w_ctrl_107);
		
	u_myNAND_108 : myNAND2
	port map (
		i_A => w_ctrl_029,
		i_B => w_ctrl_107,
		o_Z => w_ctrl_108);
		
	u_myNAND_109 : myNAND2
	port map (
		i_A => w_ctrl_028_n,
		i_B => w_ctrl_108,
		o_Z => w_ctrl_109);
		
	u_myNAND_110 : myNAND2
	port map (
		i_A => w_instr02_n,
		i_B => i_instr01,
		o_Z => w_ctrl_110);
		
	u_myNAND_111 : myNAND2
	port map (
		i_A => w_instr03_n,
		i_B => w_ctrl_110,
		o_Z => w_ctrl_111);
		
	u_myNAND_112 : myNAND2
	port map (
		i_A => w_ctrl_020_n,
		i_B => w_ctrl_111,
		o_Z => w_ctrl_112);
		
	u_myNAND_113 : myNAND2
	port map (
		i_A => w_ctrl_028_n,
		i_B => w_ctrl_112,
		o_Z => w_ctrl_113);
		
	u_myNAND_114 : myNAND2
	port map (
		i_A => w_ctrl_014_n,
		i_B => w_ctrl_113,
		o_Z => w_ctrl_114);
		
	u_myNAND_115 : myNAND2
	port map (
		i_A => w_ctrl_084,
		i_B => w_ctrl_114,
		o_Z => w_ctrl_115);
	
	u_myNAND_116 : myNAND2
	port map (
		i_A => w_ctrl_000_n,
		i_B => w_ctrl_115,
		o_Z => w_ctrl_116);
		
	u_myNAND_117 : myNAND2
	port map (
		i_A => w_ctrl_080_n,
		i_B => w_ctrl_044_n,
		o_Z => w_ctrl_117);
		
	u_myNAND_118 : myNAND2
	port map (
		i_A => w_ctrl_004_n,
		i_B => w_ctrl_070_n,
		o_Z => w_ctrl_118);
		
	u_myNAND_119 : myNAND2
	port map (
		i_A => w_ctrl_080_n,
		i_B => w_ctrl_118_n,
		o_Z => w_ctrl_119);
		
	u_myNAND_120 : myNAND2
	port map (
		i_A => w_ctrl_003_n,
		i_B => w_instr03_n,
		o_Z => w_ctrl_120);
	
	u_myNAND_121 : myNAND2
	port map (
		i_A => i_instr03,
		i_B => w_ctrl_110,
		o_Z => w_ctrl_121);
		
	u_myNAND_122 : myNAND2
	port map (
		i_A => w_ctrl_055_n,
		i_B => w_ctrl_121,
		o_Z => w_ctrl_122);
		
	u_myNAND_123 : myNAND2
	port map (
		i_A => w_ctrl_120_n,
		i_B => w_ctrl_062,
		o_Z => w_ctrl_123);
		
	u_myNAND_124 : myNAND2
	port map (
		i_A => w_ctrl_122,
		i_B => w_ctrl_123,
		o_Z => w_ctrl_124);
		
	u_myNAND_125 : myNAND2
	port map (
		i_A => w_instr20_n,
		i_B => w_instr19_n,
		o_Z => w_ctrl_125);
		
	u_myNAND_126 : myNAND2
	port map (
		i_A => w_instr18_n,
		i_B => w_instr17_n,
		o_Z => w_ctrl_126);
		
	u_myNAND_127 : myNAND2
	port map (
		i_A => w_ctrl_125_n,
		i_B => w_ctrl_126_n,
		o_Z => w_ctrl_127);
		
	u_myNAND_128 : myNAND2
	port map (
		i_A => w_ctrl_127_n,
		i_B => w_instr16_n,
		o_Z => w_ctrl_128);
		
	u_myNAND_129 : myNAND2
	port map (
		i_A => i_instr27,
		i_B => w_ctrl_128,
		o_Z => w_ctrl_129);
		
	u_myNAND_130 : myNAND2
	port map (
		i_A => i_instr31,
		i_B => w_instr28_n,
		o_Z => w_ctrl_130);
		
	u_myNAND_131 : myNAND2
	port map (
		i_A => w_ctrl_041_n,
		i_B => w_ctrl_130_n,
		o_Z => w_ctrl_131);
		
	u_myNAND_132 : myNAND2
	port map (
		i_A => w_instr27_n,
		i_B => w_instr28_n,
		o_Z => w_ctrl_132);
		
	u_myNAND_133 : myNAND2
	port map (
		i_A => i_instr28,
		i_B => w_ctrl_129,
		o_Z => w_ctrl_133);
		
	u_myNAND_134 : myNAND2
	port map (
		i_A => w_instr26_n,
		i_B => w_ctrl_124,
		o_Z => w_ctrl_134);
		
	u_myNAND_135 : myNAND2
	port map (
		i_A => i_instr26,
		i_B => w_ctrl_127_n,
		o_Z => w_ctrl_135);
		
	u_myNAND_136 : myNAND2
	port map (
		i_A => w_ctrl_134,
		i_B => w_ctrl_135,
		o_Z => w_ctrl_136);
		
	u_myNAND_137 : myNAND2
	port map (
		i_A => w_instr29_n,
		i_B => w_ctrl_133,
		o_Z => w_ctrl_137);
		
	u_myNAND_138 : myNAND2
	port map (
		i_A => w_ctrl_132_n,
		i_B => w_ctrl_136,
		o_Z => w_ctrl_138);
		
	u_myNAND_139 : myNAND2
	port map (
		i_A => w_ctrl_137_n,
		i_B => w_ctrl_138,
		o_Z => w_ctrl_139);
		
	u_myNAND_140 : myNAND2
	port map (
		i_A => w_instr31_n,
		i_B => w_ctrl_139,
		o_Z => w_ctrl_140);
		
	u_myNAND_141 : myNAND2
	port map (
		i_A => w_ctrl_131,
		i_B => w_ctrl_140,
		o_Z => w_ctrl_141);
		
	u_myNAND_142 : myNAND2
	port map (
		i_A => w_ctrl_029_n,
		i_B => i_instr26,
		o_Z => w_ctrl_142);
		
	u_myNAND_143 : myNAND2
	port map (
		i_A => w_ctrl_014_n,
		i_B => w_instr26_n,
		o_Z => w_ctrl_143);
		
	u_myNAND_144 : myNAND2
	port map (
		i_A => w_ctrl_143_n,
		i_B => w_ctrl_086_n,
		o_Z => w_ctrl_144);
		
	u_myNAND_145 : myNAND2
	port map (
		i_A => w_ctrl_144_n,
		i_B => w_ctrl_077_n,
		o_Z => w_ctrl_145);
		
	u_myNAND_146 : myNAND2
	port map (
		i_A => w_ctrl_142,
		i_B => w_ctrl_145,
		o_Z => w_ctrl_146);
		
	u_myNAND_147 : myNAND2
	port map (
		i_A => w_ctrl_028_n,
		i_B => w_ctrl_146,
		o_Z => w_ctrl_147);
		
	u_myNAND_148 : myNAND2
	port map (
		i_A => w_ctrl_074_n,
		i_B => w_instr27_n,
		o_Z => w_ctrl_148);
		
	--| Instantiate Inverters and NAND gates to generate output signals
	u_myINV_ALU_SRC_A0 : myINV
	port map (
		i_A => w_ctrl_008,
		o_Z => o_ALU_SRC_A0);
		
	u_myNAND_ALU_SRC_B1 : myNAND2
	port map (
		i_A => w_instr31_n,
		i_B => w_instr29_n,
		o_Z => o_ALU_SRC_B(1));
		
	u_myINV_ALU_SRC_B0 : myINV
	port map (
		i_A => w_ctrl_013,
		o_Z => o_ALU_SRC_B(0));
		
	u_myINV_INV_B : myINV
	port map (
		i_A => w_ctrl_116,
		o_Z => o_INV_B);
	
	u_myINV_LTZ : myINV
	port map (
		i_A => w_ctrl_033,
		o_Z => o_LTZ);
		
	u_myINV_EQ : myINV
	port map (
		i_A => w_ctrl_035,
		o_Z => o_EQ);
		
	u_myINV_NE : myINV
	port map (
		i_A => w_ctrl_036,
		o_Z => o_NE);
		
	u_myINV_LEZ : myINV
	port map (
		i_A => w_ctrl_040,
		o_Z => o_LEZ);
		
	u_myINV_GTZ : myINV
	port map (
		i_A => w_ctrl_042,
		o_Z => o_GTZ);
		
	u_myINV_RIGHT_SHIFT : myINV
	port map (
		i_A => w_ctrl_047,
		o_Z => o_RIGHT_SHIFT);
		
	u_myNAND_ADDER : myNAND2
	port map (
		i_A => w_instr31_n,
		i_B => w_ctrl_052,
		o_Z => o_ADDER);
	
	u_myINV_AND : myINV
	port map (
		i_A => w_ctrl_061,
		o_Z => o_AND);	
		
	u_myINV_OR : myINV
	port map (
		i_A => w_ctrl_069,
		o_Z => o_OR);
		
	u_myINV_XOR : myINV
	port map (
		i_A => w_ctrl_076,
		o_Z => o_XOR);
		
	u_myINV_NOR : myINV
	port map (
		i_A => w_ctrl_081,
		o_Z => o_NOR);
		
	u_myINV_COMPARE : myINV
	port map (
		i_A => w_ctrl_109,
		o_Z => o_COMPARE);
		
	u_myINV_LUI : myINV
	port map (
		i_A => w_ctrl_083,
		o_Z => o_LUI);
		
	u_myINV_REG_SEL0 : myINV
	port map (
		i_A => w_ctrl_094,
		o_Z => o_REG_SEL(0));
		
	u_myNAND_REG_SEL1 : myNAND2
	port map (
		i_A => w_ctrl_098,
		i_B => w_ctrl_099,
		o_Z => o_REG_SEL(1));
		
	u_myNAND_OVER_CTRL0 : myNAND2
	port map (
		i_A => w_ctrl_117,
		i_b => w_ctrl_103,
		o_Z => o_OVER_CTRL(0));
	
	u_myNAND_OVER_CTRL1 : myNAND2
	port map (
		i_A => w_ctrl_119,
		i_b => w_ctrl_103,
		o_Z => o_OVER_CTRL(1));
		
	u_myINV_UNSIGNED : myINV
	port map (
		i_A => w_ctrl_147,
		o_Z => o_UNSIGNED);
	
	o_overflow <= w_ctrl_025;
	
	o_imm_extend <= w_ctrl_082;
		
	u_myNAND_FSM_CTRL0 : myNAND2
	port map (
		i_A => w_ctrl_095,
		i_b => w_ctrl_101,
		o_Z => o_FSM_CTRL(0));
		
	u_myNAND_FSM_CTRL1 : myNAND2
	port map (
		i_A => w_ctrl_095,
		i_b => w_ctrl_098,
		o_Z => o_FSM_CTRL(1));
		
	u_myNAND_INVALID_INSTR : myNAND2
	port map (
		i_A => w_instr30_n,
		i_b => w_ctrl_141,
		o_Z => o_INVALID_INSTR);
end a_Instruction_Decoder;