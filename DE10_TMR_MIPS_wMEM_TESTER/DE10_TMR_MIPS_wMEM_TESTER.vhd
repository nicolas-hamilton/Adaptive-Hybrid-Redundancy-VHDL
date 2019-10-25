--| DE10_TMR_MIPS_wMEM_TESTER.vhd
--| Test the functionality of the Basic_MIPS using the MEM_EMULATOR
--| so that the controller can "read" instructions from memory, transition
--| through the appropriate states, and send the proper control signals out
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity DE10_TMR_MIPS_wMEM_TESTER is
	port (i_clk					: in  std_logic;
			i_reset_TMR			: in  std_logic;
			i_reset_MEM			: in  std_logic;
			o_DONE				: out std_logic;
			o_UART_ERROR		: out std_logic;
			o_LEDS				: out std_logic_vector(9 downto 0));
--			o_HEX0				: out std_logic_vector(6 downto 0);
--			o_HEX1				: out std_logic_vector(6 downto 0);
--			o_HEX2				: out std_logic_vector(6 downto 0);
--			o_HEX3				: out std_logic_vector(6 downto 0);
--			o_HEX4				: out std_logic_vector(6 downto 0));
end DE10_TMR_MIPS_wMEM_TESTER;

architecture a_DE10_TMR_MIPS_wMEM_TESTER of DE10_TMR_MIPS_wMEM_TESTER is
--| Define Components
--	component DE10_TMR_MIPS_noMEM is
--		port (i_clk					: in  std_logic;
--				i_reset				: in  std_logic;
--				i_MEM_OUT			: in  std_logic_vector(31 downto 0);
--				i_MEM_READY			: in  std_logic;
--				i_DONE				: in  std_logic;
--				o_MEM_READ			: out std_logic;
--				o_MEM_WRITE			: out std_logic;
--				o_MEM_IN				: out std_logic_vector(31 downto 0);
--				o_MEM_ADDRESS		: out std_logic_vector(31 downto 0);
--				o_LEDS				: out std_logic_vector(9 downto 0));
----				o_HEX0				: out std_logic_vector(6 downto 0);
----				o_HEX1				: out std_logic_vector(6 downto 0);
----				o_HEX2				: out std_logic_vector(6 downto 0);
----				o_HEX3				: out std_logic_vector(6 downto 0);
----				o_HEX4				: out std_logic_vector(6 downto 0));
--	end component;
	
	component DE10_TMR_MIPS_noMEM_w1ERR is
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
	
--| Define signals
	signal w_MEM_READ		: std_logic;
	signal w_MEM_WRITE	: std_logic;
	signal w_MEM_IN		: std_logic_vector(31 downto 0);
	signal w_MEM_ADDRESS	: std_logic_vector(31 downto 0);
	signal w_MEM_OUT		: std_logic_vector(31 downto 0);
	signal w_MEM_READY	: std_logic;
	signal w_DONE			: std_logic;

	
begin
	-- Create TMR MIPS
--	u_TMR_MIPS : DE10_TMR_MIPS_noMEM
--	port map (i_clk => i_clk,
--				 i_reset => i_reset_TMR,
--				 i_MEM_OUT => w_MEM_OUT,
--				 i_MEM_READY => w_MEM_READY,
--				 i_DONE => w_DONE,
--				 o_MEM_READ => w_MEM_READ,
--				 o_MEM_WRITE => w_MEM_WRITE,
--				 o_MEM_IN => w_MEM_IN,
--				 o_MEM_ADDRESS => w_MEM_ADDRESS,
--				 o_LEDS => open);--o_LEDS);
----				 o_HEX0 => o_HEX0,
----				 o_HEX1 => o_HEX1,
----				 o_HEX2 => o_HEX2,
----				 o_HEX3 => o_HEX3,
----				 o_HEX4 => o_HEX4);
				 
	-- Create TMR MIPS
	u_TMR_MIPS : DE10_TMR_MIPS_noMEM_w1ERR
	port map (i_clk => i_clk,
				 i_reset => i_reset_TMR,
				 i_MEM_OUT => w_MEM_OUT,
				 i_MEM_READY => w_MEM_READY,
				 i_DONE => w_DONE,
				 o_MEM_READ => w_MEM_READ,
				 o_MEM_WRITE => w_MEM_WRITE,
				 o_MEM_IN => w_MEM_IN,
				 o_MEM_ADDRESS => w_MEM_ADDRESS,
				 o_LEDS => open);
				 
	u_MEMULATOR : TMR_Memulator
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
					
end a_DE10_TMR_MIPS_wMEM_TESTER;