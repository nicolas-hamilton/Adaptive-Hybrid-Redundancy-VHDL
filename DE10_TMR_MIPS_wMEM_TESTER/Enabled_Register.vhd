--| Enabled_Register.vhd
--| On the rising clock edge, the contents of the register are modified
--|to be equal to the value of i_data if i_en is 1.  Otherwise, the
--| register retains its previous value.
--|
--| INPUTS:
--| i_clk	- Clock
--| i_reset	- Reset
--| i_data	- Data
--| i_en		- Enable the register to store incoming data
--|
--| OUTPUTS:
--| o_Q - Output of register 0
library IEEE;
use IEEE.std_logic_1164.all;

entity Enabled_Register is
	port (i_clk		: in  std_logic;
			i_reset	: in  std_logic;
			i_data	: in  std_logic_vector(31 downto 0);
			i_en		: in  std_logic;
			o_Q		: out std_logic_vector(31 downto 0));
end Enabled_Register;

architecture a_Enabled_Register of Enabled_Register is
--| Declare Components
	component myRegN is
		generic (m_width : integer := 32);
		port (i_clk		: in  std_logic;
				i_reset	: in  std_logic;
				i_D		: in  std_logic_vector(m_width-1 downto 0);
				o_Q		: out std_logic_vector(m_width-1 downto 0));
	end component;
	
	component myMUX2_N is
		generic (m_width : integer := 32);
		port (i_0 : in  std_logic_vector(m_width-1 downto 0);
				i_1 : in  std_logic_vector(m_width-1 downto 0);
				i_S : in  std_logic;
				o_Z : out std_logic_vector(m_width-1 downto 0)
				);
	end component;
	
--| Declare Signals
	-- Register Input
	signal w_D : std_logic_vector(31 downto 0);
	-- Register Output
	signal f_Q : std_logic_vector(31 downto 0);
	
	signal w_EN : std_logic_vector(31 downto 0); -- Enable Signal
begin
	u_myMUX2: myMUX2_N
	generic map (m_width => 32)
	port map (i_0 => f_Q,
				 i_1 => i_data,
				 i_S => i_en,
				 o_Z => w_D);
	--| Store the selected value to the register
	u_myReg: myRegN
	generic map (m_width => 32)
	port map (i_clk => i_clk,
				 i_reset => i_reset,
				 i_D => w_D,
				 o_Q => f_Q);
				 
	--| Connect output signals
	o_Q <= f_Q;
end a_Enabled_Register;