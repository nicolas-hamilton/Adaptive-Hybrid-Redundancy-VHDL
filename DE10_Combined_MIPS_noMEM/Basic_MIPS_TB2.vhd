--| Basic_MIPS_TB.vhd
--| Test the functionality of the Basic_MIPS using the MEM_EMULATOR
--| so that the controller can "read" instructions from memory, transition
--| through the appropriate states, and send the proper control signals out
library IEEE;
use IEEE.std_logic_1164.all;

entity Basic_MIPS_TB2 is
end Basic_MIPS_TB2;

architecture testbench of Basic_MIPS_TB2 is
--| Define Components
	--| Controller Finite State Machine
	component Basic_MIPS is
		port (i_clk					: in  std_logic;
				i_reset				: in  std_logic;
				i_MEM_OUT			: in  std_logic_vector(31 downto 0);
				i_MEM_READY			: in  std_logic;
				o_MEM_READ			: out std_logic;
				o_MEM_WRITE			: out std_logic;
				o_MEM_IN				: out std_logic_vector(31 downto 0);
				o_MEM_ADDRESS		: out std_logic_vector(31 downto 0));
	end component;
	
	--| Memory Emulator
	component MEM_EMULATOR2 is
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
	signal w_MEM_IN				: std_logic_vector(31 downto 0);
	signal w_MEM_READ				: std_logic;
	signal w_MEM_WRITE			: std_logic;
	signal w_written_data		: std_logic_vector(31 downto 0);
	signal w_address				: std_logic_vector(31 downto 0);
	
begin
	u_Basic_MIPS : Basic_MIPS
	port map (i_clk => c_clk,
				 i_reset => w_reset,
				 i_MEM_OUT => w_MEM_OUT,
				 i_MEM_READY => w_MEM_READY,
				 o_MEM_READ => w_MEM_READ,
				 o_MEM_WRITE => w_MEM_WRITE,
				 o_MEM_IN => w_MEM_IN,
				 o_MEM_ADDRESS => w_address);
				 
	u_MEM_EMULATOR2 : MEM_EMULATOR2
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