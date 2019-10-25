--| DE10_TSR_MIPS_noMEM.vhd - Same as Basic_MIPS - only a name change
--| Connect the Controller and Datapath of a "MIPS Like" architecture that implements the following
--| 33 commands.  See MIPS Volume II, Revision 0.95 March 12, 2001 by MIPS Technologies Inc. for the
--| function of each of these instructions.  One exception is that the branching instructions do not
--| implement the branch delay slot and instead, the 18-bit signed offset is added to the current PC
--| value to form a PC relative effective target address.
--|	SLL	- Shift Word Left Logical
--|	NOP	- No Operation
--|	SRL	- Shfit Word Right Logical
--|	SRA	- Shift Word Right Arithmetic
--|	SLLV	- Shift Word Left Logical Variable
--|	SRLV	- Shfit Word Right Logical Variable
--|	SRAV	- Shift Word Right Arithmetic Variable
--|	ADD	- Add Word
--|	ADDU	- Add Unsigned Word
--|	SUB	- Subtract Word
--|	SUBU	- Subtract Unsigned Word
--|	AND	- Bitwise And
--|	OR		- Bitwise Or
--|	XOR	- Bitwise Exclusive Or
--|	NOR	- Bitwise Nor
--|	SLT	- Set Less Than
--|	SLTU	- Set Less Than Unsigned	
--|	BGEZ	- Branch on Greater Than or Equal to Zero
--|	BLTZ	- Branch on Less Than Zero
--|	BEQ	- Branch on Equal
--|	BNE	- Branch on Not Equal
--|	BLEZ	- Branch on Less Than or Equal to Zero
--|	BGTZ	- Branch on Greater Than Zero
--|	ADDI	- Add Immediate Word
--|	ADDIU	- Add Immediate Unsigned Word
--|	SLTI	- Set on Less Than Immediate
--|	SLTIU	- Set on Less Than Immediate Unsigned
--|	ANDI	- Bitwise And Immediate
--|	ORI	- Bitwise Or Immediate
--|	XORI	- Bitwise Exclusive Or Immediate
--|	LUI	- Load Upper Immediate
--|	LW		- Load Word
--|	SW		- Store Word
--|
--| INPUTS:
--| i_clk		- Clock input
--| i_reset		- Reset input
--| i_MEM_OUT	- Output from memory to be stored into the instruction register
--|
--| OUTPUTS:
--| o_MEM_READ				- Read from memory enable signal
--| o_MEM_WRITE			- Write to memory enable signal
--| o_MEM_IN				- Output from DE10_TSR_MIPS_noMEM to be stored in memory
--| o_MEM_ADDRESS			- Address used to access memory
library IEEE;
use IEEE.std_logic_1164.all;

entity DE10_TSR_MIPS_noMEM is
	port (i_clk					: in  std_logic;
			i_reset				: in  std_logic;
			i_MEM_OUT			: in  std_logic_vector(31 downto 0);
			i_MEM_READY			: in  std_logic;
			i_DONE				: in  std_logic;
			o_MEM_READ			: out std_logic;
			o_MEM_WRITE			: out std_logic;
			o_MEM_IN				: out std_logic_vector(31 downto 0);
			o_MEM_ADDRESS		: out std_logic_vector(31 downto 0));
--			o_LEDS				: out std_logic_vector(9 downto 0));
end DE10_TSR_MIPS_noMEM;

architecture a_DE10_TSR_MIPS_noMEM of DE10_TSR_MIPS_noMEM is
--| Define Components
	--| Controller Finite State Machine
	component Controller_FSM is
		port (i_clk					: in  std_logic;
				i_reset				: in  std_logic;
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
				o_immediate			: out std_logic_vector(15 downto 0));
	end component;
	-- | Datapath
	component Datapath is
		port (i_clk					: in  std_logic;
				i_reset				: in  std_logic;
				i_ALU_SRC_A			: in  std_logic_vector(1 downto 0);
				i_ALU_SRC_B			: in  std_logic_vector(1 downto 0);
				i_ALU_INV_B 		: in  std_logic;
				i_COMP_SEL			: in  std_logic_vector(2 downto 0);
				i_OVER_CTRL 		: in  std_logic_vector(1 downto 0);
				i_ALU_OUTPUT		: in  std_logic_vector(3 downto 0);
				i_RS_SEL				: in  std_logic_vector(4 downto 0);
				i_RT_SEL				: in  std_logic_vector(4 downto 0);
				i_imm					: in  std_logic_vector(15 downto 0);
				i_UNSIGNED			: in  std_logic;
				i_overflow			: in  std_logic;
				i_imm_extend		: in  std_logic;
				i_STORE_FROM_MEM	: in  std_logic;
				i_REG_SEL			: in  std_logic_vector(1 downto 0);
				i_PC_EN				: in  std_logic;
				i_MEM_ADDRESS_SEL	: in  std_logic;
				i_MEM_OUT			: in  std_logic_vector(31 downto 0);
				o_MEM_ADDRESS		: out std_logic_vector(31 downto 0);
				o_RT_DATA			: out std_logic_vector(31 downto 0));
	end component;

--| Define Control Signals from Controller_FSM to Datapath
	signal w_reset_n				: std_logic;
	signal w_reset					: std_logic;
	signal w_MEM_READ			: std_logic;
	signal w_MEM_WRITE		: std_logic;
	signal w_ALU_SRC_A			: std_logic_vector(1 downto 0);
	signal w_ALU_SRC_B			: std_logic_vector(1 downto 0);
	signal w_ALU_INV_B 			: std_logic;
	signal w_COMP_SEL				: std_logic_vector(2 downto 0);
	signal w_OVER_CTRL 			: std_logic_vector(1 downto 0);
	signal w_ALU_OUTPUT			: std_logic_vector(3 downto 0);
	signal w_RS_SEL				: std_logic_vector(4 downto 0);
	signal w_RT_SEL				: std_logic_vector(4 downto 0);
	signal w_immediate			: std_logic_vector(15 downto 0);
	signal w_UNSIGNED				: std_logic;
	signal w_overflow				: std_logic;
	signal w_imm_extend			: std_logic;
	signal w_STORE_FROM_MEM		: std_logic;
	signal w_REG_SEL				: std_logic_vector(1 downto 0);
	signal w_PC_EN					: std_logic;
	signal w_MEM_ADDRESS_SEL	: std_logic;
	
	constant k_zero10 : std_logic_vector(9 downto 0) := (others => '0');
	
begin
	w_reset_n <= not i_reset;
	w_reset <= w_reset_n or i_DONE;
--	o_leds(9 downto 6) <= (others => '0');
--	o_leds(5) <= i_reset;
--	o_leds(4) <= w_reset_n;
--	o_leds(3) <= i_DONE;
--	o_leds(2) <= i_MEM_READY;
--	o_leds(1) <= w_MEM_READ;
--	o_leds(0) <= w_MEM_WRITE;
--	o_MEM_READ <= w_MEM_READ;
--	o_MEM_WRITE <= w_MEM_WRITE;
	
	--| Connect the Controller
	u_Controller_FSM : Controller_FSM
	port map (i_clk => i_clk,
				 i_reset => w_reset,
				 i_MEM_OUT => i_MEM_OUT,
				 i_MEM_READY => i_MEM_READY,
				 o_MEM_READ => o_MEM_READ,--w_MEM_READ,
				 o_MEM_WRITE => o_MEM_WRITE,--w_MEM_WRITE,
				 o_MEM_ADDRESS_SEL => w_MEM_ADDRESS_SEL,
				 o_STORE_FROM_MEM => w_STORE_FROM_MEM,
				 o_PC_EN => w_PC_EN,
				 o_ALU_SRC_A => w_ALU_SRC_A,
				 o_ALU_SRC_B => w_ALU_SRC_B,
				 o_ALU_INV_B => w_ALU_INV_B,
				 o_COMP_SEL => w_COMP_SEL,
				 o_OVER_CTRL => w_OVER_CTRL,
				 o_ALU_OUTPUT => w_ALU_OUTPUT,
				 o_REG_SEL => w_REG_SEL,
				 o_UNSIGNED => w_UNSIGNED,
				 o_overflow => w_overflow,
				 o_imm_extend => w_imm_extend,
				 o_RS_SEL => w_RS_SEL,
				 o_RT_SEL => w_RT_SEL,
				 o_immediate => w_immediate);
				 
	--| Connect the Datapath
	u_Datapath : Datapath
	port map (i_clk => i_clk,
				 i_reset => w_reset,
				 i_ALU_SRC_A => w_ALU_SRC_A,
				 i_ALU_SRC_B => w_ALU_SRC_B,
				 i_ALU_INV_B => w_ALU_INV_B,
				 i_COMP_SEL => w_COMP_SEL,
				 i_OVER_CTRL => w_OVER_CTRL,
				 i_ALU_OUTPUT => w_ALU_OUTPUT,
				 i_RS_SEL => w_RS_SEL,
				 i_RT_SEL => w_RT_SEL,
				 i_imm => w_immediate,
				 i_UNSIGNED => w_UNSIGNED,
				 i_overflow => w_overflow,
				 i_imm_extend => w_imm_extend,
				 i_STORE_FROM_MEM => w_STORE_FROM_MEM,
				 i_REG_SEL => w_REG_SEL,
				 i_PC_EN => w_PC_EN,
				 i_MEM_ADDRESS_SEL => w_MEM_ADDRESS_SEL,
				 i_MEM_OUT => i_MEM_OUT,
				 o_MEM_ADDRESS => o_MEM_ADDRESS,
				 o_RT_DATA => o_MEM_IN);
end a_DE10_TSR_MIPS_noMEM;