--| Encoder6_3.vhd
--| Encode 6 input bits as a 3-bit output signal assuming only
--| one of the 6 inputs can be '1' at any time and the remaining
--| inputs are '0'.  Because input 0 is assigned the value '00',
--| if the remaining inputs are '0', input 0 is assumed to be '1',
--| encoder only requires inputs 1 to 5.
--| Input => Output
--| i_1 => '0001'
--| i_2 => '0010'
--| i_3 => '0011'
--| i_4 => '0100'
--| i_5 => '0101'
--| i_6 => '0110'
--| i_7 => '0111'
--| i_8 => '1000'
--|
--| INPUTS:
--| i_1 - Input 1
--| i_2 - Input 2
--| i_3 - Input 3
--| i_4 - Input 4
--| i_5 - Input 5
--|
--| OUTPUTS:
--| o_Z - Encoded Output
library IEEE;
use IEEE.std_logic_1164.all;

entity Encoder6_3 is
	port (i_1 : in  std_logic;
			i_2 : in  std_logic;
			i_3 : in  std_logic;
			i_4 : in  std_logic;
			i_5 : in  std_logic;
			o_Z : out std_logic_vector(2 downto 0));
end Encoder6_3;

architecture a_Encoder6_3 of Encoder6_3 is	
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
	-- Inverted Input signals
	signal w_1_n : std_logic; -- Inverted Input 1
	signal w_2_n : std_logic; -- Inverted Input 2
	signal w_3_n : std_logic; -- Inverted Input 3
	signal w_4_n : std_logic; -- Inverted Input 4
	signal w_5_n : std_logic; -- Inverted Input 5
	
	-- Intermediate signals
	signal w_sig0, w_sig0_n : std_logic;

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
		
	u_myINV_4 : myINV
	port map (
		i_A => i_4,
		o_Z => w_4_n);
		
	u_myINV_5 : myINV
	port map (
		i_A => i_5,
		o_Z => w_5_n);
		
	-- Invert itermediate signals
	u_myINV_sig0 : myINV
	port map (
		i_A => w_sig0,
		o_Z => w_sig0_n);
		
	--| Create Intermediate Signals
	u_myNAND_sig0 : myNAND2
	port map (
		i_A => w_1_n,
		i_B => w_3_n,
		o_Z => w_sig0);
	
	--| Create output signals
	u_myNAND_Z2 : myNAND2
	port map (
		i_A => w_4_n,
		i_B => w_5_n,
		o_Z => o_Z(2));
		
	u_myNAND_Z1 : myNAND2
	port map (
		i_A => w_2_n,
		i_B => w_3_n,
		o_Z => o_Z(1));
		
	u_myNAND_Z0 : myNAND2
	port map (
		i_A => w_sig0_n,
		i_B => w_5_n,
		o_Z => o_Z(0));
end a_Encoder6_3;