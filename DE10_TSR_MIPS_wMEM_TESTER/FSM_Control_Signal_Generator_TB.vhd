--| FSM_Control_Signal_Generator_TB
--| Tests FSM_Control_Signal_Generator
library IEEE;
use IEEE.std_logic_1164.all;

entity FSM_Control_Signal_Generator_TB is
end FSM_Control_Signal_Generator_TB;

architecture testbench of FSM_Control_Signal_Generator_TB is
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

	-- Declare signals
	signal w_state 				: std_logic_vector(3 downto 0) := (others => '0');
	signal w_MEM_READ 			: std_logic;
	signal w_MEM_WRITE			: std_logic;
	signal w_MEM_ADDRESS_SEL	: std_logic;
	signal w_STORE_FROM_MEM		: std_logic;
	signal w_PC_STORE				: std_logic;
	signal w_PC_EN					: std_logic;
	signal w_DO_NOT_STORE		: std_logic;
	signal w_BRANCH_OVERRIDE	: std_logic;
	signal w_STORE_INSTRUCTION	: std_logic;
	

begin	
	-- Connect myNAND2
	u_FSM_Control_Signal_Generator: FSM_Control_Signal_Generator
	port map (i_state => w_state,
				 o_MEM_READ => w_MEM_READ,
				 o_MEM_WRITE => w_MEM_WRITE,
				 o_MEM_ADDRESS_SEL => w_MEM_ADDRESS_SEL,
				 o_STORE_FROM_MEM => w_STORE_FROM_MEM,
				 o_PC_STORE => w_PC_STORE,
				 o_PC_EN => w_PC_EN,
				 o_DO_NOT_STORE => w_DO_NOT_STORE,
				 o_BRANCH_OVERRIDE => w_BRANCH_OVERRIDE,
				 o_STORE_INSTRUCTION => w_STORE_INSTRUCTION);
	
	-- Process for stimulating inputs		 
	stimulus: process is
	begin
		-- State 0
		wait for 20 ns;
		-- State 1
		w_state <= B"0001";
		wait for 20 ns;
		-- State 2
		w_state <= B"0010";
		wait for 20 ns;
		-- State 3
		w_state <= B"0011";
		wait for 20 ns;
		-- State 4
		w_state <= B"0100";
		wait for 20 ns;
		-- State 5
		w_state <= B"0101";
		wait for 20 ns;
		-- State 6
		w_state <= B"0110";
		wait for 20 ns;
		-- State 7
		w_state <= B"0111";
		wait for 20 ns;
		-- State 8
		w_state <= B"1000";
		wait for 20 ns;
		-- State 9
		w_state <= B"1001";
		wait for 20 ns;
		-- State 10
		w_state <= B"1010";
		wait for 20 ns;
		-- State 11
		w_state <= B"1011";
		wait for 20 ns;
		-- State 12
		w_state <= B"1100";
		wait for 20 ns;
		-- State 13
		w_state <= B"1101";
		wait for 20 ns;
		-- State 14
		w_state <= B"1110";
		wait for 20 ns;
		-- State 15
		w_state <= B"1111";
		wait for 20 ns;
		wait;
	end process stimulus;
end testbench;