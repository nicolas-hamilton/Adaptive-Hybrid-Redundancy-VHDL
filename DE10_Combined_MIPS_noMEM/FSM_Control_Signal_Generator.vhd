--| FSM_Control_Signal_Generator.vhd
--| Determines the control signals issued by the FSM Controller based on the
--| current state.
--|
--| INPUTS:
--| i_state - current state of the FSM
--|
--| OUTPUTS:
--| o_MEM_READ				- Read from memory enable signal
--| o_MEM_WRITE			- Write to memory enable signal
--| o_MEM_ADDRESS_SEL	- Select whether the memory address comes from the PC register or the ALU Result
--| o_STORE_FROM_MEM		- Store word from memory - select signal to determine if input to GPR_BANK is
--|							  from memory if '1' or from the ALU Result if '0'
--| o_PC_STORE				- Override the normal value of REG_SEL to store the ALU Result to the PC register
--| o_PC_EN					- Enable the PC Register regardless of any other control signals.  Used to store
--|							  PC+4 to the PC register.
--| o_DO_NOT_STORE		- Override the normal value of REG_SEL not store any incoming data to the GPR_BANK
--| o_BRANCH_OVERRIDE	- Override the normal value of the ALU_SRC_A, ALU_SRC_B, ALU_INV_B, and ALU_OUTPUT
--|							  control signals for a branch instruction
--| o_STORE_INSTRUCTION	- Enable the instruction register to store the data read from memory
library IEEE;
use IEEE.std_logic_1164.all;

entity FSM_Control_Signal_Generator is
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
end FSM_Control_Signal_Generator;

architecture a_FSM_Control_Signal_Generator of FSM_Control_Signal_Generator is
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
	-- Inverted State Signals
	signal w_S3_n : std_logic;
	signal w_S2_n : std_logic;
	signal w_S1_n : std_logic;
	signal w_S0_n : std_logic;
	
	-- Intermediate control signals (and inverted control signals) used to compute outputs
	signal w_fsm_00 : std_logic;
	signal w_fsm_01, w_fsm_01_n : std_logic;
	signal w_fsm_02, w_fsm_02_n : std_logic;
	signal w_fsm_03, w_fsm_03_n : std_logic;
	signal w_fsm_04, w_fsm_04_n : std_logic;
	signal w_fsm_05, w_fsm_05_n : std_logic;
	signal w_fsm_06 : std_logic;
	signal w_fsm_07, w_fsm_07_n : std_logic;
	signal w_fsm_08, w_fsm_08_n : std_logic;
	signal w_fsm_09 : std_logic;
	signal w_fsm_10, w_fsm_10_n : std_logic;
	signal w_fsm_11 : std_logic;
	signal w_fsm_12 : std_logic;
--	signal w_fsm_13 : std_logic;
	signal w_fsm_14 : std_logic;
	signal w_fsm_15 : std_logic;
--	signal w_fsm_16 : std_logic;
--	signal w_fsm_17 : std_logic;
--	signal w_fsm_18 : std_logic;
	signal w_fsm_19 : std_logic;
	signal w_fsm_20, w_fsm_20_n : std_logic;
	signal w_fsm_21 : std_logic;
	signal w_fsm_22 : std_logic;
--	signal w_fsm_23 : std_logic;
	signal w_fsm_24 : std_logic;
	signal w_fsm_25, w_fsm_25_n : std_logic;
	signal w_fsm_26 : std_logic;
	signal w_fsm_27, w_fsm_27_n : std_logic;
	
begin
	--| Instantiate Inverters to create inverted signals where needed
	u_myINV_S0 : myINV
	port map (
		i_A => i_state(0),
		o_Z => w_S0_n);
		
	u_myINV_S1 : myINV
	port map (
		i_A => i_state(1),
		o_Z => w_S1_n);
		
	u_myINV_S2 : myINV
	port map (
		i_A => i_state(2),
		o_Z => w_S2_n);
		
	u_myINV_S3 : myINV
	port map (
		i_A => i_state(3),
		o_Z => w_S3_n);
		
	u_myINV_01 : myINV
	port map (
		i_A => w_fsm_01,
		o_Z => w_fsm_01_n);
		
	u_myINV_02 : myINV
	port map (
		i_A => w_fsm_02,
		o_Z => w_fsm_02_n);
		
	u_myINV_03 : myINV
	port map (
		i_A => w_fsm_03,
		o_Z => w_fsm_03_n);
		
	u_myINV_04 : myINV
	port map (
		i_A => w_fsm_04,
		o_Z => w_fsm_04_n);
		
	u_myINV_05 : myINV
	port map (
		i_A => w_fsm_05,
		o_Z => w_fsm_05_n);
		
	u_myINV_07 : myINV
	port map (
		i_A => w_fsm_07,
		o_Z => w_fsm_07_n);
		
	u_myINV_08 : myINV
	port map (
		i_A => w_fsm_08,
		o_Z => w_fsm_08_n);
		
	u_myINV_10 : myINV
	port map (
		i_A => w_fsm_10,
		o_Z => w_fsm_10_n);
		
	u_myINV_20 : myINV
	port map (
		i_A => w_fsm_20,
		o_Z => w_fsm_20_n);
		
	u_myINV_25 : myINV
	port map (
		i_A => w_fsm_25,
		o_Z => w_fsm_25_n);
		
	u_myINV_27 : myINV
	port map (
		i_A => w_fsm_27,
		o_Z => w_fsm_27_n);
	
	--| Instantiate NAND gates to create intermediate control signals
	u_myNAND_00 : myNAND2
	port map (
		i_A => i_state(2),
		i_B => w_S1_n,
		o_Z => w_fsm_00);
		
	u_myNAND_01 : myNAND2
	port map (
		i_A => w_S2_n,
		i_B => i_state(1),
		o_Z => w_fsm_01);
		
	u_myNAND_02 : myNAND2
	port map (
		i_A => w_S3_n,
		i_B => w_S0_n,
		o_Z => w_fsm_02);
		
	u_myNAND_03 : myNAND2
	port map (
		i_A => w_fsm_00,
		i_B => w_fsm_01,
		o_Z => w_fsm_03);
		
	u_myNAND_04 : myNAND2
	port map (
		i_A => i_state(3),
		i_B => w_S2_n,
		o_Z => w_fsm_04);
		
	u_myNAND_05 : myNAND2
	port map (
		i_A => w_S1_n,
		i_B => w_S0_n,
		o_Z => w_fsm_05);
		
	u_myNAND_06 : myNAND2
	port map (
		i_A => w_S3_n,
		i_B => w_fsm_15,
		o_Z => w_fsm_06);
		
	u_myNAND_07 : myNAND2
	port map (
		i_A => w_S3_n,
		i_B => i_state(2),
		o_Z => w_fsm_07);
		
	u_myNAND_08 : myNAND2
	port map (
		i_A => i_state(1),
		i_B => i_state(0),
		o_Z => w_fsm_08);
		
	u_myNAND_09 : myNAND2
	port map (
		i_A => w_fsm_07_n,
		i_B => w_fsm_08_n,
		o_Z => w_fsm_09);

	u_myNAND_10 : myNAND2
	port map (
		i_A => w_S1_n,
		i_B => i_state(0),
		o_Z => w_fsm_10);
		
	u_myNAND_11 : myNAND2
	port map (
		i_A => w_fsm_07_n,
		i_B => w_fsm_10_n,
		o_Z => w_fsm_11);
		
	u_myNAND_12 : myNAND2
	port map (
		i_A => w_fsm_04_n,
		i_B => w_fsm_05_n,
		o_Z => w_fsm_12);
		
--	u_myNAND_13 : myNAND2
--	port map (
--		i_A => w_S3_n,
--		i_B => w_fsm_08_n,
--		o_Z => w_fsm_13);
		
	u_myNAND_14 : myNAND2
	port map (
		i_A => w_S2_n,
		i_B => w_S1_n,
		o_Z => w_fsm_14);
		
	u_myNAND_15 : myNAND2
	port map (
		i_A => w_S2_n,
		i_B => w_fsm_05_n,
		o_Z => w_fsm_15);
		
--	u_myNAND_16 : myNAND2
--	port map (
--		i_A => i_state(0),
--		i_B => w_fsm_14,
--		o_Z => w_fsm_16);
--		
--	u_myNAND_17 : myNAND2
--	port map (
--		i_A => i_state(3),
--		i_B => w_fsm_15,
--		o_Z => w_fsm_17);
--		
--	u_myNAND_18 : myNAND2
--	port map (
--		i_A => w_fsm_17,
--		i_B => w_fsm_16,
--		o_Z => w_fsm_18);
		
	u_myNAND_19 : myNAND2
	port map (
		i_A => w_fsm_07_n,
		i_B => w_S1_n,
		o_Z => w_fsm_19);
		
	u_myNAND_20 : myNAND2
	port map (
		i_A => w_S3_n,
		i_B => w_S2_n,
		o_Z => w_fsm_20);
		
	u_myNAND_21 : myNAND2
	port map (
		i_A => w_fsm_20_n,
		i_B => w_fsm_10_n,
		o_Z => w_fsm_21);
		
	u_myNAND_22 : myNAND2
	port map (
		i_A => w_fsm_03_n,
		i_B => w_fsm_02_n,
		o_Z => w_fsm_22);
		
--	u_myNAND_23 : myNAND2
--	port map (
--		i_A => w_fsm_04_n,
--		i_B => w_fsm_10_n,
--		o_Z => w_fsm_23);
		
	u_myNAND_24 : myNAND2
	port map (
		i_A => i_state(3),
		i_B => i_state(0),
		o_Z => w_fsm_24);
		
	u_myNAND_25 : myNAND2
	port map (
		i_A => w_fsm_24,
		i_B => w_fsm_02,
		o_Z => w_fsm_25);
		
	u_myNAND_26 : myNAND2
	port map (
		i_A => w_fsm_01_n,
		i_B => w_fsm_25_n,
		o_Z => w_fsm_26);
		
	u_myNAND_27 : myNAND2
	port map (
		i_A => w_s3_n,
		i_B => i_state(0),
		o_Z => w_fsm_27);
		
	--| Instantiate Inverters and NAND gates to generate output signals
	u_myINV_MEM_READ : myINV
	port map (
		i_A => w_fsm_22,
		o_Z => o_MEM_READ);
	
	u_myINV_MEM_WRITE : myINV
	port map (
		i_A => w_fsm_12,
		o_Z => o_MEM_WRITE);
	
	u_myNAND_MEM_ADDRESS : myNAND2
	port map (
		i_A => w_fsm_06,
		i_B => w_fsm_12,
		o_Z => o_MEM_ADDRESS_SEL);
	
	u_myINV_STORE_FROM_MEM : myINV
	port map (
		i_A => w_fsm_09,
		o_Z => o_STORE_FROM_MEM);
		
	u_myINV_PC_STORE : myINV
	port map (
		i_A => w_fsm_11,
		o_Z => o_PC_STORE);
	
	u_myINV_PC_EN : myINV
	port map (
		i_A => w_fsm_26,
		o_Z => o_PC_EN);
	
--	u_myNAND_PC_EN : myNAND2
--	port map (
--		i_A => w_fsm_13,
--		i_B => w_fsm_23,
--		o_Z => o_PC_EN);
		
	u_myNAND_DO_NOT_STORE : myNAND2
	port map (
		i_A => w_fsm_27_n,
		i_B => w_fsm_14,
		o_Z => o_DO_NOT_STORE);
		
--	u_myINV_DO_NOT_STORE : myINV
--	port map (
--		i_A => w_fsm_18,
--		o_Z => o_DO_NOT_STORE);
		
	u_myINV_BRANCH_OVERRIDE : myINV
	port map (
		i_A => w_fsm_19,
		o_Z => o_BRANCH_OVERRIDE);
		
	u_myINV_STORE_INSTRUCTION : myINV
	port map (
		i_A => w_fsm_21,
		o_Z => o_STORE_INSTRUCTION);
end a_FSM_Control_Signal_Generator;