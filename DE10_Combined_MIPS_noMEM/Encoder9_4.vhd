--| Encoder9_4.vhd
--| Encode 9 input bits as a 4-bit output signal assuming only
--| one of the 9 inputs can be '1' at any time and the remaining
--| inputs are '0'.  Because input 0 is assigned the value '00',
--| if the remaining inputs are '0', input 0 is assumed to be '1',
--| encoder only requires inputs 1 to 8.
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
--| i_6 - Input 6
--| i_7 - Input 7
--| i_8 - Input 8
--|
--| OUTPUTS:
--| o_Z - Encoded Output
library IEEE;
use IEEE.std_logic_1164.all;

entity Encoder9_4 is
	port (i_1 : in  std_logic;
			i_2 : in  std_logic;
			i_3 : in  std_logic;
			i_4 : in  std_logic;
			i_5 : in  std_logic;
			i_6 : in  std_logic;
			i_7 : in  std_logic;
			i_8 : in  std_logic;
			o_Z : out std_logic_vector(3 downto 0));
end Encoder9_4;

architecture a_Encoder9_4 of Encoder9_4 is	
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
	signal w_6_n : std_logic; -- Inverted Input 6
	signal w_7_n : std_logic; -- Inverted Input 7
	
	-- Intermediate signals
	signal w_sig0, w_sig0_n : std_logic;
	signal w_sig1, w_sig1_n : std_logic;
	signal w_sig2, w_sig2_n : std_logic;
	signal w_sig3, w_sig3_n : std_logic;
	signal w_sig4, w_sig4_n : std_logic;

begin
	o_Z(3) <= i_8;

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
		
	u_myINV_6 : myINV
	port map (
		i_A => i_6,
		o_Z => w_6_n);
		
	u_myINV_7 : myINV
	port map (
		i_A => i_7,
		o_Z => w_7_n);
		
	-- Invert itermediate signals
	u_myINV_sig0 : myINV
	port map (
		i_A => w_sig0,
		o_Z => w_sig0_n);
		
	u_myINV_sig1 : myINV
	port map (
		i_A => w_sig1,
		o_Z => w_sig1_n);	
	
	u_myINV_sig2 : myINV
	port map (
		i_A => w_sig2,
		o_Z => w_sig2_n);
		
	u_myINV_sig3 : myINV
	port map (
		i_A => w_sig3,
		o_Z => w_sig3_n);
		
	u_myINV_sig4 : myINV
	port map (
		i_A => w_sig4,
		o_Z => w_sig4_n);
		
	--| Create Intermediate Signals
	u_myNAND_sig0 : myNAND2
	port map (
		i_A => w_7_n,
		i_B => w_6_n,
		o_Z => w_sig0);
		
	u_myNAND_sig1 : myNAND2
	port map (
		i_A => w_5_n,
		i_B => w_4_n,
		o_Z => w_sig1);
		
	u_myNAND_sig2 : myNAND2
	port map (
		i_A => w_3_n,
		i_B => w_2_n,
		o_Z => w_sig2);
		
	u_myNAND_sig3 : myNAND2
	port map (
		i_A => w_7_n,
		i_B => w_5_n,
		o_Z => w_sig3);
		
	u_myNAND_sig4 : myNAND2
	port map (
		i_A => w_3_n,
		i_B => w_1_n,
		o_Z => w_sig4);
	
	--| Create output signals
	u_myNAND_Z2 : myNAND2
	port map (
		i_A => w_sig0_n,
		i_B => w_sig1_n,
		o_Z => o_Z(2));
		
	u_myNAND_Z1 : myNAND2
	port map (
		i_A => w_sig0_n,
		i_B => w_sig2_n,
		o_Z => o_Z(1));
		
	u_myNAND_Z0 : myNAND2
	port map (
		i_A => w_sig3_n,
		i_B => w_sig4_n,
		o_Z => o_Z(0));
end a_Encoder9_4;