--| TMR_Memulator_old.vhd
--| Emulate the behaviour of a 32-bit addressable memory.  Uses incoming
--| address to determine which instruction to return next.  For write
--| operations, a single internal register will retain the value of i_data
--| until it is overwritten by the next write operation.  Write operations
--| occur when i_write_enable is '1'.
--|
--| INPUTS:
--| i_clk            - clock input
--| i_reset          - reset input
--| i_address	    - address
--| i_read_enable    - enable read
--| i_write_enable   - enable write
--| i_data           - input data
--| i_ack            - acknowlegement that error buffer has received an error
--|
--| OUTPUTS:
--| o_data           - output data
--| o_MEM_READY      - signal is 1 when read/write operation is complete
--| o_DONE           - signal is 1 when the instruction set is completed
--| o_DONE2          - Copy of o_DONE that is sent to a different output pin
--| o_error_detected - signal is 1 when an error has been detected
--| o_error          - indicates the type and location of the error
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity TMR_Memulator_old is
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
end TMR_Memulator_old;

architecture a_TMR_Memulator_old of TMR_Memulator_old is
--| Define Components
component Test80_Reg_TMR is
   port (i_clk             : in  std_logic;
         i_reset           : in  std_logic;
         i_address         : in  std_logic_vector(31 downto 0);
         i_read_enable     : in  std_logic;
         i_write_enable    : in  std_logic;
         i_data            : in  std_logic_vector(31 downto 0);
         i_ack             : in  std_logic;
         o_data            : out std_logic_vector(31 downto 0);
         o_MEM_READY       : out std_logic;
         o_DONE            : out std_logic;
         o_DONE2           : out std_logic;
         o_error_detected  : out std_logic;
         o_error           : out std_logic_vector(39 downto 0));
end component;

component Error_Buffer is
	port (i_clk					: in  std_logic;
			i_reset				: in  std_logic;
			i_error				: in  std_logic_vector(39 downto 0);
			i_error_detected	: in  std_logic;
			i_done				: in  std_logic;
			o_data				: out std_logic_vector(7 downto 0);
			o_send				: out std_logic;
			o_ack					: out std_logic);
end component;

component UART_TX is
	port (i_clk		: in  std_logic;
			i_reset	: in  std_logic;
			i_data	: in  std_logic_vector(7 downto 0);
			i_send	: in  std_logic;
			o_data	: out std_logic;
			o_done	: out std_logic);
end component;

--| Define signals
signal w_reset				: std_logic;
signal w_ack				: std_logic;
signal w_error				: std_logic_vector(39 downto 0);
signal w_error_detected	: std_logic;
signal w_uart_done		: std_logic;
signal w_uart_data_in	: std_logic_vector(7 downto 0);
signal w_send				: std_logic;

--| Define constants
constant k_zero10 : std_logic_vector(9 downto 0) := (others => '0');
	
begin
	w_reset <= not i_reset;
	o_zero <= '0';
	o_leds <= k_zero10;
	-- Create the Memory Emulator
	u_Memory : Test80_Reg_TMR
		port map (i_clk => i_clk,
					 i_reset => w_reset,
					 i_address => i_address,
					 i_read_enable => i_read_enable,
					 i_write_enable => i_write_enable,
					 i_data => i_data,
					 i_ack => w_ack,
					 o_data => o_data,
					 o_MEM_READY => o_MEM_READY,
					 o_DONE => o_DONE,
					 o_DONE2 => o_DONE2,
					 o_error_detected => w_error_detected,
					 o_error => w_error);
	-- Create the error buffer
	u_Error_Buffer : Error_Buffer
		port map (i_clk => i_clk,
					 i_reset => w_reset,
					 i_error => w_error,
					 i_error_detected => w_error_detected,
					 i_done => w_uart_done,
					 o_data => w_uart_data_in,
					 o_send => w_send,
					 o_ack => w_ack);
					 
	-- Create the UART Transmitter
	u_UART_TX : UART_TX
		port map (i_clk => i_clk,
					 i_reset => w_reset,
					 i_data => w_uart_data_in,
					 i_send => w_send,
					 o_data => o_UART_ERROR,
					 o_done => w_uart_done);
end a_TMR_Memulator_old;