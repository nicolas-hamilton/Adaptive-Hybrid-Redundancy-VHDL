--| Encoder4_2.vhd
--| Encode 4 input bits as a two bit output signal assuming only
--| one of the 4 inputs can be '1' at any time and the remaining
--| inputs are '0'.  Because input 0 is assigned the value '00' and
--| if the inputs 1, 2, and 3 are 0, input 0 is assumed to be '1',
--| encoder only requires inputs 1, 2, and 3.  The output is
--| '01' when input 1 is '1', '10' when input 2 is '1', '11' when
--| input 3 is '1', and '00' when inputs 1, 2, and 3 are all '0'.
--|
--| INPUTS:
--| i_1 - Input 1
--| i_2 - Input 2
--| i_3 - Input 3
--|
--| OUTPUTS:
--| o_Z - Encoded Output
library IEEE;
use IEEE.std_logic_1164.all;

entity Encoder4_2 is
	port (i_1 : in  std_logic;
			i_2 : in  std_logic;
			i_3 : in  std_logic;
			o_Z : out std_logic_vector(1 downto 0));
end Encoder4_2;

architecture a_Encoder4_2 of Encoder4_2 is	
--| Declare Components
	-- Declare NAND_2
	component myNAND2 is
		port (i_A : in  std_logic;
				i_B : in  std_logic;
				o_Z : out std_logic
				);
	end component;
	-- Declare Inverter
	component myINV is
		port (i_A : in  std_logic;
				o_Z : out std_logic
				);
	end component;
	
--| Declare Signals
	signal w_1_n : std_logic; -- Inverted Input 1
	signal w_2_n : std_logic; -- Inverted Input 2
	signal w_3_n : std_logic; -- Inverted Input 3

begin
	--| Invert Inputs
	u_myINV_1 : myINV
	port map (
		i_A => i_1,
		o_Z => w_1_n);
		
	u_myINV_2 : myINV
	port map (
		i_A => i_2,
		o_Z => w_2_n);
		
	u_myINV_3 : myINV
	port map (
		i_A => i_3,
		o_Z => w_3_n);
		
	--| Create output signals
	u_myNAND_0 : myNAND2
	port map (
		i_A => w_3_n,
		i_B => w_1_n,
		o_Z => o_Z(0));
		
	u_myNAND_1 : myNAND2
	port map (
		i_A => w_3_n,
		i_B => w_2_n,
		o_Z => o_Z(1));
end a_Encoder4_2;