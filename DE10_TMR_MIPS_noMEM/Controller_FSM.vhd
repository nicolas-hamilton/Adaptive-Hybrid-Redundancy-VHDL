--| Controller_FSM.vhd
--| Based on instructions input from memory, determine the type of instruction,
--| the correct sequence of state transitions for that type of instruction, and
--| issue the appropriate instructions to the datapath during the appropriate
--| states for that instruction.
--|
--| INPUTS:
--| i_clk		- Clock input
--| i_reset		- Reset input
--| i_MEM_OUT	- Output from memory to be stored into the instruction register
--| i_MEM_READY- Signal is 1 when memory has completed the read or write task
--|
--| OUTPUTS:
--| o_MEM_READ				- Read from memory enable signal
--| o_MEM_WRITE			- Write to memory enable signal
--| o_MEM_ADDRESS_SEL	- Select whether the memory address comes from the PC register or the ALU Result
--| o_STORE_FROM_MEM		- Store word from memory - select signal to determine if input to GPR_BANK is
--|							  from memory if '1' or from the ALU Result if '0'
--| o_PC_EN					- Enable the PC Register regardless of any other control signals.  Used to store
--|							  PC+4 to the PC register.
--| o_ALU_SRC_A			- ALU Source A selector
--| o_ALU_SRC_B			- ALU Source B selector
--| o_ALU_INV_B			- ALU Invert B selector
--| o_COMP_SEL 			- Select the value to output from the Comparator
--| o_OVER_CTRL			- Select which overflow detection means should be used
--|					  (i.e. ADD, ADDI, SUB, or no overflow detection).
--| o_ALU_OUTPUT			- Select which ALU function should be output
--|								0 - Shift Left
--|								1 - Shift Right
--|								2 - Adder
--|								3 - AND
--|								4 - OR
--|								5 - XOR
--|								6 - NOR
--|								7 - Comparator
--|								8 - LUI
--|								9, 10, 11, 12, 13, 14, 15 - Shift Left
--| o_REG_SEL				- Select the destination register
--| o_UNSIGNED				- Determine if the comparator is comparing sigend numbers (0) or unsigned
--|					  		  numbers (1).
--| o_overflow				- Determine if the comparator is performing a Less Than comparison that will
--|                       or will not produce an overflow.  No overflow can occur in BLTZ instructions,
--|							  but overflow can occur in SLT, SLTU, SLTI, and SLTIU instructions.  0 - no
--|							  overflow can occur, 1 - overflow can occur
--| o_imm_extend			- Determine if the immediate value should be 0 extended or sign extended
--| o_RS_SEL				- Reference to the RS register
--| o_RT_SEL				- Reference to the RT register
--| o_immediate			- The immediate value also contains the reference to
--|							  the RD register, the shift amount (SA), and bit zero
--|							  of the instruction (used to determine the difference
--|							  between a logical and arithmetic right shift by the
--|							  ALU Core's Right Shift module).
library IEEE;
use IEEE.std_logic_1164.all;

entity Controller_FSM is
	port (i_clk					: in  std_logic;
			i_reset				: in  std_logic;
			i_clk_en				: in  std_logic;
			i_MEM_OUT			: in  std_logic_vector(31 downto 0);
			i_MEM_READY			: in std_logic;
			o_MEM_READ			: out std_logic;
			o_MEM_WRITE			: out std_logic;
			o_MEM_ADDRESS_SEL	: out std_logic;
			o_STORE_FROM_MEM	: out std_logic;
			o_PC_EN				: out std_logic;
			o_ALU_SRC_A			: out std_logic_vector(1 downto 0);
			o_ALU_SRC_B			: out std_logic_vector(1 downto 0);
			o_ALU_INV_B 		: out std_logic;
			o_COMP_SEL			: out std_logic_vector(2 downto 0);
			o_OVER_CTRL 		: out std_logic_vector(1 downto 0);
			o_ALU_OUTPUT		: out std_logic_vector(3 downto 0);
			o_REG_SEL			: out std_logic_vector(1 downto 0);
			o_UNSIGNED			: out std_logic;
			o_overflow			: out std_logic;
			o_imm_extend		: out std_logic;
			o_RS_SEL				: out std_logic_vector(4 downto 0);
			o_RT_SEL				: out std_logic_vector(4 downto 0);
			o_immediate			: out std_logic_vector(15 downto 0);
			o_state				: out std_logic_vector(3 downto 0));-- remove later
end Controller_FSM;

architecture a_Controller_FSM of Controller_FSM is
--| Define Components
	-- Register to use for states
	component myRegN is
		generic (m_width : integer := 4);
		port (i_clk		: in  std_logic;
				i_reset	: in  std_logic;
				i_clk_en	: in  std_logic;
				i_D		: in  std_logic_vector (m_width-1 downto 0);
				o_Q		: out std_logic_vector (m_width-1 downto 0));
	end component;
	
	-- Enabled Register
	component Enabled_Register is
		port (i_clk		: in  std_logic;
				i_reset	: in  std_logic;
				i_clk_en	: in  std_logic;
				i_data	: in  std_logic_vector(31 downto 0);
				i_en		: in  std_logic;
				o_Q		: out std_logic_vector(31 downto 0));
	end component;
	
	-- 2-input N-bit mux
	component myMUX2_N is
		generic (m_width : integer := 4);
		port (i_0 : in  std_logic_vector(m_width-1 downto 0);
				i_1 : in  std_logic_vector(m_width-1 downto 0);
				i_S : in  std_logic;
				o_Z : out std_logic_vector(m_width-1 downto 0));
	end component;
	
	-- 4-input N-bit mux
	component myMUX4_N is
		generic (m_width : integer := 4);
		port (i_0 : in  std_logic_vector(m_width-1 downto 0);
				i_1 : in  std_logic_vector(m_width-1 downto 0);
				i_2 : in  std_logic_vector(m_width-1 downto 0);
				i_3 : in  std_logic_vector(m_width-1 downto 0);
				i_S : in  std_logic_vector(1 downto 0);
				o_Z : out std_logic_vector(m_width-1 downto 0));
	end component;
	
	-- 16-input N-bit mux
	component myMUX16_N is
		generic (m_width : integer := 4);
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

	-- FSM Control Signal Generator to generate state dependent control signals
	component FSM_Control_Signal_Generator is
		port (i_state					: in  std_logic_vector(3 downto 0);
				o_MEM_READ				: out std_logic;
				o_MEM_WRITE				: out std_logic;
				o_MEM_ADDRESS_SEL		: out std_logic;
				o_STORE_FROM_MEM		: out std_logic;
				o_PC_STORE				: out std_logic;
				o_PC_EN					: out std_logic;
				o_DO_NOT_STORE			: out std_logic;
				o_BRANCH_OVERRIDE		: out std_logic;
				o_STORE_INSTRUCTION	: out std_logic);
	end component;
	
	-- Instruction Decoder and Encoder to generate instruction and state dependent control signals
	component Instruction_Dec_Enc is
		port (i_instr31			: in  std_logic;
				i_instr30			: in  std_logic;
				i_instr29			: in  std_logic;
				i_instr28			: in  std_logic;
				i_instr27			: in  std_logic;
				i_instr26			: in  std_logic;
				i_instr20			: in  std_logic;
				i_instr19			: in  std_logic;
				i_instr18			: in  std_logic;
				i_instr17			: in  std_logic;
				i_instr16			: in  std_logic;
				i_instr05			: in  std_logic;
				i_instr04			: in  std_logic;
				i_instr03			: in  std_logic;
				i_instr02			: in  std_logic;
				i_instr01			: in  std_logic;
				i_instr00			: in  std_logic;
				i_BRANCH_OVERRIDE	: in  std_logic;
				i_DO_NOT_STORE		: in  std_logic;
				i_PC_STORE			: in  std_logic;
				o_ALU_SRC_A			: out std_logic_vector(1 downto 0);
				o_ALU_SRC_B			: out std_logic_vector(1 downto 0);
				o_ALU_INV_B 		: out std_logic;
				o_COMP_SEL			: out std_logic_vector(2 downto 0);
				o_OVER_CTRL 		: out std_logic_vector(1 downto 0);
				o_ALU_OUTPUT		: out std_logic_vector(3 downto 0);
				o_REG_SEL			: out std_logic_vector(1 downto 0);
				o_UNSIGNED			: out std_logic;
				o_overflow			: out std_logic;
				o_imm_extend		: out std_logic;
				o_FSM_CTRL			: out std_logic_vector(1 downto 0);
				o_INVALID_INSTR	: out std_logic);
	end component;

--| Define Signals
	-- Finite State Machine Signals
	signal w_state			: std_logic_vector(3 downto 0); -- Current state of the FSM
	signal w_next_state	: std_logic_vector(3 downto 0); -- Next state of the FSM
	signal w_next_state0	: std_logic_vector(3 downto 0); -- Potentially the next state if the FSM if there is no instruction error
	signal w_next_state12: std_logic_vector(3 downto 0); -- Potentially the next state if the FSM is currently in state 1
	signal w_next_state2	: std_logic_vector(3 downto 0); -- Potentially the next state if the FSM is currently in state 2
	signal w_next_state01: std_logic_vector(3 downto 0); -- Potentially the next state if the FSM is currently in state 0
	signal w_next_state67: std_logic_vector(3 downto 0); -- Potentially the next state if the FSM is currently in state 6
	signal w_next_state70: std_logic_vector(3 downto 0); -- Potentially the next state if the FSM is currently in state 7
	signal w_next_state89: std_logic_vector(3 downto 0); -- Potentially the next state if the FSM is currently in state 8
	signal w_next_state90: std_logic_vector(3 downto 0); -- Potentially the next state if the FSM is currently in state 9
	
	
	-- Instruction Signal
	signal w_instruction : std_logic_vector(31 downto 0);
	
	-- Internal Control SIgnals
	signal w_BRANCH_OVERRIDE	: std_logic; -- See description in Instruction_Dec_Enc.vhd
	signal w_DO_NOT_STORE		: std_logic; -- See description in Instruction_Dec_Enc.vhd
	signal w_PC_STORE				: std_logic; -- See description in Instruction_Dec_Enc.vhd
	signal w_STORE_INSTRUCTION	: std_logic; -- Enable the Instruction Register to store the data from memory
	signal w_INVALID_INSTR: std_logic; 		 -- Signal to set the FSM to state 0 if an invalid instruction is detected
	signal w_FSM_CTRL		: std_logic_vector(1 downto 0); -- Signal to determine the value of w_next_state2 depending on the instruction
	
--| Define Constants
	constant k_zero_4		: std_logic_vector(3 downto 0) := (others => '0');
	constant k_one_4		: std_logic_vector(3 downto 0) := B"0001";
	constant k_two_4		: std_logic_vector(3 downto 0) := B"0010";
	constant k_three_4	: std_logic_vector(3 downto 0) := B"0011";
	constant k_four_4		: std_logic_vector(3 downto 0) := B"0100";
	constant k_five_4		: std_logic_vector(3 downto 0) := B"0101";
	constant k_six_4		: std_logic_vector(3 downto 0) := B"0110";
	constant k_seven_4	: std_logic_vector(3 downto 0) := B"0111";
	constant k_eight_4	: std_logic_vector(3 downto 0) := B"1000";
	constant k_nine_4		: std_logic_vector(3 downto 0) := B"1001";
	constant k_ten_4		: std_logic_vector(3 downto 0) := B"1010";
	
begin
	o_state <= w_state; -- remove later
	-- Connect Instruction Register
	u_Instruction_Register: Enabled_Register
	port map (i_clk => i_clk,
				 i_reset => i_reset,
				 i_clk_en => i_clk_en,
				 i_data => i_MEM_OUT,
				 i_en => w_STORE_INSTRUCTION,
				 o_Q => w_instruction);
	-- Connect instruction register related outputs
	o_RS_SEL <= w_instruction(25 downto 21);
	o_RT_SEL <= w_instruction(20 downto 16);
	o_immediate <= w_instruction(15 downto 0);
	
	-- Connect the State Register
	u_State_Register: myRegN
	generic map (m_width => 4)
	port map (i_clk => i_clk,
				 i_reset => i_reset,
				 i_clk_en => i_clk_en,
				 i_D => w_next_state,
				 o_Q => w_state);
				 
	-- Connect the MUXes to determine the next state
	u_myMUX2_INVALID: myMUX2_N
	generic map (m_width => 4)
	port map (i_0 => w_next_state0,
				 i_1 => k_zero_4,
				 i_S => w_INVALID_INSTR,
				 o_Z => w_next_state);

	u_myMUX2_next_state12: myMUX2_N
	generic map (m_width => 4)
	port map (i_0 => k_two_4,
				 i_1 => k_one_4,
				 i_S => i_MEM_READY,
				 o_Z => w_next_state12);

	u_myMUX2_next_state01: myMUX2_N
	generic map (m_width => 4)
	port map (i_0 => k_zero_4,
				 i_1 => k_one_4,
				 i_S => i_MEM_READY,
				 o_Z => w_next_state01);

	u_myMUX2_next_state67: myMUX2_N
	generic map (m_width => 4)
	port map (i_0 => k_six_4,
				 i_1 => k_seven_4,
				 i_S => i_MEM_READY,
				 o_Z => w_next_state67);

	u_myMUX2_next_state70: myMUX2_N
	generic map (m_width => 4)
	port map (i_0 => k_ten_4,
				 i_1 => k_seven_4,
				 i_S => i_MEM_READY,
				 o_Z => w_next_state70);

	u_myMUX2_next_state89: myMUX2_N
	generic map (m_width => 4)
	port map (i_0 => k_eight_4,
				 i_1 => k_nine_4,
				 i_S => i_MEM_READY,
				 o_Z => w_next_state89);

	u_myMUX2_next_state90: myMUX2_N
	generic map (m_width => 4)
	port map (i_0 => k_ten_4,
				 i_1 => k_nine_4,
				 i_S => i_MEM_READY,
				 o_Z => w_next_state90);
	
	u_myMUX16_N: myMUX16_N
	generic map (m_width => 4)
	port map (i_0 => w_next_state01,
				 i_1 => w_next_state12,
				 i_2 => w_next_state2,
				 i_3 => k_zero_4,
				 i_4 => k_five_4,
				 i_5 => k_zero_4,
				 i_6 => w_next_state67,
				 i_7 => w_next_state70,
				 i_8 => w_next_state89,
				 i_9 => w_next_state90,
				 i_10 => k_zero_4,
				 i_11 => k_zero_4,
				 i_12 => k_zero_4,
				 i_13 => k_zero_4,
				 i_14 => k_zero_4,
				 i_15 => k_zero_4,
				 i_S => w_state,
				 o_Z => w_next_state0);
	
	u_myMUX4_INSTRUCTION_TYPE: myMUX4_N
	generic map (m_width => 4)
	port map (i_0 => k_three_4,
				 i_1 => k_four_4,
				 i_2 => k_six_4,
				 i_3 => k_eight_4,
				 i_S => w_FSM_CTRL,
				 o_Z => w_next_state2);
	-- Connect the Control Signal Generator
	u_FSM_Control_Signal_Generator: FSM_Control_Signal_Generator
	port map (i_state => w_state,
				 o_MEM_READ => o_MEM_READ,
				 o_MEM_WRITE => o_MEM_WRITE,
				 o_MEM_ADDRESS_SEL => o_MEM_ADDRESS_SEL,
				 o_STORE_FROM_MEM => o_STORE_FROM_MEM,
				 o_PC_STORE => w_PC_STORE,
				 o_PC_EN => o_PC_EN,
				 o_DO_NOT_STORE => w_DO_NOT_STORE,
				 o_BRANCH_OVERRIDE => w_BRANCH_OVERRIDE,
				 o_STORE_INSTRUCTION => w_STORE_INSTRUCTION);
	-- Connec the Instruction Decoder/Encoder
	u_Instruction_Dec_Enc: Instruction_Dec_Enc
	port map (i_instr31 => w_instruction(31),
				 i_instr30 => w_instruction(30),
				 i_instr29 => w_instruction(29),
				 i_instr28 => w_instruction(28),
				 i_instr27 => w_instruction(27),
				 i_instr26 => w_instruction(26),
				 i_instr20 => w_instruction(20),
				 i_instr19 => w_instruction(19),
				 i_instr18 => w_instruction(18),
				 i_instr17 => w_instruction(17),
				 i_instr16 => w_instruction(16),
				 i_instr05 => w_instruction(5),
				 i_instr04 => w_instruction(4),
				 i_instr03 => w_instruction(3),
				 i_instr02 => w_instruction(2),
				 i_instr01 => w_instruction(1),
				 i_instr00 => w_instruction(0),
				 i_BRANCH_OVERRIDE => w_BRANCH_OVERRIDE,
				 i_DO_NOT_STORE => w_DO_NOT_STORE,
				 i_PC_STORE => w_PC_STORE,
				 o_ALU_SRC_A => o_ALU_SRC_A,
				 o_ALU_SRC_B => o_ALU_SRC_B,
				 o_ALU_INV_B => o_ALU_INV_B,
				 o_COMP_SEL => o_COMP_SEL,
				 o_OVER_CTRL => o_OVER_CTRL,
				 o_ALU_OUTPUT => o_ALU_OUTPUT,
				 o_REG_SEL => o_REG_SEL,
				 o_UNSIGNED => o_UNSIGNED,
				 o_overflow => o_overflow,
				 o_imm_extend => o_imm_extend,
				 o_FSM_CTRL => w_FSM_CTRL,
				 o_INVALID_INSTR => w_INVALID_INSTR);
end a_Controller_FSM;