--| DE10_TMR_MIPS_noMEM.vhd
--| Instantiate three (3) Basic MIPS processors and a Voter to
--| compare their outputs.  Connects to memory in order to
--| recieve instructions and data from memory and to send data
--| to memory.
library IEEE;
use IEEE.std_logic_1164.all;

entity DE10_TMR_MIPS_noMEM is
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
end DE10_TMR_MIPS_noMEM;

architecture a_DE10_TMR_MIPS_noMEM of DE10_TMR_MIPS_noMEM is
--| Define Components
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
	
	component TMR_VOTER is
		port (i_clk				: in  std_logic;
				i_reset			: in  std_logic;
				i_MEM_READ0		: in  std_logic;
				i_MEM_READ1		: in  std_logic;
				i_MEM_READ2		: in  std_logic;
				i_MEM_WRITE0	: in  std_logic;
				i_MEM_WRITE1	: in  std_logic;
				i_MEM_WRITE2	: in  std_logic;
				i_MEM_IN0		: in  std_logic_vector(31 downto 0);
				i_MEM_IN1		: in  std_logic_vector(31 downto 0);
				i_MEM_IN2		: in  std_logic_vector(31 downto 0);
				i_MEM_ADDRESS0	: in  std_logic_vector(31 downto 0);
				i_MEM_ADDRESS1	: in  std_logic_vector(31 downto 0);
				i_MEM_ADDRESS2	: in  std_logic_vector(31 downto 0);
				i_MEM_OUT		: in  std_logic_vector(31 downto 0);
				i_MEM_READY		: in  std_logic;
				o_MEM_READ		: out std_logic;
				o_MEM_WRITE		: out std_logic;
				o_MEM_IN			: out std_logic_vector(31 downto 0);
				o_MEM_ADDRESS	: out std_logic_vector(31 downto 0);
				o_MEM_OUT0		: out std_logic_vector(31 downto 0);
				o_MEM_OUT1		: out std_logic_vector(31 downto 0);
				o_MEM_OUT2		: out std_logic_vector(31 downto 0);
				o_MEM_READY0	: out std_logic;
				o_MEM_READY1	: out std_logic;
				o_MEM_READY2	: out std_logic;
				o_RESET0			: out std_logic;
				o_RESET1			: out std_logic;
				o_RESET2			: out std_logic);
	end component;

	
--| Define signals
	signal w_reset_n			: std_logic;
	signal w_reset_voter		: std_logic;
	signal w_MEM_OUT			: std_logic_vector(31 downto 0);
	signal w_MEM_READ			: std_logic;
	signal w_MEM_WRITE		: std_logic;

	-- BASIC_MIPS0 Signals
	signal w_MEM_READ0		: std_logic;
	signal w_MEM_WRITE0		: std_logic;
	signal w_MEM_IN0			: std_logic_vector(31 downto 0);
	signal w_MEM_ADDRESS0	: std_logic_vector(31 downto 0);
	signal w_MEM_OUT0			: std_logic_vector(31 downto 0);
	signal w_MEM_READY0		: std_logic;
	signal w_RESET0			: std_logic;
	signal w_RESET_MIPS0		: std_logic;
	-- BASIC_MIPS1 Signals
	signal w_MEM_READ1		: std_logic;
	signal w_MEM_WRITE1		: std_logic;
	signal w_MEM_IN1			: std_logic_vector(31 downto 0);
	signal w_MEM_ADDRESS1	: std_logic_vector(31 downto 0);
	signal w_MEM_OUT1			: std_logic_vector(31 downto 0);
	signal w_MEM_READY1		: std_logic;
	signal w_RESET1			: std_logic;
	signal w_RESET_MIPS1		: std_logic;
	-- BASIC_MIPS2 Signals
	signal w_MEM_READ2		: std_logic;
	signal w_MEM_WRITE2		: std_logic;
	signal w_MEM_IN2			: std_logic_vector(31 downto 0);
	signal w_MEM_ADDRESS2	: std_logic_vector(31 downto 0);
	signal w_MEM_OUT2			: std_logic_vector(31 downto 0);
	signal w_MEM_READY2		: std_logic;
	signal w_RESET2			: std_logic;
	signal w_RESET_MIPS2		: std_logic;
	
	constant k_zero10 : std_logic_vector(9 downto 0) := (others => '0');
	
begin
	w_reset_n <= not i_reset;
	w_reset_voter <= w_reset_n or i_DONE;
	w_RESET_MIPS0 <= w_reset_n or w_RESET0 or i_DONE;
	w_RESET_MIPS1 <= w_reset_n or w_RESET1 or i_DONE;
	w_RESET_MIPS2 <= w_reset_n or w_RESET2 or i_DONE;
	o_leds(9 downto 6) <= (others => '0');
	o_leds(5) <= i_reset;
	o_leds(4) <= w_reset_n;
	o_leds(3) <= i_DONE;
	o_leds(2) <= i_MEM_READY;
	o_leds(1) <= w_MEM_READ;
	o_leds(0) <= w_MEM_WRITE;
	o_MEM_READ <= w_MEM_READ;
	o_MEM_WRITE <= w_MEM_WRITE;
	
	-- Create BASIC_MIPS processor 0
	u_Basic_MIPS0 : Basic_MIPS
	port map (i_clk => i_clk,
				 i_reset => w_RESET_MIPS0,
				 i_MEM_OUT => w_MEM_OUT0,
				 i_MEM_READY => w_MEM_READY0,
				 o_MEM_READ => w_MEM_READ0,
				 o_MEM_WRITE => w_MEM_WRITE0,
				 o_MEM_IN => w_MEM_IN0,
				 o_MEM_ADDRESS => w_MEM_ADDRESS0);
	-- Create BASIC_MIPS processor 1
	u_Basic_MIPS1 : Basic_MIPS
	port map (i_clk => i_clk,
				 i_reset => w_RESET_MIPS1,
				 i_MEM_OUT => w_MEM_OUT1,
				 i_MEM_READY => w_MEM_READY1,
				 o_MEM_READ => w_MEM_READ1,
				 o_MEM_WRITE => w_MEM_WRITE1,
				 o_MEM_IN => w_MEM_IN1,
				 o_MEM_ADDRESS => w_MEM_ADDRESS1);
	-- Create BASIC_MIPS processor 2
	u_Basic_MIPS2 : Basic_MIPS
	port map (i_clk => i_clk,
				 i_reset => w_RESET_MIPS2,
				 i_MEM_OUT => w_MEM_OUT2,
				 i_MEM_READY => w_MEM_READY2,
				 o_MEM_READ => w_MEM_READ2,
				 o_MEM_WRITE => w_MEM_WRITE2,
				 o_MEM_IN => w_MEM_IN2,
				 o_MEM_ADDRESS => w_MEM_ADDRESS2);
	-- Create TMR_VOTER
	u_TMR_VOTER : TMR_VOTER
	port map (i_clk => i_clk,
				 i_reset => w_reset_voter,
				 i_MEM_READ0 => w_MEM_READ0,
				 i_MEM_READ1 => w_MEM_READ1,
				 i_MEM_READ2 => w_MEM_READ2,
				 i_MEM_WRITE0 => w_MEM_WRITE0,
				 i_MEM_WRITE1 => w_MEM_WRITE1,
				 i_MEM_WRITE2 => w_MEM_WRITE2,
				 i_MEM_IN0 => w_MEM_IN0,
				 i_MEM_IN1 => w_MEM_IN1,
				 i_MEM_IN2 => w_MEM_IN2,
				 i_MEM_ADDRESS0 => w_MEM_ADDRESS0,
				 i_MEM_ADDRESS1 => w_MEM_ADDRESS1,
				 i_MEM_ADDRESS2 => w_MEM_ADDRESS2,
				 i_MEM_OUT => i_MEM_OUT,
				 i_MEM_READY => i_MEM_READY,
				 o_MEM_READ => w_MEM_READ,
				 o_MEM_WRITE => w_MEM_WRITE,
				 o_MEM_IN => o_MEM_IN,
				 o_MEM_ADDRESS => o_MEM_ADDRESS,
				 o_MEM_OUT0 => w_MEM_OUT0,
				 o_MEM_OUT1 => w_MEM_OUT1,
				 o_MEM_OUT2 => w_MEM_OUT2,
				 o_MEM_READY0 => w_MEM_READY0,
				 o_MEM_READY1 => w_MEM_READY1,
				 o_MEM_READY2 => w_MEM_READY2,
				 o_RESET0 => w_RESET0,
				 o_RESET1 => w_RESET1,
				 o_RESET2 => w_RESET2);
				 
end a_DE10_TMR_MIPS_noMEM;