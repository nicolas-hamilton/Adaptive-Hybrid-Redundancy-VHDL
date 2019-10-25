--| Instruction_Dec_Enc_TB
--| Tests Instruction_Dec_Enc
library IEEE;
use IEEE.std_logic_1164.all;

entity Instruction_Dec_Enc_TB is
end Instruction_Dec_Enc_TB;

architecture testbench of Instruction_Dec_Enc_TB is
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
				o_imm_extend		: out std_logic;
				o_FSM_CTRL			: out std_logic_vector(1 downto 0);
				o_INVALID_INSTR	: out std_logic);
	end component;

	-- Declare signals
	signal w_instruction 	: std_logic_vector(31 downto 0);
	signal w_BRANCH_OVERRIDE: std_logic :='0';
	signal w_DO_NOT_STORE	: std_logic :='0';
	signal w_PC_STORE			: std_logic :='0';
	signal w_ALU_SRC_A 		: std_logic_vector(1 downto 0);
	signal w_ALU_SRC_B		: std_logic_vector(1 downto 0);
	signal w_ALU_INV_B		: std_logic;
	signal w_COMP_SEL			: std_logic_vector(2 downto 0);
	signal w_OVER_CTRL		: std_logic_vector(1 downto 0);
	signal w_ALU_OUTPUT		: std_logic_vector(3 downto 0);
	signal w_REG_SEL			: std_logic_vector(1 downto 0);
	signal w_UNSIGNED			: std_logic;
	signal w_imm_extend		: std_logic;
	signal w_FSM_CTRL			: std_logic_vector(1 downto 0);
	signal w_INVALID_INSTR : std_logic;

begin	
	-- Connect Instruction_Dec_Enc
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
				 o_ALU_SRC_A => w_ALU_SRC_A,
				 o_ALU_SRC_B => w_ALU_SRC_B,
				 o_ALU_INV_B => w_ALU_INV_B,
				 o_COMP_SEL => w_COMP_SEL,
				 o_OVER_CTRL => w_OVER_CTRL,
				 o_ALU_OUTPUT => w_ALU_OUTPUT,
				 o_REG_SEL => w_REG_SEL,
				 o_UNSIGNED => w_UNSIGNED,
				 o_imm_extend => w_imm_extend,
				 o_FSM_CTRL => w_FSM_CTRL,
				 o_INVALID_INSTR => w_INVALID_INSTR);
	
	-- Process for stimulating inputs		 
	stimulus: process is
	begin
		-- SLL R2, R1, 5
		w_instruction <= B"00000000000000010001000101000000";
		wait for 20 ns;
		-- NOP
		w_instruction <= B"00000000000000000000000000000000";
		wait for 20 ns;
		-- SRL R3, R2, 7
		w_instruction <= B"00000000000000100001100111000010";
		wait for 20 ns;
		-- SRA R5 R4 15
		w_instruction <= B"00000000000001000010101111000011";
		wait for 20 ns;
		-- SLLV R3 R2 R1
		w_instruction <= B"00000000001000100001100000000100";
		wait for 20 ns;
		-- SRLV R7 R6 R8
		w_instruction <= B"00000001000001100011100000000110";
		wait for 20 ns;
		-- SRAV R9 R10 R11
		w_instruction <= B"00000001011010100100100000000111";
		wait for 20 ns;
		-- ADD R12 R13 R14
		w_instruction <= B"00000001101011100110000000100000";
		wait for 20 ns;
		-- ADDU R15 R16 R17
		w_instruction <= B"00000010000100010111100000100001";
		wait for 20 ns;
		-- SUB R18 R19 R20
		w_instruction <= B"00000010011101001001000000100010";
		wait for 20 ns;
		-- SUBU R21 R22 R23
		w_instruction <= B"00000010110101111010100000100011";
		wait for 20 ns;
		-- AND R24 R25 R26
		w_instruction <= B"00000011001110101100000000100100";
		wait for 20 ns;
		-- OR R27 R28 R29
		w_instruction <= B"00000011101111001101100000100101";
		wait for 20 ns;
		-- XOR R30 R31 R0
		w_instruction <= B"00000011111000001111000000100110";
		wait for 20 ns;
		-- NOR R1 R2 R3
		w_instruction <= B"00000000010000110000100000100111";
		wait for 20 ns;
		-- SLT R4 R5 R6
		w_instruction <= B"00000000101001100010000000101010";
		wait for 20 ns;
		-- SLTU R7 R8 R9
		w_instruction <= B"00000001000010010011100000101011";
		wait for 20 ns;
		-- BGEZ R10 20
		w_instruction <= B"00000101010000010000000000010100";
		wait for 20 ns;
		w_BRANCH_OVERRIDE <= '1';
		wait for 20 ns;
		-- BLTZ R12 64
		w_instruction <= B"00000101100000000000000001000000";
		w_BRANCH_OVERRIDE <= '0';
		wait for 20 ns;
		w_BRANCH_OVERRIDE <= '1';
		wait for 20 ns;
		-- BEQ R14 R15 128
		w_instruction <= B"00010001110011100000000010000000";
		w_BRANCH_OVERRIDE <= '0';
		wait for 20 ns;
		w_BRANCH_OVERRIDE <= '1';
		wait for 20 ns;
		-- BNE R16 R17 860
		w_instruction <= B"00010110000100000000001101011100";
		w_BRANCH_OVERRIDE <= '0';
		wait for 20 ns;
		w_BRANCH_OVERRIDE <= '1';
		wait for 20 ns;
		-- BLEZ R18 -240
		w_instruction <= B"00011010010000001111111100010000";
		w_BRANCH_OVERRIDE <= '0';
		wait for 20 ns;
		w_BRANCH_OVERRIDE <= '1';
		wait for 20 ns;
		-- BGTZ R20 -32
		w_instruction <= B"00011110100000001111111111100000";
		w_BRANCH_OVERRIDE <= '0';
		wait for 20 ns;
		w_BRANCH_OVERRIDE <= '1';
		wait for 20 ns;
		-- ADDI R22 R23 10053
		w_instruction <= B"00100010110101100010011101000101";
		w_BRANCH_OVERRIDE <= '0';
		wait for 20 ns;
		-- ADDIU R24 R0 32767
		w_instruction <= B"00100100010110000111111111111111";
		wait for 20 ns;
		-- SLTI R25 R26 25
		w_instruction <= B"00101011001110010000000000011001";
		wait for 20 ns;
		-- SLTIU R27 R28 47
		w_instruction <= B"00101111011110110000000000101111";
		wait for 20 ns;
		-- ANDI R29 R30 30
		w_instruction <= B"00110011101111010000000000011110";
		wait for 20 ns;
		-- ORI R31 R0 5
		w_instruction <= B"00110100011111110000000000000101";
		wait for 20 ns;
		-- XORI R1 R0 127
		w_instruction <= B"00111000001000010000000001111111";
		wait for 20 ns;
		-- LUI R2 200
		w_instruction <= B"00111100000000100000000011001000";
		wait for 20 ns;
		-- LW R4 R5 256
		w_instruction <= B"10001100100001000000000100000000";
		w_DO_NOT_STORE <= '1';
		wait for 20 ns;
		w_DO_NOT_STORE <= '0';
		wait for 20 ns;
		-- SW R6 R7 128
		w_instruction <= B"10101100110001100000000010000000";
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;