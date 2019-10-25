--| Datapath_clk_en.vhd
--| Execute the MIPS instructions as controlled by the controller.
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
--| i_RS_SEL		- Select the register from which the RS_DATA will be supplied to the ALU
--| i_RT_SEL		- Select the register from which the RT_DATA will be supplied to the ALU
--| i_imm			- Immediate/offset value
--| i_unsigned		- Determine if the comparator is comparing sigend numbers (0) or unsigned
--|					  numbers (1).
--| i_overflow		- Determine if the comparator is performing a Less Than comparison that will
--|                 or will not produce an overflow.  No overflow can occur in BLTZ instructions,
--|					  but overflow can occur in SLT, SLTU, SLTI, and SLTIU instructions.  0 - no
--|					  overflow can occur, 1 - overflow can occur
--| i_STORE_FROM_MEM - Indicates data should be stored to a GPR from memory
--|						  rather than from the ALU output.
--| i_REG_SEL		- Determine which register to which the ALU output should be stored
--| i_PC_EN			- When '1', PC=PC+4.  When '0', the next value of PC depends on i_REG_SEL
--| i_MEM_ADDRESS_SEL - Determines whether the output of the ALU or the PC value should be
--|					  used as the adddress to access memory.
--| i_MEM_OUT		- Output from memory to be stored into a register
--| i_imm_extend	- Determine if the immediate value should be 0 extended or sign extended
--|
--| OUTPUTS:
--| o_MEM_ADDRESS - Address used for accessing memory
--| o_RT_DATA		- Data to write to memory from the register indicated by i_RT_SEL
--| 
library IEEE;
use IEEE.std_logic_1164.all;
use work.my_word_array_package.all;

entity Datapath_clk_en is
	port (i_clk					: in  std_logic;
			i_reset				: in  std_logic;
			i_clk_en				: in  std_logic;
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
end Datapath_clk_en;

architecture a_Datapath_clk_en of Datapath_clk_en is
--| Define Components
	-- General Purpose Register Bank
	component GPR_Bank_clk_en is
		port (i_clk		: in  std_logic;
				i_reset	: in  std_logic;
				i_clk_en	: in  std_logic;
				i_data	: in  std_logic_vector(31 downto 0);
				i_sel		: in  std_logic_vector(4 downto 0);
				o_Q		: out word_array);
--				o_Q00		: out std_logic_vector(31 downto 0);
--				o_Q01		: out std_logic_vector(31 downto 0);
--				o_Q02		: out std_logic_vector(31 downto 0);
--				o_Q03		: out std_logic_vector(31 downto 0);
--				o_Q04		: out std_logic_vector(31 downto 0);
--				o_Q05		: out std_logic_vector(31 downto 0);
--				o_Q06		: out std_logic_vector(31 downto 0);
--				o_Q07		: out std_logic_vector(31 downto 0);
--				o_Q08		: out std_logic_vector(31 downto 0);
--				o_Q09		: out std_logic_vector(31 downto 0);
--				o_Q10		: out std_logic_vector(31 downto 0);
--				o_Q11		: out std_logic_vector(31 downto 0);
--				o_Q12		: out std_logic_vector(31 downto 0);
--				o_Q13		: out std_logic_vector(31 downto 0);
--				o_Q14		: out std_logic_vector(31 downto 0);
--				o_Q15		: out std_logic_vector(31 downto 0);
--				o_Q16		: out std_logic_vector(31 downto 0);
--				o_Q17		: out std_logic_vector(31 downto 0);
--				o_Q18		: out std_logic_vector(31 downto 0);
--				o_Q19		: out std_logic_vector(31 downto 0);
--				o_Q20		: out std_logic_vector(31 downto 0);
--				o_Q21		: out std_logic_vector(31 downto 0);
--				o_Q22		: out std_logic_vector(31 downto 0);
--				o_Q23		: out std_logic_vector(31 downto 0);
--				o_Q24		: out std_logic_vector(31 downto 0);
--				o_Q25		: out std_logic_vector(31 downto 0);
--				o_Q26		: out std_logic_vector(31 downto 0);
--				o_Q27		: out std_logic_vector(31 downto 0);
--				o_Q28		: out std_logic_vector(31 downto 0);
--				o_Q29		: out std_logic_vector(31 downto 0);
--				o_Q30		: out std_logic_vector(31 downto 0);
--				o_Q31		: out std_logic_vector(31 downto 0));
	end component;
	
	-- ALU Core
	component ALU_CORE_clk_en is
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
	end component;
	
	-- 2-input 32-bit mux
	component myMUX2_N is
		generic (m_width : integer := 32);
		port (i_0 : in  std_logic_vector(m_width-1 downto 0);
				i_1 : in  std_logic_vector(m_width-1 downto 0);
				i_S : in  std_logic;
				o_Z : out std_logic_vector(m_width-1 downto 0)
				);
	end component;
	
	-- 2-input 1-bit mux
	component myMUX2_1 is
		port (i_0 : in  std_logic;
				i_1 : in  std_logic;
				i_S : in  std_logic;
				o_Z : out std_logic
				);
	end component;
	
	-- 4-input N-bit mux
	component myMUX4_N is
		generic (m_width : integer := 32);
		port (i_0 : in  std_logic_vector(m_width-1 downto 0);
				i_1 : in  std_logic_vector(m_width-1 downto 0);
				i_2 : in  std_logic_vector(m_width-1 downto 0);
				i_3 : in  std_logic_vector(m_width-1 downto 0);
				i_S : in  std_logic_vector(1 downto 0);
				o_Z : out std_logic_vector(m_width-1 downto 0)
				);
	end component;
	
	-- 4-input 1-bit mux
	component myMUX4_1 is
		port (i_0 : in  std_logic;
				i_1 : in  std_logic;
				i_2 : in  std_logic;
				i_3 : in  std_logic;
				i_S : in  std_logic_vector(1 downto 0);
				o_Z : out std_logic
				);
	end component;
	
	-- 32-input N-bit mux
	component myMUX32_N is
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
				i_16 : in  std_logic_vector(m_width-1 downto 0);
				i_17 : in  std_logic_vector(m_width-1 downto 0);
				i_18 : in  std_logic_vector(m_width-1 downto 0);
				i_19 : in  std_logic_vector(m_width-1 downto 0);
				i_20 : in  std_logic_vector(m_width-1 downto 0);
				i_21 : in  std_logic_vector(m_width-1 downto 0);
				i_22 : in  std_logic_vector(m_width-1 downto 0);
				i_23 : in  std_logic_vector(m_width-1 downto 0);
				i_24 : in  std_logic_vector(m_width-1 downto 0);
				i_25 : in  std_logic_vector(m_width-1 downto 0);
				i_26 : in  std_logic_vector(m_width-1 downto 0);
				i_27 : in  std_logic_vector(m_width-1 downto 0);
				i_28 : in  std_logic_vector(m_width-1 downto 0);
				i_29 : in  std_logic_vector(m_width-1 downto 0);
				i_30 : in  std_logic_vector(m_width-1 downto 0);
				i_31 : in  std_logic_vector(m_width-1 downto 0);
				i_S : in  std_logic_vector(4 downto 0);
				o_Z : out std_logic_vector(m_width-1 downto 0));
	end component;
	
	-- Inverter
	component myINV is
		port (i_A : in  std_logic;
				o_Z : out std_logic
				);
	end component;
	
	-- Enabled Register
	component Enabled_Register_clk_en is
		port (i_clk		: in  std_logic;
				i_reset	: in  std_logic;
				i_clk_en			: in std_logic;
				i_data	: in  std_logic_vector(31 downto 0);
				i_en		: in  std_logic;
				o_Q		: out std_logic_vector(31 downto 0));
	end component;
	
	-- ADDER + 4
	component CARRY_SELECT_ADDER_30_SC is
		port (i_A			: in  std_logic_vector(29 downto 0);
				i_B			: in  std_logic_vector(29 downto 0);
				i_C			: in  std_logic;
				o_S			: out std_logic_vector(29 downto 0);
				o_C			: out std_logic);
	end component;

--| Define Signals
	-- GPR_BANK Signals
	signal w_GPR_DATA_IN	: std_logic_vector(31 downto 0);	-- Data in to the GPR_BANK
	signal w_GPR_SEL		: std_logic_vector(4 downto 0);	-- Select which register will to which to store data
	signal w_Q				: word_array;
--	signal w_Q00			: std_logic_vector(31 downto 0);	-- Data out from register 0
--	signal w_Q01			: std_logic_vector(31 downto 0);	-- Data out from register 1
--	signal w_Q02			: std_logic_vector(31 downto 0);
--	signal w_Q03			: std_logic_vector(31 downto 0);
--	signal w_Q04			: std_logic_vector(31 downto 0);
--	signal w_Q05			: std_logic_vector(31 downto 0);
--	signal w_Q06			: std_logic_vector(31 downto 0);
--	signal w_Q07			: std_logic_vector(31 downto 0);
--	signal w_Q08			: std_logic_vector(31 downto 0);
--	signal w_Q09			: std_logic_vector(31 downto 0);
--	signal w_Q10			: std_logic_vector(31 downto 0);
--	signal w_Q11			: std_logic_vector(31 downto 0);
--	signal w_Q12			: std_logic_vector(31 downto 0);
--	signal w_Q13			: std_logic_vector(31 downto 0);
--	signal w_Q14			: std_logic_vector(31 downto 0);
--	signal w_Q15			: std_logic_vector(31 downto 0);
--	signal w_Q16			: std_logic_vector(31 downto 0);
--	signal w_Q17			: std_logic_vector(31 downto 0);
--	signal w_Q18			: std_logic_vector(31 downto 0);
--	signal w_Q19			: std_logic_vector(31 downto 0);
--	signal w_Q20			: std_logic_vector(31 downto 0);
--	signal w_Q21			: std_logic_vector(31 downto 0);
--	signal w_Q22			: std_logic_vector(31 downto 0);
--	signal w_Q23			: std_logic_vector(31 downto 0);
--	signal w_Q24			: std_logic_vector(31 downto 0);
--	signal w_Q25			: std_logic_vector(31 downto 0);
--	signal w_Q26			: std_logic_vector(31 downto 0);
--	signal w_Q27			: std_logic_vector(31 downto 0);
--	signal w_Q28			: std_logic_vector(31 downto 0);
--	signal w_Q29			: std_logic_vector(31 downto 0);
--	signal w_Q30			: std_logic_vector(31 downto 0);	-- Data out from register 30
--	signal w_Q31			: std_logic_vector(31 downto 0);	-- Data out from register 31
	
	-- ALU Signals
	signal w_RS_DATA		: std_logic_vector(31 downto 0); -- Data from register indicated by i_RS_SEL
	signal w_RT_DATA		: std_logic_vector(31 downto 0); -- Data from register indicated by i_RT_SEL
	signal w_RD_DATA		: std_logic_vector(31 downto 0); -- Data from register indicated by i_RD_SEL
	signal w_ALU_RESULT	: std_logic_vector(31 downto 0); -- Output of ALU Core
	
	-- PC Signals
	signal w_PC				: std_logic_vector(31 downto 0); -- PC Data
	signal w_PC_4			: std_logic_vector(31 downto 0); -- PC Data + 4
	signal w_PC_IN 		: std_logic_vector(31 downto 0); -- PC Register Input
	signal w_PC_ENABLE	: std_logic; -- Enable the PC Register Signal
	signal w_PC_ENABLE0	: std_logic; -- Output of MUX to determine if the PC Register should be enabled based on the i_REG_SEL signal
	signal w_PC_EN_n		: std_logic; -- Inverted i_PC_EN
	
--| Define Constants
	constant k_zero_5 : std_logic_vector(4 downto 0) := (others => '0'); -- 5-bit zero
	constant k_zero_1 : std_logic := '0'; -- 1-bit zero
	constant k_one_1	: std_logic := '1'; -- 1 bit one
	constant k_one_30 : std_logic_vector(29 downto 0) := B"00_0000_0000_0000_0000_0000_0000_0001";
	
begin
	-- MUX to determine the input data to the GPR_BANK
	u_myMUX_GPR_DATA_IN: myMUX2_N
	generic map (m_width => 32)
	port map (i_0 => w_ALU_RESULT,
				 i_1 => i_MEM_OUT,
				 i_S => i_STORE_FROM_MEM,
				 o_Z => w_GPR_DATA_IN);
	
	-- MUX to select which register will be enabled
	u_myMUX4_GPR_SEL: myMUX4_N
	generic map (m_width => 5)
	port map (i_0 => k_zero_5,
				 i_1 => i_imm(15 downto 11),--i_RD_SEL
				 i_2 => i_RT_SEL,
				 i_3 => k_zero_5,
				 i_S => i_REG_SEL,
				 o_Z => w_GPR_SEL);
				 
	-- Connect the GPR_BANK
	u_GPR_BANK: GPR_BANK_clk_en
	port map (i_clk => i_clk,
				 i_reset => i_reset,
				 i_clk_en => i_clk_en,
				 i_data => w_GPR_DATA_IN,
				 i_sel => w_GPR_SEL,
				 o_Q => w_Q);
--				 o_Q00 => w_Q00,
--				 o_Q01 => w_Q01,
--				 o_Q02 => w_Q02,
--				 o_Q03 => w_Q03,
--				 o_Q04 => w_Q04,
--				 o_Q05 => w_Q05,
--				 o_Q06 => w_Q06,
--				 o_Q07 => w_Q07,
--				 o_Q08 => w_Q08,
--				 o_Q09 => w_Q09,
--				 o_Q10 => w_Q10,
--				 o_Q11 => w_Q11,
--				 o_Q12 => w_Q12,
--				 o_Q13 => w_Q13,
--				 o_Q14 => w_Q14,
--				 o_Q15 => w_Q15,
--				 o_Q16 => w_Q16,
--				 o_Q17 => w_Q17,
--				 o_Q18 => w_Q18,
--				 o_Q19 => w_Q19,
--				 o_Q20 => w_Q20,
--				 o_Q21 => w_Q21,
--				 o_Q22 => w_Q22,
--				 o_Q23 => w_Q23,
--				 o_Q24 => w_Q24,
--				 o_Q25 => w_Q25,
--				 o_Q26 => w_Q26,
--				 o_Q27 => w_Q27,
--				 o_Q28 => w_Q28,
--				 o_Q29 => w_Q29,
--				 o_Q30 => w_Q30,
--				 o_Q31 => w_Q31);
		
	-- Connect the MUX to select the RS Data from the GPR Bank
	u_myMUX32_N_RS: myMUX32_N
	generic map (m_width => 32)
	port map (i_0 => w_Q(0),
				 i_1 => w_Q(1),
				 i_2 => w_Q(2),
				 i_3 => w_Q(3),
				 i_4 => w_Q(4),
				 i_5 => w_Q(5),
				 i_6 => w_Q(6),
				 i_7 => w_Q(7),
				 i_8 => w_Q(8),
				 i_9 => w_Q(9),
				 i_10 => w_Q(10),
				 i_11 => w_Q(11),
				 i_12 => w_Q(12),
				 i_13 => w_Q(13),
				 i_14 => w_Q(14),
				 i_15 => w_Q(15),
				 i_16 => w_Q(16),
				 i_17 => w_Q(17),
				 i_18 => w_Q(18),
				 i_19 => w_Q(19),
				 i_20 => w_Q(20),
				 i_21 => w_Q(21),
				 i_22 => w_Q(22),
				 i_23 => w_Q(23),
				 i_24 => w_Q(24),
				 i_25 => w_Q(25),
				 i_26 => w_Q(26),
				 i_27 => w_Q(27),
				 i_28 => w_Q(28),
				 i_29 => w_Q(29),
				 i_30 => w_Q(30),
				 i_31 => w_Q(31),
				 i_S => i_RS_SEL,
				 o_Z => w_RS_DATA);
				 
	-- Connect the MUX to select the RT Data from the GPR Bank
	u_myMUX32_N_RT: myMUX32_N
	generic map (m_width => 32)
	port map (i_0 => w_Q(0),
				 i_1 => w_Q(1),
				 i_2 => w_Q(2),
				 i_3 => w_Q(3),
				 i_4 => w_Q(4),
				 i_5 => w_Q(5),
				 i_6 => w_Q(6),
				 i_7 => w_Q(7),
				 i_8 => w_Q(8),
				 i_9 => w_Q(9),
				 i_10 => w_Q(10),
				 i_11 => w_Q(11),
				 i_12 => w_Q(12),
				 i_13 => w_Q(13),
				 i_14 => w_Q(14),
				 i_15 => w_Q(15),
				 i_16 => w_Q(16),
				 i_17 => w_Q(17),
				 i_18 => w_Q(18),
				 i_19 => w_Q(19),
				 i_20 => w_Q(20),
				 i_21 => w_Q(21),
				 i_22 => w_Q(22),
				 i_23 => w_Q(23),
				 i_24 => w_Q(24),
				 i_25 => w_Q(25),
				 i_26 => w_Q(26),
				 i_27 => w_Q(27),
				 i_28 => w_Q(28),
				 i_29 => w_Q(29),
				 i_30 => w_Q(30),
				 i_31 => w_Q(31),
				 i_S => i_RT_SEL,
				 o_Z => w_RT_DATA);
				 
	-- Connect the MUX to select the RD Data from the GPR Bank
	u_myMUX32_N_RD: myMUX32_N
	generic map (m_width => 32)
	port map (i_0 => w_Q(0),
				 i_1 => w_Q(1),
				 i_2 => w_Q(2),
				 i_3 => w_Q(3),
				 i_4 => w_Q(4),
				 i_5 => w_Q(5),
				 i_6 => w_Q(6),
				 i_7 => w_Q(7),
				 i_8 => w_Q(8),
				 i_9 => w_Q(9),
				 i_10 => w_Q(10),
				 i_11 => w_Q(11),
				 i_12 => w_Q(12),
				 i_13 => w_Q(13),
				 i_14 => w_Q(14),
				 i_15 => w_Q(15),
				 i_16 => w_Q(16),
				 i_17 => w_Q(17),
				 i_18 => w_Q(18),
				 i_19 => w_Q(19),
				 i_20 => w_Q(20),
				 i_21 => w_Q(21),
				 i_22 => w_Q(22),
				 i_23 => w_Q(23),
				 i_24 => w_Q(24),
				 i_25 => w_Q(25),
				 i_26 => w_Q(26),
				 i_27 => w_Q(27),
				 i_28 => w_Q(28),
				 i_29 => w_Q(29),
				 i_30 => w_Q(30),
				 i_31 => w_Q(31),
				 i_S => i_imm(15 downto 11), --i_RD_SEL
				 o_Z => w_RD_DATA);
				 
	-- Connect the ALU_CORE
	u_ALU_CORE: ALU_CORE_clk_en
	port map(i_clk	=> i_clk,
				i_reset => i_reset,
				i_clk_en => i_clk_en,
				i_ALU_SRC_A => i_ALU_SRC_A,
				i_ALU_SRC_B => i_ALU_SRC_B,
				i_ALU_INV_B => i_ALU_INV_B,
				i_COMP_SEL => i_COMP_SEL,
				i_OVER_CTRL => i_OVER_CTRL,
				i_ALU_OUTPUT => i_ALU_OUTPUT,
				i_RS_DATA => w_RS_DATA,
				i_RT_DATA => w_RT_DATA,
				i_RD_DATA => w_RD_DATA,
				i_PC => w_PC,
				i_imm => i_imm,
				i_UNSIGNED => i_UNSIGNED,
				i_overflow => i_overflow,
				i_imm_extend => i_imm_extend,
				o_ALU_RESULT => w_ALU_RESULT);
				
	-- Connect the MUX to determine the input data to the PC Register
	u_myMUX_PC_IN: myMUX2_N
	generic map (m_width => 32)
	port map (i_0 => w_PC_4,
				 i_1 => w_ALU_RESULT,
				 i_S => w_PC_EN_n,
				 o_Z => w_PC_IN);
				 
	-- Connect the MUX to determine whether the PC register should be enabled based on i_REG_SEL
	u_myMUX4_PC_ENABLE0: myMUX4_1
	port map (i_0 => k_zero_1,
				 i_1 => k_zero_1,
				 i_2 => k_zero_1,
				 i_3 => k_one_1,
				 i_S => i_REG_SEL,
				 o_Z => w_PC_ENABLE0);
	
	-- Connect the MUX to determine whether the PC register should be enabled based on i_PC_EN or i_REG_SEL
	u_myMUX2_PC_ENABLE: myMUX2_1
	port map (i_0 => w_PC_ENABLE0,
				 i_1 => k_one_1,
				 i_S => i_PC_EN,
				 o_Z => w_PC_ENABLE);
	
	-- Connect the inverter to invert i_PC_EN
	u_myINV: myINV
	port map (i_A => i_PC_EN,
				 o_Z => w_PC_EN_n);
	
	-- Connect the PC Register
	u_Enabled_Register: Enabled_Register_clk_en
	port map (i_clk => i_clk,
				 i_reset => i_reset,
				 i_clk_en => i_clk_en,
				 i_data => w_PC_IN,
				 i_en => w_PC_ENABLE,
				 o_Q => w_PC);
				 
	-- Connect the adder to calculate PC+4
	u_CARRY_SELECT_ADDER_30_SC: CARRY_SELECT_ADDER_30_SC
	port map (i_A => w_PC(31 downto 2),
				 i_B => k_one_30,
				 i_C => k_zero_1,
				 o_S => w_PC_4(31 downto 2),
				 o_C => open);
	w_PC_4(1 downto 0) <= w_PC(1 downto 0);
	
	-- Connect the MUX to determine o_MEM_ADDRESS
	u_myMUX_MEM_ADDRESS: myMUX2_N
	generic map (m_width => 32)
	port map (i_0 => w_PC,
				 i_1 => w_ALU_RESULT,
				 i_S => i_MEM_ADDRESS_SEL,
				 o_Z => o_MEM_ADDRESS);
				 
	-- Connect remaining output
	o_RT_DATA <= w_RT_DATA;
end a_Datapath_clk_en;