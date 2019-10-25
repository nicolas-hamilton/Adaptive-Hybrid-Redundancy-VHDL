--| Controller_FSM_TB.vhd
--| Test the functionality of the Controller_FSM using the MEM_EMULATOR
--| so that the controller can "read" instructions from memory, transition
--| through the appropriate states, and send the proper control signals out
library IEEE;
use IEEE.std_logic_1164.all;

entity Controller_FSM_TB is
end Controller_FSM_TB;

architecture testbench of Controller_FSM_TB is
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
				o_imm_extend		: out std_logic;
				o_RS_SEL				: out std_logic_vector(4 downto 0);
				o_RT_SEL				: out std_logic_vector(4 downto 0);
				o_immediate			: out std_logic_vector(15 downto 0));
	end component;
	
	--| Memory Emulator
	component MEM_EMULATOR is
		port (i_clk				: in  std_logic;
				i_reset			: in  std_logic;
				i_address		: in  std_logic_vector(31 downto 0);
				i_read_enable	: in  std_logic;
				i_write_enable	: in  std_logic;
				i_data			: in  std_logic_vector(31 downto 0);
				o_data			: out std_logic_vector(31 downto 0);
				o_written_data	: out std_logic_vector(31 downto 0);
				o_MEM_READY		: out std_logic);
	end component;
	
--| Define signals
	signal c_clk					: std_logic := '0';
	signal w_reset					: std_logic := '1';
	signal w_MEM_OUT				: std_logic_vector(31 downto 0);
	signal w_MEM_READY			: std_logic;
	signal w_MEM_IN				: std_logic_vector(31 downto 0) := B"11110000111100001111000011110000";
	signal w_MEM_READ				: std_logic;
	signal w_MEM_WRITE			: std_logic;
	signal w_MEM_ADDRESS_SEL	: std_logic;
	signal w_STORE_FROM_MEM		: std_logic;
	signal w_PC_EN					: std_logic;
	signal w_ALU_SRC_A			: std_logic_vector(1 downto 0);
	signal w_ALU_SRC_B			: std_logic_vector(1 downto 0);
	signal w_ALU_INV_B 			: std_logic;
	signal w_COMP_SEL				: std_logic_vector(2 downto 0);
	signal w_OVER_CTRL 			: std_logic_vector(1 downto 0);
	signal w_ALU_OUTPUT			: std_logic_vector(3 downto 0);
	signal w_REG_SEL				: std_logic_vector(1 downto 0);
	signal w_UNSIGNED				: std_logic;
	signal w_imm_extend			: std_logic;
	signal w_RS_SEL				: std_logic_vector(4 downto 0);
	signal w_RT_SEL				: std_logic_vector(4 downto 0);
	signal w_immediate			: std_logic_vector(15 downto 0);
	signal w_written_data		: std_logic_vector(31 downto 0);
	signal w_address				: std_logic_vector(31 downto 0) := (others => '0');
	
begin
	u_Controller_FSM : Controller_FSM
	port map (i_clk => c_clk,
				 i_reset => w_reset,
				 i_MEM_OUT => w_MEM_OUT,
				 i_MEM_READY => w_MEM_READY,
				 o_MEM_READ => w_MEM_READ,
				 o_MEM_WRITE => w_MEM_WRITE,
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
				 o_imm_extend => w_imm_extend,
				 o_RS_SEL => w_RS_SEL,
				 o_RT_SEL => w_RT_SEL,
				 o_immediate => w_immediate);
				 
	u_MEM_EMULATOR : MEM_EMULATOR
	port map (i_clk => c_clk,
				 i_reset => w_reset,
				 i_address => w_address,
				 i_read_enable => w_MEM_READ,
				 i_write_enable => w_MEM_WRITE,
				 i_data => w_MEM_IN,
				 o_data => w_MEM_OUT,
				 o_written_data => w_written_data,
				 o_MEM_READY => w_MEM_READY);
	
	--| Generate the stimulus
	stimulus : process is
   begin
		wait for 100 ns;
		w_reset <= '0';
   end process;
				 
	--| Generate the clock signal
	clock_gen: process is
	begin
		c_clk <= '1' after 10 ns, '0' after 20 ns;
		wait for 20 ns;
	end process clock_gen;
end testbench;