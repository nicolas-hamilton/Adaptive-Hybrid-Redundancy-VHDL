--| ALU_CORE.vhd
--| Determine the A and B inputs to the ALU submodules, connect all of the
--| ALU submodules, and select which submodule should have its output be
--| ALU output.
--|
--| INPUTS:
--| i_ALU_SRC_A	- ALU Source A selector
--| i_ALU_SRC_B	- ALU Source B selector
--| i_ALU_INV_B	- ALU Invert B selector
--| i_COMP_SEL 	- Select the value to output from the Comparator
--| i_OVER_CTRL	- Select which overflow detection means should be used
--|					  (i.e. ADD, ADDI, SUB, or no overflow detection).
--| i_ALU_OUTPUT	- Select which ALU function should be output
--|						0 - Shift Left
--|						1 - Shift Right
--|						2 - Adder
--|						3 - AND
--|						4 - OR
--|						5 - XOR
--|						6 - NOR
--|						7 - Comparator
--|						8 - LUI
--|						9, 10, 11, 12, 13, 14, 15 - Shift Left
--| i_RS_DATA		- Data from the register specified by RS
--| i_RT_DATA		- Data from the register specified by RS
--| i_RD_DATA		- Data from the register specified by RS
--| i_PC				- Address stored in the PC register
--| i_imm			- Immediate/offset value
--| i_UNSIGNED		- Determine if the comparator is comparing sigend numbers
--|					  (0) or unsigned numbers (1).
--| i_overflow		- Determine if the comparator is performing a Less Than comparison that will
--|                 or will not produce an overflow.  No overflow can occur in BLTZ instructions,
--|					  but overflow can occur in SLT, SLTU, SLTI, and SLTIU instructions.  0 - no
--|					  overflow can occur, 1 - overflow can occur
--| i_imm_extend	- Determine if the immediate value should be 0 extended or
--|					  sign extended. 0 for zero extended.  1 for sign extended.
--|
--| OUTPUTS:
--| o_ALU_RESULT
library IEEE;
use IEEE.std_logic_1164.all;

entity ALU_CORE is
	port (i_clk				: in std_logic;
			i_reset			: in std_logic;
			i_clk_en			: in std_logic;
			i_ALU_SRC_A		: in  std_logic_vector(1 downto 0);
			i_ALU_SRC_B		: in  std_logic_vector(1 downto 0);
			i_ALU_INV_B 	: in  std_logic;
			i_COMP_SEL		: in  std_logic_vector(2 downto 0);
			i_OVER_CTRL 	: in  std_logic_vector(1 downto 0);
			i_ALU_OUTPUT	: in  std_logic_vector(3 downto 0);
			i_RS_DATA		: in  std_logic_vector(31 downto 0);
			i_RT_DATA		: in  std_logic_vector(31 downto 0);
			i_RD_DATA		: in  std_logic_vector(31 downto 0);
			i_PC				: in  std_logic_vector(31 downto 0);
			i_imm				: in  std_logic_vector(15 downto 0);
			i_UNSIGNED		: in  std_logic;
			i_overflow		: in  std_logic;
			i_imm_extend	: in  std_logic;
			o_ALU_RESULT	: out std_logic_vector(31 downto 0));
end ALU_CORE;

architecture a_ALU_CORE of ALU_CORE is
--| Define Components
	component myINV_N is
		generic(m_width : integer := 32);
		port (i_A	: in  std_logic_vector(m_width-1 downto 0);
				o_Z	: out std_logic_vector(m_width-1 downto 0));
	end component;
	
	component myMUX16_N is
		generic (m_width : integer := 32);
		port (i_0 : in  std_logic_vector(m_width-1 downto 0);
				i_1 : in  std_logic_vector(m_width-1 downto 0);
				i_2 : in  std_logic_vector(m_width-1 downto 0);
				i_3 : in  std_logic_vector(m_width-1 downto 0);
				i_4 : in  std_logic_vector(m_width-1 downto 0);
				i_5 : in  std_logic_vector(m_width-1 downto 0);
				i_6 : in  std_logic_vector(m_width-1 downto 0);
				i_7 : in  std_logic_vector(m_width-1 downto 0);
				i_8 : in  std_logic_vector(m_width-1 downto 0);
				i_9 : in  std_logic_vector(m_width-1 downto 0);
				i_10 : in  std_logic_vector(m_width-1 downto 0);
				i_11 : in  std_logic_vector(m_width-1 downto 0);
				i_12 : in  std_logic_vector(m_width-1 downto 0);
				i_13 : in  std_logic_vector(m_width-1 downto 0);
				i_14 : in  std_logic_vector(m_width-1 downto 0);
				i_15 : in  std_logic_vector(m_width-1 downto 0);
				i_S : in  std_logic_vector(3 downto 0);
				o_Z : out std_logic_vector(m_width-1 downto 0));
	end component;
	
	component myMUX4_N is
		generic (m_width : integer := 32);
		port (i_0 : in  std_logic_vector(m_width-1 downto 0);
				i_1 : in  std_logic_vector(m_width-1 downto 0);
				i_2 : in  std_logic_vector(m_width-1 downto 0);
				i_3 : in  std_logic_vector(m_width-1 downto 0);
				i_S : in  std_logic_vector(1 downto 0);
				o_Z : out std_logic_vector(m_width-1 downto 0));
	end component;
	
	component myMUX2_N is
		generic (m_width : integer := 32);
		port (i_0 : in  std_logic_vector(m_width-1 downto 0);
				i_1 : in  std_logic_vector(m_width-1 downto 0);
				i_S : in  std_logic;
				o_Z : out std_logic_vector(m_width-1 downto 0));
	end component;
	
	component myMUX2_1 is
		port (i_0 : in  std_logic;
				i_1 : in  std_logic;
				i_S : in  std_logic;
				o_Z : out std_logic);
	end component;
	
	component Sign_Extend16_32 is
		port (i_A	: in  std_logic_vector(15 downto 0);
				o_Z	: out std_logic_vector(31 downto 0));
	end component;
	
	component Extend16_32 is
		port (i_A	: in  std_logic_vector(15 downto 0);
				o_Z	: out std_logic_vector(31 downto 0));
	end component;
	
	component Extend5_32 is
		port (i_A	: in  std_logic_vector(4 downto 0);
				o_Z	: out std_logic_vector(31 downto 0));
	end component;
	
	component SLL2_32 is
		port (i_A	: in  std_logic_vector(31 downto 0);
				o_Z	: out std_logic_vector(31 downto 0));
	end component;
	
	component myReg1 is
		port (i_clk		: in  std_logic;
				i_reset	: in  std_logic;
				i_clk_en			: in std_logic;
				i_D		: in  std_logic;
				o_Q		: out std_logic);
	end component;
	
	component CARRY_SELECT_ADDER_32 is
		port (i_A			: in  std_logic_vector(31 downto 0);
				i_A_n			: in  std_logic_vector(31 downto 0);
				i_B			: in  std_logic_vector(31 downto 0);
				i_B_n			: in  std_logic_vector(31 downto 0);
				i_AB_AND		: in  std_logic_vector(31 downto 0);
				i_AB_NAND	: in  std_logic_vector(31 downto 0);
				i_AB_NOR		: in  std_logic_vector(31 downto 0);
				i_C			: in  std_logic;
				o_S			: out std_logic_vector(31 downto 0);
				o_C			: out std_logic);
	end component;
	
	component LEFT_SHIFT is
		port (i_A	: in  std_logic_vector(31 downto 0);
				i_SA	: in  std_logic_vector(4 downto 0);
				o_Z	: out std_logic_vector(31 downto 0)
				);
	end component;
	
	component RIGHT_SHIFT is
		port (i_A		: in  std_logic_vector(31 downto 0);
				i_SA		: in  std_logic_vector(4 downto 0);
				i_ARITH	: in std_logic;
				o_Z		: out std_logic_vector(31 downto 0)
				);
	end component;
	
	component Bitwise_Ops2_32 is
		port (i_A		: in  std_logic_vector(31 downto 0);
				i_B		: in  std_logic_vector(31 downto 0);
				o_A_n		: out std_logic_vector(31 downto 0);
				o_B_n 	: out std_logic_vector(31 downto 0);
				o_AND		: out std_logic_vector(31 downto 0);
				o_NAND	: out std_logic_vector(31 downto 0);
				o_OR		: out std_logic_vector(31 downto 0);
				o_XOR		: out std_logic_vector(31 downto 0);
				o_XNOR	: out std_logic_vector(31 downto 0);
				o_NOR		: out std_logic_vector(31 downto 0));
	end component;
	
	component Comparator is
		port (i_S			: in  std_logic_vector(31 downto 0);
				i_NAND_AB	: in  std_logic;
				i_OR_AB		: in  std_logic;
				i_XNOR_AB	: in  std_logic;
				i_unsigned	: in  std_logic;
				i_overflow	: in  std_logic;
				i_COMP_SEL	: in  std_logic_vector(2 downto 0);
				o_Z			: out std_logic);
	end component;
	
	component LUI is
		port (i_A : in  std_logic_vector(15 downto 0);
				o_Z : out std_logic_vector(31 downto 0)
				);
	end component;
	
	component Over_Detect is
		port (i_AB_NAND	: in  std_logic; -- From bitwise operations on bit 31 - NAND(A,B)
				i_AB_OR		: in  std_logic; -- From bitwise operations on bit 31 - OR(A,B)
				i_AB_XNOR	: in  std_logic; -- From bitwise operations on bit 31 - XNOR(A,B)
				i_S			: in  std_logic_vector(31 downto 0);
				i_RD			: in  std_logic_vector(31 downto 0);
				i_RT			: in  std_logic_vector(31 downto 0);
				i_OVER_CTRL	: in  std_logic_vector(1 downto 0);
				o_Z			: out std_logic_vector(31 downto 0)
				);
	end component;

--| Define Signals
	signal w_A				: std_logic_vector(31 downto 0); -- ALU Input A
	signal w_A_n				: std_logic_vector(31 downto 0); -- Inverted ALU Input A
	signal w_B				: std_logic_vector(31 downto 0); -- ALU Input B
	signal w_B_n				: std_logic_vector(31 downto 0); -- Inverted ALU Input B
	signal w_B0				: std_logic_vector(31 downto 0); -- Preliminary ALU Input - B may become B0 or INV(B0) depending on the value of i_ALU_INV_B
	signal w_B0_n			: std_logic_vector(31 downto 0); -- INV(B0)
	signal w_AB_NAND		: std_logic_vector(31 downto 0); -- NAND(A,B)
	signal w_SA_EXT		: std_logic_vector(31 downto 0); -- Zero extended i_SA
	signal w_IMM_EXT0		: std_logic_vector(31 downto 0); -- Zero extended immediate
	signal w_IMM_EXT1		: std_logic_vector(31 downto 0); -- Sign extended immediate
	signal w_IMM_EXT		: std_logic_vector(31 downto 0); -- Zero or Sign Extended immediate
	signal w_IMM_SLL2		: std_logic_vector(31 downto 0); -- Sign extended immediate left shifted by 2
	signal w_comp_out		: std_logic;							-- Output of the comparator
	signal f_comp_out		: std_logic;							-- Output of the comparator delayed one clock cycle
	signal ff_comp_out	: std_logic;							-- Output of the comparator delayed two clock cycles
	signal w_SLX			: std_logic_vector(31 downto 0); -- Output of the LEFT_SHIFT
	signal w_SRX			: std_logic_vector(31 downto 0); -- Output of the RIGHT_SHIFT
	signal w_ADD0			: std_logic_vector(31 downto 0); -- Output of the adder
	signal w_ADD			: std_logic_vector(31 downto 0); -- Output of the adder after overflow detection
	signal w_AND			: std_logic_vector(31 downto 0); -- Output of the bitwise AND
	signal w_OR				: std_logic_vector(31 downto 0); -- Output of the bitwsie OR
	signal w_XOR			: std_logic_vector(31 downto 0); -- Output of the bitwise XOR
	signal w_XNOR			: std_logic_vector(31 downto 0); -- Output of the bitwise XNOR - inverted XOR signal
	signal w_NOR			: std_logic_vector(31 downto 0); -- Output of the bitwise NOR
	signal w_COMP			: std_logic_vector(31 downto 0); -- Result of a logical comparison (k_zero32 for false and k_one32 for true).
	signal w_LUI			: std_logic_vector(31 downto 0); -- Output of the bitwise LUI
	signal w_ALU_SRC_B_3 : std_logic_vector(31 downto 0); -- Input 3 to the ALU_SRC_B selection MUX
	
--| Define Constants
	constant k_zero32	: std_logic_vector(31 downto 0) := (others => '0');
	constant k_one32	: std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_0000_0000_0001";
	constant k_four32 : std_logic_vector(31 downto 0) := B"0000_0000_0000_0000_0000_0000_0000_0100";
	
begin
	-- Extend the SA value
	u_Extend_SA: Extend5_32
	port map(i_A => i_imm(10 downto 6), --i_SA
				o_Z => w_SA_EXT);
	
	-- Zero extend the immediate value
	u_Extend_IMM: Extend16_32
	port map(i_A => i_imm,
				o_Z => w_IMM_EXT0);
	
	-- Sign extend the immediate value
	u_Sign_Extend_IMM: Sign_Extend16_32
	port map(i_A => i_imm,
				o_Z => w_IMM_EXT1);
			
	-- Determine the input to ALU_SRC_B selection MUX input 3 (B"11")
	u_myMUX2_IMM_EXTEND: myMUX2_N
	generic map (m_width => 32)
	port map (i_0 => w_IMM_EXT0,
				 i_1 => w_IMM_EXT1,
				 i_S => i_imm_extend,
				 o_Z => w_IMM_EXT);		
			
	-- Shift the sign extended immediate value left by 2
	u_SLL2_IMM: SLL2_32
	port map(i_A => w_IMM_EXT1,
				o_Z => w_IMM_SLL2);
				
	-- Determine the input to ALU_SRC_B selection MUX input 3 (B"11")
	u_myMUX2_ALU_SRC_B_3: myMUX2_N
	generic map (m_width => 32)
	port map (i_0 => k_four32,
				 i_1 => w_IMM_SLL2,
				 i_S => ff_comp_out,
				 o_Z => w_ALU_SRC_B_3);
				 
	-- Determine the A input to the ALU
	u_ALU_SRC_A: myMUX4_N
	generic map (m_width => 32)
	port map (i_0 => i_RS_DATA,
				 i_1 => w_SA_EXT,
				 i_2 => i_PC,
				 i_3 => i_PC,
				 i_S => i_ALU_SRC_A,
				 o_Z => w_A);
				 
	-- Determine the B0 input to the ALU
	u_ALU_SRC_B: myMUX4_N
	generic map (m_width => 32)
	port map (i_0 => k_zero32,
				 i_1 => i_RT_DATA,
				 i_2 => w_IMM_EXT,
				 i_3 => w_ALU_SRC_B_3,
				 i_S => i_ALU_SRC_B,
				 o_Z => w_B0);
				 
	-- Create inverted B0
	u_myINV_B0: myINV_N
	generic map (m_width => 32)
	port map (i_A => w_B0,
				 o_Z => w_B0_n);
				 
	-- Determine whether to use B0 or B0_n as the B input
	u_myMUX2_B: myMUX2_N
	generic map (m_width => 32)
	port map (i_0 => w_B0,
				 i_1 => w_B0_n,
				 i_S => i_ALU_INV_B,
				 o_Z => w_B);
	
	-- Connect the LEFT_SHIFT Module
	u_LEFT_SHIFT: LEFT_SHIFT
	port map (i_A => w_B,
				 i_SA => w_A(4 downto 0),
				 o_Z => w_SLX);
				 
	-- Connect the RIGHT_SHIFT Module
	u_RIGHT_SHIFT: RIGHT_SHIFT
	port map (i_A => w_B,
				 i_SA => w_A(4 downto 0),
				 i_ARITH => i_imm(0), --i_instr0
				 o_Z => w_SRX);
				 
	-- Connect the Adder Module
	u_CARRY_SELECT_ADDER_32: CARRY_SELECT_ADDER_32
	port map (i_A => w_A,
				 i_A_n => w_A_n,
				 i_B => w_B,
				 i_B_n => w_B_n,
				 i_AB_AND => w_AND,
				 i_AB_NAND => w_AB_NAND,
				 i_AB_NOR => w_NOR,
				 i_C => i_ALU_INV_B,
				 o_S => w_ADD0,
				 o_C => OPEN);
				 
	-- Connect the Bitwise Operations Module
	u_Bitwise_Ops2_32: Bitwise_Ops2_32
	port map (i_A => w_A,
				 i_B => w_B,
				 o_A_n => w_A_n,
				 o_B_n => w_B_n,
				 o_AND => w_AND,
				 o_NAND => w_AB_NAND,
				 o_OR => w_OR,
				 o_XOR => w_XOR,
				 o_XNOR => w_XNOR,
				 o_NOR => w_NOR);
				 
	-- Connect Load Upper Immediate Module
	u_LUI: LUI
	port map (i_A => w_B(15 downto 0),
				 o_Z => w_LUI);
				 
	-- Connect Comparator
	u_Comparator: Comparator
	port map (i_S => w_ADD0,
				 i_NAND_AB => w_AB_NAND(31),
				 i_OR_AB => w_OR(31),
				 i_XNOR_AB => w_XNOR(31),
				 i_unsigned => i_UNSIGNED,
				 i_overflow => i_overflow,
				 i_COMP_SEL => i_COMP_SEL,
				 o_Z => w_comp_out);
				 
	-- Connect Register to store value of comparator
	u_myReg_delay_1: myReg1
	port map (i_clk => i_clk,
				 i_reset => i_reset,
				 i_clk_en => i_clk_en,
				 i_D => w_comp_out,
				 o_Q => f_comp_out);
				 
	u_myReg_delay_2: myReg1
	port map (i_clk => i_clk,
				 i_reset => i_reset,
				 i_clk_en => i_clk_en,
				 i_D => f_comp_out,
				 o_Q => ff_comp_out);
				 
	-- Determine Output for a Set On Less Than Instruction
	u_myMUX2_COMP: myMUX2_N
	generic map (m_width => 32)
	port map (i_0 => k_zero32,
				 i_1 => k_one32,
				 i_S => w_comp_out,
				 o_Z => w_COMP);
				 
	-- Connect Overflow Detection
	u_Over_Detect: Over_Detect
	port map(i_AB_NAND => w_AB_NAND(31),
				i_AB_OR => w_OR(31),
				i_AB_XNOR => w_XNOR(31),
				i_S => w_ADD0,
				i_RD => i_RD_DATA,
				i_RT => i_RT_DATA,
				i_OVER_CTRL => i_OVER_CTRL,
				o_Z => w_ADD);
				
	-- Determine ALU Output
	u_myMUX16_ALU_OUT: myMUX16_N
	generic map (m_width => 32)
	port map (i_0 => w_SLX,
				 i_1 => w_SRX,
				 i_2 => w_ADD,
				 i_3 => w_AND,
				 i_4 => w_OR,
				 i_5 => w_XOR,
				 i_6 => w_NOR,
				 i_7 => w_COMP,
				 i_8 => w_LUI,
				 i_9 => w_SRX,  -- MUX inputs 9-15 were chosen to minimize the error should a bit flip occur
				 i_10 => w_ADD, -- in the MSB position of the ALU_OUTPUT control signal.  For i_9 "1001" is
				 i_11 => w_AND, -- w_SRX which is also conneted to i_1 "0001".For i_14 "1110" is w_NOR which
				 i_12 => w_OR,  -- is also connected to i_6 "0110".
				 i_13 => w_XOR,
				 i_14 => w_NOR,
				 i_15 => w_COMP,
				 i_S => i_ALU_OUTPUT,
				 o_Z => o_ALU_RESULT);
	
end a_ALU_CORE;