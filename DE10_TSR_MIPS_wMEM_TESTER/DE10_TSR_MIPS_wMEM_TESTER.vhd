--| DE10_TSR_MIPS_wMEM_TESTER.vhd
--| Test the functionality of the Basic_MIPS using the MEM_EMULATOR
--| so that the controller can "read" instructions from memory, transition
--| through the appropriate states, and send the proper control signals out
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity DE10_TSR_MIPS_wMEM_TESTER is
	port (i_clk					: in  std_logic;
			i_reset_TSR			: in  std_logic;
			i_reset_MEM			: in  std_logic;
			o_DONE				: out std_logic;
			o_UART_ERROR		: out std_logic);
end DE10_TSR_MIPS_wMEM_TESTER;

architecture a_DE10_TSR_MIPS_wMEM_TESTER of DE10_TSR_MIPS_wMEM_TESTER is
--| Define Components
--	component DE10_TSR_MIPS_noMEM_wERR is
--		generic(k_reg_sel	: std_logic_vector(4 downto 0) := "00011";-- Location to which the data will be stored in the GPR Bank
--				  k_reg_num : integer := 3; -- Location from which the data will be used to create an error - should match k_reg_sel
--				  k_PC_err	: std_logic_vector(31 downto 0) := "00000000000000000000000011010000";-- PC address at which the error will be injected
--				  k_loop_err	: std_logic_vector(31 downto 0) := "00000000000000000000000000000011";-- Loop index at which the error will be injected
--				  k_err_bit		: integer := 5); -- Bit where the error (bit flip) will be injected
--		port (i_clk					: in  std_logic;
--				i_reset				: in  std_logic;
--				i_DONE				: in  std_logic;
--				i_MEM_OUT			: in  std_logic_vector(31 downto 0);
--				i_MEM_READY			: in  std_logic;
--				i_Err_Override		: in  std_logic;
--				o_MEM_READ			: out std_logic;
--				o_MEM_WRITE			: out std_logic;
--				o_MEM_IN				: out std_logic_vector(31 downto 0);
--				o_MEM_ADDRESS		: out std_logic_vector(31 downto 0));
--	end component;
	component DE10_TSR_MIPS_noMEM is
		port (i_clk					: in  std_logic;
				i_reset				: in  std_logic;
				i_MEM_OUT			: in  std_logic_vector(31 downto 0);
				i_MEM_READY			: in  std_logic;
				i_DONE				: in  std_logic;
				o_MEM_READ			: out std_logic;
				o_MEM_WRITE			: out std_logic;
				o_MEM_IN				: out std_logic_vector(31 downto 0);
				o_MEM_ADDRESS		: out std_logic_vector(31 downto 0));
	end component;
	
	--| Memory Emulator
	component TSR_Memulator is
		port (i_clk             : in  std_logic;
				i_reset           : in  std_logic;
				i_address         : in  std_logic_vector(31 downto 0);
				i_read_enable     : in  std_logic;
				i_write_enable    : in  std_logic;
				i_data            : in  std_logic_vector(31 downto 0);
				o_data            : out std_logic_vector(31 downto 0);
				o_MEM_READY       : out std_logic;
				o_DONE            : out std_logic;
				o_DONE2           : out std_logic;
				o_UART_ERROR		: out std_logic;
				o_zero				: out std_logic;
				o_leds				: out std_logic_vector(9 downto 0));
	end component;
	
	--| Define signals
	signal w_MEM_READ		: std_logic;
	signal w_MEM_WRITE	: std_logic;
	signal w_MEM_IN		: std_logic_vector(31 downto 0);
	signal w_MEM_ADDRESS	: std_logic_vector(31 downto 0);
	signal w_MEM_OUT		: std_logic_vector(31 downto 0);
	signal w_MEM_READY	: std_logic;
	signal w_DONE			: std_logic;
	--| Define Constants
	constant k_reg_sel	: std_logic_vector(4 downto 0) := "11111";
	constant k_reg_num	: integer := 31;
	constant k_PC_err		: std_logic_vector(31 downto 0) := "00000000000000000000000101010100";
	constant k_loop_err	: std_logic_vector(31 downto 0) := "00000000000000000000000111110100";
	constant k_err_bit0	: integer := 5;
	constant k_zero		: std_logic := '0';
	
begin
	-- Create TSR MIPS
--	u_TSR_MIPS : DE10_TSR_MIPS_noMEM_wERR
--	generic map (k_reg_sel => k_reg_sel,
--					 k_reg_num => k_reg_num,
--					 k_PC_err => k_PC_err,
--					 k_loop_err => k_loop_err,
--					 k_err_bit => k_err_bit0)
--	port map (i_clk => i_clk,
--				 i_reset => i_reset_TSR,
--				 i_DONE => w_DONE,
--				 i_MEM_OUT => w_MEM_OUT,
--				 i_MEM_READY => w_MEM_READY,
--				 i_Err_Override => k_zero,
--				 o_MEM_READ => w_MEM_READ,
--				 o_MEM_WRITE => w_MEM_WRITE,
--				 o_MEM_IN => w_MEM_IN,
--				 o_MEM_ADDRESS => w_MEM_ADDRESS);
	u_TSR_MIPS : DE10_TSR_MIPS_noMEM
	port map (i_clk => i_clk,
				 i_reset => i_reset_TSR,
				 i_MEM_OUT => w_MEM_OUT,
				 i_MEM_READY => w_MEM_READY,
				 i_DONE => w_DONE,
				 o_MEM_READ => w_MEM_READ,
				 o_MEM_WRITE => w_MEM_WRITE,
				 o_MEM_IN => w_MEM_IN,
				 o_MEM_ADDRESS => w_MEM_ADDRESS);
				 
	u_MEMULATOR : TSR_Memulator
	port map (i_clk => i_clk,
				 i_reset => i_reset_MEM,
				 i_address => w_MEM_ADDRESS,
				 i_read_enable => w_MEM_READ,
				 i_write_enable => w_MEM_WRITE,
				 i_data => w_MEM_IN,
				 o_data => w_MEM_OUT,
				 o_MEM_READY => w_MEM_READY,
				 o_DONE => w_DONE,
				 o_DONE2 =>o_DONE,
				 o_UART_ERROR => open,--o_UART_ERROR,
				 o_zero => open,
				 o_LEDs => open);
					
end a_DE10_TSR_MIPS_wMEM_TESTER;