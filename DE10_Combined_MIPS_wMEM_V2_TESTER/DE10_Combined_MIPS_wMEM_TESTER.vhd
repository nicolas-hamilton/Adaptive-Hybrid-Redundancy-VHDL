--| DE10_Combined_MIPS_wMEM_TESTER.vhd
--| Test the functionality of the Combined_MIPS using the MEM_EMULATOR
--| so that the controller can "read" instructions from memory, transition
--| through the appropriate states, and send the proper control signals out
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity DE10_Combined_MIPS_wMEM_TESTER is
	port (i_clk					: in  std_logic;
			i_reset_Combined	: in  std_logic;
			i_reset_MEM			: in  std_logic;
			o_DONE				: out std_logic;
			o_UART_ERROR		: out std_logic);
end DE10_Combined_MIPS_wMEM_TESTER;

architecture a_DE10_Combined_MIPS_wMEM_TESTER of DE10_Combined_MIPS_wMEM_TESTER is
--| Define Components
	component DE10_Combined_MIPS_noMEM is
		port (i_clk					: in  std_logic;
				i_reset				: in  std_logic;
				i_MEM_OUT			: in  std_logic_vector(31 downto 0);
				i_MEM_READY			: in  std_logic;
				i_DONE				: in  std_logic;
				o_MEM_READ			: out std_logic;
				o_MEM_WRITE			: out std_logic;
				o_MEM_IN				: out std_logic_vector(31 downto 0);
				o_MEM_ADDRESS		: out std_logic_vector(31 downto 0);
				o_LEDS				: out std_logic_vector(9 downto 0));
	end component;
	
	component DE10_Combined_MIPS_noMEM_clk_en is
		port (i_clk					: in  std_logic;
				i_reset				: in  std_logic;
				i_clk_en				: in  std_logic;
				i_MEM_OUT			: in  std_logic_vector(31 downto 0);
				i_MEM_READY			: in  std_logic;
				i_DONE				: in  std_logic;
				o_MEM_READ			: out std_logic;
				o_MEM_WRITE			: out std_logic;
				o_MEM_IN				: out std_logic_vector(31 downto 0);
				o_MEM_ADDRESS		: out std_logic_vector(31 downto 0);
				o_LEDS				: out std_logic_vector(9 downto 0));
	end component;

	component DE10_Combined_MIPS_noMEM_wERR is
		generic(k_reg_sel_1	: std_logic_vector(4 downto 0) := "00111";-- Location to which the data will be stored in the GPR Bank
				  k_reg_num_1 : integer := 7; -- Location from which the data will be used to create an error - should match k_reg_sel
				  k_PC_err_1	: std_logic_vector(31 downto 0) := "00000000000000000000000001110100";-- PC address at which the error will be injected
				  k_loop_err_1	: std_logic_vector(31 downto 0) := "00000000000000000000001011001000";-- Loop index at which the error will be injected
				  k_err_bit_1_0		: integer := 5; -- Bit where the error (bit flip) will be injected
				  k_err_bit_1_1		: integer := 7;  -- Bit where the error (bit flip) will be injected
				  k_reg_sel_2	: std_logic_vector(4 downto 0) := "00111";-- Location to which the data will be stored in the GPR Bank
				  k_reg_num_2 : integer := 7; -- Location from which the data will be used to create an error - should match k_reg_sel
				  k_PC_err_2	: std_logic_vector(31 downto 0) := "00000000000000000000000001110100";-- PC address at which the error will be injected
				  k_loop_err_2	: std_logic_vector(31 downto 0) := "00000000000000000000001011001000";-- Loop index at which the error will be injected
				  k_err_bit_2_0		: integer := 5; -- Bit where the error (bit flip) will be injected
				  k_err_bit_2_1		: integer := 7); -- Bit where the error (bit flip) will be injected
		port (i_clk					: in  std_logic;
				i_reset				: in  std_logic;
				i_MEM_OUT			: in  std_logic_vector(31 downto 0);
				i_MEM_READY			: in  std_logic;
				i_DONE				: in  std_logic;
				o_MEM_READ			: out std_logic;
				o_MEM_WRITE			: out std_logic;
				o_MEM_IN				: out std_logic_vector(31 downto 0);
				o_MEM_ADDRESS		: out std_logic_vector(31 downto 0);
				o_LEDS				: out std_logic_vector(9 downto 0));
	end component;
	
	--| Memory Emulator
	component TMR_Memulator is
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
	
	component TMR_Memulator_clk_en is
		port (i_clk             : in  std_logic;
				i_reset           : in  std_logic;
				i_clk_en				: in  std_logic;
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
	
	component clock_divider is
		port (
			i_clk		: in  std_logic;
			i_reset	: in  std_logic;
			o_clk		: out std_logic);
	end component;
	
--| Define signals
	signal w_MEM_READ		: std_logic;
	signal w_MEM_WRITE	: std_logic;
	signal w_MEM_IN		: std_logic_vector(31 downto 0);
	signal w_MEM_ADDRESS	: std_logic_vector(31 downto 0);
	signal w_MEM_OUT		: std_logic_vector(31 downto 0);
	signal w_MEM_READY	: std_logic;
	signal w_DONE			: std_logic;
	
	signal w_clk_en		: std_logic;
	signal w_reset_n		: std_logic;

--| Define constants for error injection
	constant k_reg_sel_1	: std_logic_vector(4 downto 0) := "00011";
	constant k_reg_num_1	: integer := 3;
	constant k_PC_err_1		: std_logic_vector(31 downto 0) := "00000000000000000000000001110000";
	constant k_loop_err_1	: std_logic_vector(31 downto 0) := "00000000000000000000001111100111";
	constant k_err_bit_1_0	: integer := 5;
	constant k_err_bit_1_1	: integer := 7;
	constant k_reg_sel_2	: std_logic_vector(4 downto 0) := "00111";
	constant k_reg_num_2	: integer := 7;
	constant k_PC_err_2		: std_logic_vector(31 downto 0) := "01000000000000000000000111010100";
	constant k_loop_err_2	: std_logic_vector(31 downto 0) := "01000000000000000000001111100101";
	constant k_err_bit_2_0	: integer := 4;
	constant k_err_bit_2_1	: integer := 6;

	
begin
	w_reset_n <= not i_reset_MEM;
	-- Create Combined MIPS
--	u_Combined_MIPS : DE10_Combined_MIPS_noMEM
--	port map (i_clk => i_clk,
--				 i_reset => i_reset_Combined,
--				 i_MEM_OUT => w_MEM_OUT,
--				 i_MEM_READY => w_MEM_READY,
--				 i_DONE => w_DONE,
--				 o_MEM_READ => w_MEM_READ,
--				 o_MEM_WRITE => w_MEM_WRITE,
--				 o_MEM_IN => w_MEM_IN,
--				 o_MEM_ADDRESS => w_MEM_ADDRESS,
--				 o_LEDS => open);	
				 
	-- Create Combined MIPS
	u_Combined_MIPS : DE10_Combined_MIPS_noMEM_clk_en
	port map (i_clk => i_clk,
				 i_reset => i_reset_Combined,
				 i_clk_en => w_clk_en,
				 i_MEM_OUT => w_MEM_OUT,
				 i_MEM_READY => w_MEM_READY,
				 i_DONE => w_DONE,
				 o_MEM_READ => w_MEM_READ,
				 o_MEM_WRITE => w_MEM_WRITE,
				 o_MEM_IN => w_MEM_IN,
				 o_MEM_ADDRESS => w_MEM_ADDRESS,
				 o_LEDS => open);
				 
--	u_Combined_MIPS : DE10_Combined_MIPS_noMEM_wERR
--	generic map (k_reg_sel_1 => k_reg_sel_1,
--					 k_reg_num_1 => k_reg_num_1,
--					 k_PC_err_1 => k_PC_err_1,
--					 k_loop_err_1 => k_loop_err_1,
--					 k_err_bit_1_0 => k_err_bit_1_0,
--					 k_err_bit_1_1 => k_err_bit_1_1,
--					 k_reg_sel_2 => k_reg_sel_2,
--					 k_reg_num_2 => k_reg_num_2,
--					 k_PC_err_2 => k_PC_err_2,
--					 k_loop_err_2 => k_loop_err_2,
--					 k_err_bit_2_0 => k_err_bit_2_0,
--					 k_err_bit_2_1 => k_err_bit_2_1)
--	port map (i_clk => i_clk,
--				 i_reset => i_reset_Combined,
--				 i_MEM_OUT => w_MEM_OUT,
--				 i_MEM_READY => w_MEM_READY,
--				 i_DONE => w_DONE,
--				 o_MEM_READ => w_MEM_READ,
--				 o_MEM_WRITE => w_MEM_WRITE,
--				 o_MEM_IN => w_MEM_IN,
--				 o_MEM_ADDRESS => w_MEM_ADDRESS,
--				 o_LEDS => open);
				 
--	u_MEMULATOR : TMR_Memulator
--	port map (i_clk => i_clk,
--				 i_reset => i_reset_MEM,
--				 i_address => w_MEM_ADDRESS,
--				 i_read_enable => w_MEM_READ,
--				 i_write_enable => w_MEM_WRITE,
--				 i_data => w_MEM_IN,
--				 o_data => w_MEM_OUT,
--				 o_MEM_READY => w_MEM_READY,
--				 o_DONE => w_DONE,
--				 o_DONE2 =>o_DONE,
--				 o_UART_ERROR => open,
--				 o_zero => open,
--				 o_leds => open);
				 
	u_MEMULATOR : TMR_Memulator_clk_en
	port map (i_clk => i_clk,
				 i_reset => i_reset_MEM,
				 i_clk_en => w_clk_en,
				 i_address => w_MEM_ADDRESS,
				 i_read_enable => w_MEM_READ,
				 i_write_enable => w_MEM_WRITE,
				 i_data => w_MEM_IN,
				 o_data => w_MEM_OUT,
				 o_MEM_READY => w_MEM_READY,
				 o_DONE => w_DONE,
				 o_DONE2 =>o_DONE,
				 o_UART_ERROR => open,
				 o_zero => open,
				 o_leds => open);
				 
--	--| Connect Debouncer to the button input
--	u_debouncer_btn: debouncer
--		port map(i_clk=>i_clk,
--					i_reset=>w_not_reset,
--					i_bouncy=>i_BTN,
--					o_debounced=>w_DEB0);
--					
--	--| Connect the display module
--	u_display: display 
--		port map(i_clk=>i_clk,
--					i_reset=>w_not_reset,
--					i_DONE => w_DONE,
--					i_CLK_CYCLES => w_CLK_CYCLES,
--					i_next => w_DEB0,
--					o_LEDs => o_LEDs);

	u_clk_divider : clock_divider
	port map (i_clk => i_clk,
				 i_reset => w_reset_n,
				 o_clk => w_clk_en);
					
end a_DE10_Combined_MIPS_wMEM_TESTER;