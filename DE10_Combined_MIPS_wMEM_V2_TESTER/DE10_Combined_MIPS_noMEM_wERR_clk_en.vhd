--| DE10_Combined_MIPS_noMEM_wERR_clk_en.vhd
--| Instantiate three (3) Basic MIPS processors and a Voter to
--| compare their outputs.  Connects to memory in order to
--| recieve instructions and data from memory and to send data
--| to memory.
library IEEE;
use IEEE.std_logic_1164.all;

entity DE10_Combined_MIPS_noMEM_wERR_clk_en is
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
			i_clk_en				: in  std_logic;
			i_MEM_OUT			: in  std_logic_vector(31 downto 0);
			i_MEM_READY			: in  std_logic;
			i_DONE				: in  std_logic;
			o_MEM_READ			: out std_logic;
			o_MEM_WRITE			: out std_logic;
			o_MEM_IN				: out std_logic_vector(31 downto 0);
			o_MEM_ADDRESS		: out std_logic_vector(31 downto 0);
			o_LEDS				: out std_logic_vector(9 downto 0));
end DE10_Combined_MIPS_noMEM_wERR_clk_en;

architecture a_DE10_Combined_MIPS_noMEM_wERR_clk_en of DE10_Combined_MIPS_noMEM_wERR_clk_en is
--| Define Components
	component Basic_MIPS_clk_en is
		port (i_clk					: in  std_logic;
				i_reset				: in  std_logic;
				i_clk_en				: in  std_logic;
				i_MEM_OUT			: in  std_logic_vector(31 downto 0);
				i_MEM_READY			: in  std_logic;
				o_MEM_READ			: out std_logic;
				o_MEM_WRITE			: out std_logic;
				o_MEM_IN				: out std_logic_vector(31 downto 0);
				o_MEM_ADDRESS		: out std_logic_vector(31 downto 0));
	end component;
	
	component Basic_MIPS_Error_Prone_clk_en is
		generic(k_reg_sel_1	: std_logic_vector(4 downto 0) := "00111";-- Location to which the data will be stored in the GPR Bank
				  k_reg_num_1 : integer := 7; -- Location from which the data will be used to create an error - should match k_reg_sel
			     k_PC_err_1	: std_logic_vector(31 downto 0) := "00000000000000000000000001110100";-- PC address at which the error will be injected
			     k_loop_err_1	: std_logic_vector(31 downto 0) := "00000000000000000000001011001000";-- Loop index at which the error will be injected
			     k_err_bit_1		: integer := 5; -- Bit where the error (bit flip) will be injected
				  k_reg_sel_2	: std_logic_vector(4 downto 0) := "00111";-- Location to which the data will be stored in the GPR Bank
				  k_reg_num_2 : integer := 7; -- Location from which the data will be used to create an error - should match k_reg_sel
			     k_PC_err_2	: std_logic_vector(31 downto 0) := "00000000000000000000000001110100";-- PC address at which the error will be injected
			     k_loop_err_2	: std_logic_vector(31 downto 0) := "00000000000000000000001011001000";-- Loop index at which the error will be injected
			     k_err_bit_2		: integer := 5); -- Bit where the error (bit flip) will be injected
		port (i_clk					: in  std_logic;
				i_reset				: in  std_logic;
				i_clk_en				: in  std_logic;
				i_DONE				: in  std_logic;
				i_MEM_OUT			: in  std_logic_vector(31 downto 0);
				i_MEM_READY			: in  std_logic;
				i_Err_Override		: in  std_logic;
				o_MEM_READ			: out std_logic;
				o_MEM_WRITE			: out std_logic;
				o_MEM_IN				: out std_logic_vector(31 downto 0);
				o_MEM_ADDRESS		: out std_logic_vector(31 downto 0));
	end component;
	
	component TMR_Voter_Test1002_clk_en is
		port (i_clk				: in  std_logic;
				i_reset			: in  std_logic;
				i_clk_en				: in  std_logic;
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
				o_RESET2			: out std_logic;
				o_NEXT_INSTR	: out std_logic;
				o_TMR_ERROR		: out std_logic;
				o_ERR_OVERRIDE	: out std_logic);
	end component;
	
	component Combined_Controller_v2_Test1002_clk_en is
		port (i_clk				: in  std_logic;
				i_reset			: in  std_logic;
				i_clk_en				: in  std_logic;
				i_NEXT_INSTR	: in  std_logic;								-- From TMR Voter	- used to determine next state
				i_TMR_ERROR		: in  std_logic;								-- From TMR Voter	- used to determine next state
				i_MEM_READ		: in  std_logic;								-- From TMR Voter	- used to determine next state	- controller can modify this signal
				i_MEM_WRITE		: in  std_logic;								-- From TMR Voter	- used to determine next state	- controller can modify this signal
				i_MEM_ADDRESS	: in  std_logic_vector(31 downto 0);	-- From TMR Voter	- used to determine next state	- controller can modify this signal
				i_MEM_IN			: in  std_logic_vector(31 downto 0);	-- From TMR Voter												- controller can modify this signal
				i_MEM_READY		: in  std_logic;								-- From Memory		- used to determine next state	- controller can modify this signal
				i_MEM_OUT		: in  std_logic_vector(31 downto 0);	-- From Memory													- controller can modify this signal
				i_MEM_DONE		: in  std_logic;								-- From Memory													- controller can modify this signal
				i_MEM_READ0		: in  std_logic;								-- From MIPS0		- used to determine next state	- controller can modify this signal
				i_MEM_WRITE0	: in  std_logic;								-- From MIPS0													- controller can modify this signal
				i_MEM_ADDRESS0	: in  std_logic_vector(31 downto 0);	-- From MIPS0		- used to determine next state	- controller can modify this signal
				i_MEM_IN0		: in  std_logic_vector(31 downto 0);	-- From MIPS0													- controller can modify this signal
				i_MEM_READY0	: in  std_logic;								-- From Voter													- controller can modify this signal
				i_MEM_OUT0		: in  std_logic_vector(31 downto 0);	-- From Voter													- controller can modify this signal
				i_RESET0			: in  std_logic;								-- From Voter													- controller can modify this signal
				i_MEM_READY1	: in  std_logic;								-- From Voter													- controller can modify this signal
				i_MEM_OUT1		: in  std_logic_vector(31 downto 0);	-- From Voter													- controller can modify this signal
				i_RESET1			: in  std_logic;								-- From Voter													- controller can modify this signal
				i_MEM_READY2	: in  std_logic;								-- From Voter													- controller can modify this signal
				i_MEM_OUT2		: in  std_logic_vector(31 downto 0);	-- From Voter													- controller can modify this signal
				i_RESET2			: in  std_logic;								-- From Voter													- controller can modify this signal
				o_MEM_READ		: out std_logic;								-- To Memory
				o_MEM_WRITE		: out std_logic;								-- To Memory
				o_MEM_ADDRESS	: out std_logic_vector(31 downto 0);	-- To Memory
				o_MEM_IN			: out std_logic_vector(31 downto 0);	-- To Memory
				o_MEM_READY		: out std_logic;								-- To TMR Voter
				o_MEM_OUT		: out std_logic_vector(31 downto 0);	-- To TMR Voter
				o_MEM_DONE		: out std_logic;								-- To TMR Voter
				o_MEM_READY0	: out std_logic;								-- To MIPS0
				o_MEM_OUT0		: out std_logic_vector(31 downto 0);	-- To MIPS0
				o_RESET0			: out std_logic;								-- To MIPS0
				o_MEM_READY1	: out std_logic;								-- To MIPS1
				o_MEM_OUT1		: out std_logic_vector(31 downto 0);	-- To MIPS1
				o_RESET1			: out std_logic;								-- To MIPS1
				o_MEM_READY2	: out std_logic;								-- To MIPS2
				o_MEM_OUT2		: out std_logic_vector(31 downto 0);	-- To MIPS2
				o_RESET2			: out std_logic);								-- To MIPS2
	end component;


	
--| Define signals
	signal w_reset_n			: std_logic;
	signal w_reset_voter		: std_logic;
	signal w_MEM_READ_A		: std_logic;
	signal w_MEM_READ_B		: std_logic;
	signal w_MEM_WRITE_A		: std_logic;
	signal w_MEM_WRITE_B		: std_logic;
	signal w_MEM_ADDRESS		: std_logic_vector(31 downto 0);
	signal w_MEM_IN			: std_logic_vector(31 downto 0);
	signal w_MEM_READY		: std_logic;
	signal w_MEM_OUT			: std_logic_vector(31 downto 0);
	signal w_DONE				: std_logic;
	signal w_NEXT_INSTR		: std_logic;
	signal w_TMR_ERROR		: std_logic;
	signal w_ERR_OVERRIDE	: std_logic;

	-- BASIC_MIPS0 Signals
	signal w_MEM_READ0		: std_logic;
	signal w_MEM_WRITE0		: std_logic;
	signal w_MEM_IN0			: std_logic_vector(31 downto 0);
	signal w_MEM_ADDRESS0	: std_logic_vector(31 downto 0);
	signal w_MEM_READY0_A	: std_logic;
	signal w_MEM_READY0_B	: std_logic;
	signal w_MEM_OUT0_A		: std_logic_vector(31 downto 0);
	signal w_MEM_OUT0_B		: std_logic_vector(31 downto 0);
	signal w_RESET0_A			: std_logic;
	signal w_RESET0_B			: std_logic;
	signal w_RESET_MIPS0		: std_logic;
	-- BASIC_MIPS1 Signals
	signal w_MEM_READ1		: std_logic;
	signal w_MEM_WRITE1		: std_logic;
	signal w_MEM_IN1			: std_logic_vector(31 downto 0);
	signal w_MEM_ADDRESS1	: std_logic_vector(31 downto 0);
	signal w_MEM_READY1_A	: std_logic;
	signal w_MEM_READY1_B	: std_logic;
	signal w_MEM_OUT1_A		: std_logic_vector(31 downto 0);
	signal w_MEM_OUT1_B		: std_logic_vector(31 downto 0);
	signal w_RESET1_A			: std_logic;
	signal w_RESET1_B			: std_logic;
	signal w_RESET_MIPS1		: std_logic;
	-- BASIC_MIPS2 Signals
	signal w_MEM_READ2		: std_logic;
	signal w_MEM_WRITE2		: std_logic;
	signal w_MEM_IN2			: std_logic_vector(31 downto 0);
	signal w_MEM_ADDRESS2	: std_logic_vector(31 downto 0);
	signal w_MEM_READY2_A	: std_logic;
	signal w_MEM_READY2_B	: std_logic;
	signal w_MEM_OUT2_A		: std_logic_vector(31 downto 0);
	signal w_MEM_OUT2_B		: std_logic_vector(31 downto 0);
	signal w_RESET2_A			: std_logic;
	signal w_RESET2_B			: std_logic;
	signal w_RESET_MIPS2		: std_logic;
	
	constant k_zero10 : std_logic_vector(9 downto 0) := (others => '0');
	
begin
	w_reset_n <= not i_reset;						-- Invert reset button input
	w_reset_voter <= w_reset_n or w_DONE;		-- Determine Voter Reset Signal
	w_RESET_MIPS0 <= w_reset_n or w_RESET0_B; -- Determine MIPS0 Reset Signal
	w_RESET_MIPS1 <= w_reset_n or w_RESET1_B; -- Determine MIPS1 Reset Signal
	w_RESET_MIPS2 <= w_reset_n or w_RESET2_B;	-- Determine MIPS2 Reset Signal
	-- Display selected signals on LEDs
	o_leds(9 downto 6) <= (others => '0');
	o_leds(5) <= i_reset;
	o_leds(4) <= w_reset_n;
	o_leds(3) <= i_DONE;
	o_leds(2) <= i_MEM_READY;
	o_leds(1) <= w_MEM_READ_B;
	o_leds(0) <= w_MEM_WRITE_B;
	-- Assign read and write output signals to memory
	o_MEM_READ <= w_MEM_READ_B;
	o_MEM_WRITE <= w_MEM_WRITE_B;
	
	-- Create BASIC_MIPS processor 0
	u_Basic_MIPS0 : Basic_MIPS_Error_Prone_clk_en
	generic map (k_reg_sel_1 => k_reg_sel_1,
					 k_reg_num_1 => k_reg_num_1,
					 k_PC_err_1 => k_PC_err_1,
					 k_loop_err_1 => k_loop_err_1,
					 k_err_bit_1 => k_err_bit_1_0,
					 k_reg_sel_2 => k_reg_sel_2,
					 k_reg_num_2 => k_reg_num_2,
					 k_PC_err_2 => k_PC_err_2,
					 k_loop_err_2 => k_loop_err_2,
					 k_err_bit_2 => k_err_bit_2_0)
	port map (i_clk => i_clk,
				 i_reset => w_RESET_MIPS0,				-- From Reset Button and Controller
				 i_clk_en => i_clk_en,
				 i_DONE => i_DONE,						-- From memory reset signal
				 i_MEM_OUT => w_MEM_OUT0_B,			-- From Controller
				 i_MEM_READY => w_MEM_READY0_B,		-- From Controller
				 i_Err_Override => w_ERR_OVERRIDE,  -- Error overide signal from voter
				 o_MEM_READ => w_MEM_READ0,			-- To Voter and Controller
				 o_MEM_WRITE => w_MEM_WRITE0,			-- To Voter and Controller
				 o_MEM_IN => w_MEM_IN0,					-- To Voter and Controller
				 o_MEM_ADDRESS => w_MEM_ADDRESS0);	-- To Voter and Controller
	
	-- Create BASIC_MIPS processor 1
	u_Basic_MIPS1 : Basic_MIPS_clk_en
	port map (i_clk => i_clk,
				 i_reset => w_RESET_MIPS1,				-- From Reset Button and Controller
				 i_clk_en => i_clk_en,
				 i_MEM_OUT => w_MEM_OUT1_B,			-- From Controller
				 i_MEM_READY => w_MEM_READY1_B,		-- From Controller
				 o_MEM_READ => w_MEM_READ1,			-- To Voter
				 o_MEM_WRITE => w_MEM_WRITE1,			-- To Voter
				 o_MEM_IN => w_MEM_IN1,					-- To Voter
				 o_MEM_ADDRESS => w_MEM_ADDRESS1);	-- To Voter
	
--	-- Create BASIC_MIPS processor 1
--	u_Basic_MIPS1 : Basic_MIPS_Error_Prone_clk_en
--	generic map (k_reg_sel_1 => k_reg_sel_1,
--					 k_reg_num_1 => k_reg_num_1,
--					 k_PC_err_1 => k_PC_err_1,
--					 k_loop_err_1 => k_loop_err_1,
--					 k_err_bit_1 => k_err_bit_1_1,
--					 k_reg_sel_2 => k_reg_sel_2,
--					 k_reg_num_2 => k_reg_num_2,
--					 k_PC_err_2 => k_PC_err_2,
--					 k_loop_err_2 => k_loop_err_2,
--					 k_err_bit_2 => k_err_bit_2_1)
--	port map (i_clk => i_clk,
--				 i_reset => w_RESET_MIPS0,				-- From Reset Button and Controller
--				 i_clk_en => i_clk_en,
--				 i_DONE => i_DONE,						-- From memory reset signal
--				 i_MEM_OUT => w_MEM_OUT0_B,			-- From Controller
--				 i_MEM_READY => w_MEM_READY0_B,		-- From Controller
--				 i_Err_Override => w_ERR_OVERRIDE,  -- Error overide signal from voter
--				 o_MEM_READ => w_MEM_READ0,			-- To Voter and Controller
--				 o_MEM_WRITE => w_MEM_WRITE0,			-- To Voter and Controller
--				 o_MEM_IN => w_MEM_IN0,					-- To Voter and Controller
--				 o_MEM_ADDRESS => w_MEM_ADDRESS0);	-- To Voter and Controller
	
	-- Create BASIC_MIPS processor 2
	u_Basic_MIPS2 : Basic_MIPS_clk_en
	port map (i_clk => i_clk,
				 i_reset => w_RESET_MIPS2,				-- From Reset Button and Controller
				 i_clk_en => i_clk_en,
				 i_MEM_OUT => w_MEM_OUT2_B,			-- From Controller
				 i_MEM_READY => w_MEM_READY2_B,		-- From Controller
				 o_MEM_READ => w_MEM_READ2,			-- To Voter
				 o_MEM_WRITE => w_MEM_WRITE2,			-- To Voter
				 o_MEM_IN => w_MEM_IN2,					-- To Voter
				 o_MEM_ADDRESS => w_MEM_ADDRESS2);	-- To Voter
				 
	-- Create TMR_VOTER
	u_TMR_VOTER : TMR_VOTER_Test1002_clk_en
	port map (i_clk => i_clk,
				 i_reset => w_reset_voter,
				 i_clk_en => i_clk_en,
				 i_MEM_READ0 => w_MEM_READ0,			-- From MIPS0
				 i_MEM_READ1 => w_MEM_READ1,			-- From MIPS1
				 i_MEM_READ2 => w_MEM_READ2,			-- From MIPS2
				 i_MEM_WRITE0 => w_MEM_WRITE0,		-- From MIPS0
				 i_MEM_WRITE1 => w_MEM_WRITE1,		-- From MIPS1
				 i_MEM_WRITE2 => w_MEM_WRITE2,		-- From MIPS2
				 i_MEM_IN0 => w_MEM_IN0,				-- From MIPS0
				 i_MEM_IN1 => w_MEM_IN1,				-- From MIPS1
				 i_MEM_IN2 => w_MEM_IN2,				-- From MIPS2
				 i_MEM_ADDRESS0 => w_MEM_ADDRESS0,	-- From MIPS0
				 i_MEM_ADDRESS1 => w_MEM_ADDRESS1,	-- From MIPS1
				 i_MEM_ADDRESS2 => w_MEM_ADDRESS2,	-- From MIPS2
				 i_MEM_OUT => w_MEM_OUT,				-- From Controller
				 i_MEM_READY => w_MEM_READY,			-- From Controller
				 o_MEM_READ => w_MEM_READ_A,			-- To Controller
				 o_MEM_WRITE => w_MEM_WRITE_A,		-- To Controller
				 o_MEM_IN => w_MEM_IN,					-- To Controller
				 o_MEM_ADDRESS => w_MEM_ADDRESS,		-- To Controller
				 o_MEM_OUT0 => w_MEM_OUT0_A,			-- To Controller
				 o_MEM_OUT1 => w_MEM_OUT1_A,			-- To Controller
				 o_MEM_OUT2 => w_MEM_OUT2_A,			-- To Controller
				 o_MEM_READY0 => w_MEM_READY0_A,		-- To Controller
				 o_MEM_READY1 => w_MEM_READY1_A,		-- To Controller
				 o_MEM_READY2 => w_MEM_READY2_A,		-- To Controller
				 o_RESET0 => w_RESET0_A,				-- To Controller
				 o_RESET1 => w_RESET1_A,				-- To Controller
				 o_RESET2 => w_RESET2_A,				-- To Controller
				 o_NEXT_INSTR => w_NEXT_INSTR,		-- To Controller
				 o_TMR_ERROR => w_TMR_ERROR,			-- To Controller
				 o_ERR_OVERRIDE => w_ERR_OVERRIDE); -- To Error Prone MIPS processors
				 
	-- Create Combined_Controller
	u_Combined_Controller : Combined_Controller_v2_Test1002_clk_en
	port map (i_clk				=> i_clk,
				 i_reset				=> w_reset_n,
				 i_clk_en => i_clk_en,
				 i_NEXT_INSTR		=> w_NEXT_INSTR,		-- From Voter
				 i_TMR_ERROR		=> w_TMR_ERROR,		-- From Voter
				 i_MEM_READ			=> w_MEM_READ_A,		-- From Voter
				 i_MEM_WRITE		=> w_MEM_WRITE_A,		-- From Voter
				 i_MEM_ADDRESS		=> w_MEM_ADDRESS,		-- From Voter
				 i_MEM_IN			=> w_MEM_IN,			-- From Voter
				 i_MEM_READY		=> i_MEM_READY,		-- From Memory
				 i_MEM_OUT			=> i_MEM_OUT,			-- From Memory
				 i_MEM_DONE			=> i_DONE,				-- From Memory
				 i_MEM_READ0		=> w_MEM_READ0,		-- From MIPS 0
				 i_MEM_WRITE0		=> w_MEM_WRITE0,		-- From MIPS 0
				 i_MEM_ADDRESS0	=> w_MEM_ADDRESS0,	-- From MIPS 0
				 i_MEM_IN0			=> w_MEM_IN0,			-- From MIPS 0
				 i_MEM_READY0		=> w_MEM_READY0_A,	-- From Voter
				 i_MEM_OUT0			=> w_MEM_OUT0_A,		-- From Voter
				 i_RESET0			=> w_RESET0_A,			-- From Voter
				 i_MEM_READY1		=> w_MEM_READY1_A,	-- From Voter
				 i_MEM_OUT1			=> w_MEM_OUT1_A,		-- From Voter
				 i_RESET1			=> w_RESET1_A,			-- From Voter
				 i_MEM_READY2		=> w_MEM_READY2_A,	-- From Voter
				 i_MEM_OUT2			=> w_MEM_OUT2_A,		-- From Voter
				 i_RESET2			=> w_RESET2_A,			-- From Voter
				 o_MEM_READ			=> w_MEM_READ_B,		-- To Memory
				 o_MEM_WRITE		=> w_MEM_WRITE_B,		-- To Memory
				 o_MEM_ADDRESS		=> o_MEM_ADDRESS,		-- To Memory
				 o_MEM_IN			=> o_MEM_IN,			-- To Memory
				 o_MEM_READY		=> w_MEM_READY,		-- To Voter
				 o_MEM_OUT			=> w_MEM_OUT,			-- To Voter
				 o_MEM_DONE			=> w_DONE,				-- To Voter
				 o_MEM_READY0		=> w_MEM_READY0_B,	-- To MIPS0
				 o_MEM_OUT0			=> w_MEM_OUT0_B,		-- To MIPS0
				 o_RESET0			=> w_RESET0_B,			-- To MIPS0
				 o_MEM_READY1		=> w_MEM_READY1_B,	-- To MIPS1
				 o_MEM_OUT1			=> w_MEM_OUT1_B,		-- To MIPS1
				 o_RESET1			=> w_RESET1_B,			-- To MIPS1
				 o_MEM_READY2		=> w_MEM_READY2_B,	-- To MIPS2
				 o_MEM_OUT2			=> w_MEM_OUT2_B,		-- To MIPS2
				 o_RESET2			=> w_RESET2_B);		-- To MIPS2
				 
end a_DE10_Combined_MIPS_noMEM_wERR_clk_en;