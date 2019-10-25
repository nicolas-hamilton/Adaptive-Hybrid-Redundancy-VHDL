--| GPR_Bank_clk_en.vhd
--| Bank of 32, 32-bit registers.  On the rising clock edge, only the contents of
--| the selected register are modified to be equal to the value of i_data.  All
--| other registers retain their previous value.
--|
--| INPUTS:
--| i_clk	- Clock
--| i_reset	- Reset
--| i_data	- Data
--| i_sel	- Encoded select signal to determine which register should be enabled
--|
--| OUTPUTS:
--| o_Q00 - Output of register 0
--| o_Q01 - Output of register 1
--| ...
--| o_Q30 - Output of register 30
--| o_Q31 - Output of register 31
library IEEE;
use IEEE.std_logic_1164.all;
use work.my_word_array_package.all;

entity GPR_Bank_clk_en is
	port (i_clk		: in  std_logic;
			i_reset	: in  std_logic;
			i_clk_en	: in  std_logic;
			i_data	: in  std_logic_vector(31 downto 0);
			i_sel		: in  std_logic_vector(4 downto 0);
			o_Q		: out word_array);
--			o_Q00		: out std_logic_vector(31 downto 0);
--			o_Q01		: out std_logic_vector(31 downto 0);
--			o_Q02		: out std_logic_vector(31 downto 0);
--			o_Q03		: out std_logic_vector(31 downto 0);
--			o_Q04		: out std_logic_vector(31 downto 0);
--			o_Q05		: out std_logic_vector(31 downto 0);
--			o_Q06		: out std_logic_vector(31 downto 0);
--			o_Q07		: out std_logic_vector(31 downto 0);
--			o_Q08		: out std_logic_vector(31 downto 0);
--			o_Q09		: out std_logic_vector(31 downto 0);
--			o_Q10		: out std_logic_vector(31 downto 0);
--			o_Q11		: out std_logic_vector(31 downto 0);
--			o_Q12		: out std_logic_vector(31 downto 0);
--			o_Q13		: out std_logic_vector(31 downto 0);
--			o_Q14		: out std_logic_vector(31 downto 0);
--			o_Q15		: out std_logic_vector(31 downto 0);
--			o_Q16		: out std_logic_vector(31 downto 0);
--			o_Q17		: out std_logic_vector(31 downto 0);
--			o_Q18		: out std_logic_vector(31 downto 0);
--			o_Q19		: out std_logic_vector(31 downto 0);
--			o_Q20		: out std_logic_vector(31 downto 0);
--			o_Q21		: out std_logic_vector(31 downto 0);
--			o_Q22		: out std_logic_vector(31 downto 0);
--			o_Q23		: out std_logic_vector(31 downto 0);
--			o_Q24		: out std_logic_vector(31 downto 0);
--			o_Q25		: out std_logic_vector(31 downto 0);
--			o_Q26		: out std_logic_vector(31 downto 0);
--			o_Q27		: out std_logic_vector(31 downto 0);
--			o_Q28		: out std_logic_vector(31 downto 0);
--			o_Q29		: out std_logic_vector(31 downto 0);
--			o_Q30		: out std_logic_vector(31 downto 0);
--			o_Q31		: out std_logic_vector(31 downto 0));
end GPR_Bank_clk_en;

architecture a_GPR_Bank_clk_en of GPR_Bank_clk_en is	
----| Declare Type for a 32 entry array of 32-bit std_logic_vectors.
--	type word_array is array (31 downto 0) of std_logic_vector(31 downto 0);

--| Declare Components
	component myRegN_clk_en is
		generic (m_width : integer := 32);
		port (i_clk		: in  std_logic;
				i_reset	: in  std_logic;
				i_clk_en	: in  std_logic;
				i_D		: in  std_logic_vector(31 downto 0);
				o_Q		: out std_logic_vector(31 downto 0));
	end component;
	
	component Decoder5_32 is
		port (i_S	: in  std_logic_vector(4 downto 0);
				o_Z	: out std_logic_vector(31 downto 0)
				);
	end component;
	
	component myMUX2_N is
		generic (m_width : integer := 32);
		port (i_0 : in  std_logic_vector(31 downto 0);
				i_1 : in  std_logic_vector(31 downto 0);
				i_S : in  std_logic;
				o_Z : out std_logic_vector(31 downto 0)
				);
	end component;
	
--| Declare Signals

	-- Input To Each Register
	signal w_D : word_array;
	-- Output From Each Register
	signal f_Q : word_array;
	
	signal w_EN : std_logic_vector(31 downto 0); -- Enable Signal
begin
	--| Enable Register Signal
	u_Decoder5_32: Decoder5_32
	port map (i_S => i_sel,
				 o_Z => w_EN);

	--| Create the array of registers (excluding the 0 register
	reg_array: for bit_index in 1 to 31 generate
		-- For each register, determine whether the the register input
		-- should be its previous value or i_data.
		u_myMUX2_N: myMUX2_N
		generic map (m_width => 32)
		port map (i_0 => f_Q(bit_index),
					 i_1 => i_data,
					 i_S => w_EN(bit_index),
					 o_Z => w_D(bit_index));
		-- Store the selected value to the register
		u_myRegN: myRegN_clk_en
		generic map (m_width => 32)
		port map (i_clk => i_clk,
					 i_reset => i_reset,
					 i_clk_en => i_clk_en,
					 i_D => w_D(bit_index),
					 o_Q => f_Q(bit_index));
	end generate reg_array;
	
	--| Register 0 should retain its zero value regardless of its being
	--| selected or the value of i_data.
	u_myMUX2_00: myMUX2_N
	generic map (m_width => 32)
	port map (i_0 => f_Q(0),
				 i_1 => f_Q(0),
				 i_S => w_EN(0),
				 o_Z => w_D(0));
	--| Store the selected value to the register
	u_myReg00: myRegN_clk_en
	generic map (m_width => 32)
	port map (i_clk => i_clk,
				 i_reset => i_reset,
				 i_clk_en => i_clk_en,
				 i_D => w_D(0),
				 o_Q => f_Q(0));
				 
	--| Connect output signals
	o_Q <= f_Q;
	
end a_GPR_Bank_clk_en;