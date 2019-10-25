--| Over_Detect.vhd
--| Detect overflow for ADD, ADDI, and SUB instructions.  If an overflow occurs
--| for one of these instructions, the destination register should retain its
--| original contents.  To accomplish this, the value of the destination register
--| (RD for ADD/SUB and RT for ADDI) is passed to the output of the ALU.  This
--| value is then stored back to the destination register.  If no overflow
--| occurs or no overflow detection is required, the output of the adder may
--| proceed to the ALU output and be stored to the destination register (assuming
--| that an operation making use of the adder has been selected for output).
--|
--| INPUTS:
--| i_AB_NAND 	- NAND(A,B) from bitwise operations (only MSB, bit 31)
--| i_AB_OR 	- OR(A,B) from bitwise operations (only MSB, bit 31)
--| i_AB_XNOR	- XNOR(A,B) from bitwise operations (only MSB, bit 31)
--| i_S - Result of the addition
--| i_RD - Data from register indicated by RD
--| i_RT - Data from register indicated by RT
--| i_OVER_CTRL - Determine which of the signals to output.
--|	0 - i_S - no overflow control needed for the selected operation
--|	1 - i_RD - data from register indicated by RD should be passed through
--|	2 - i_RT - data from register indicated by RD should be passed through
--|	3 - i_S - no overflow control needed for the selected operation
--|
--| OUTPUTS:
--| o_Z - depends on the value of i_OVER_CTRL.  If i_OVER_CTRL is 1 or 2, and
--|       an overflow is detected, then output either i_RD (1) or i_RT (2) so
--|       so that the result of the addition (subtraction) is not written to
--|		 the destination register.  If no overflow is detected, output the
--|		 result of the addition (subtraction)
library IEEE;
use IEEE.std_logic_1164.all;

entity Over_Detect is
	port (i_AB_NAND	: in  std_logic;
			i_AB_OR		: in  std_logic;
			i_AB_XNOR	: in  std_logic;
			i_S			: in  std_logic_vector(31 downto 0);
			i_RD			: in  std_logic_vector(31 downto 0);
			i_RT			: in  std_logic_vector(31 downto 0);
			i_OVER_CTRL	: in  std_logic_vector(1 downto 0);
			o_Z			: out std_logic_vector(31 downto 0)
			);
end Over_Detect;

architecture a_Over_Detect of Over_Detect is
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
	
	-- Declare 4 input, 32-bit mux
	component myMUX4_N is
		generic (m_width : integer := 32);
		port (i_0 : in  std_logic_vector(31 downto 0);
				i_1 : in  std_logic_vector(31 downto 0);
				i_2 : in  std_logic_vector(31 downto 0);
				i_3 : in  std_logic_vector(31 downto 0);
				i_S : in  std_logic_vector(1 downto 0);
				o_Z : out std_logic_vector(31 downto 0)
				);
	end component;
	
	-- Declare 2 input, 32-bit mux
	component myMUX2_N is
		generic (m_width : integer := 32);
		port (i_0 : in  std_logic_vector(31 downto 0);
				i_1 : in  std_logic_vector(31 downto 0);
				i_S : in  std_logic;
				o_Z : out std_logic_vector(31 downto 0)
				);
	end component;
	
	--| Declare Signals
	signal w_S31_n : std_logic;  -- INV(i_S(31))
	signal w_OV_0 : std_logic;
	signal w_OV_1 : std_logic;
	signal w_OV_2, w_OV_2_n : std_logic;
	signal w_OV_3, w_OV_3_n : std_logic;
	signal w_data : std_logic_vector(31 downto 0); -- Output from MUX4_32 and input to MUX2_32
begin
	-- Create Inverets for signals that must be inverted
	u_myINV_S31_n : myINV
	port map (
		i_A => i_S(31),
		o_Z => w_S31_n);
		
	u_myINV_OV_2_n : myINV
	port map (
		i_A => w_OV_2,
		o_Z => w_OV_2_n);
		
	u_myINV_OV_3_n : myINV
	port map (
		i_A => w_OV_3,
		o_Z => w_OV_3_n); -- w_OV_3_n is 1 if an overflow occured and if the instruction is ADD, SUB, or ADDI, 0 otherwise
	
	--Create intermediate signals
	u_myNAND_OV_0 : myNAND2
	port map (
		i_A => i_S(31),
		i_B => i_AB_OR,
		o_Z => w_OV_0);
		
	u_myNAND_OV_1 : myNAND2
	port map (
		i_A => w_S31_n,
		i_B => i_AB_NAND,
		o_Z => w_OV_1);
		
	u_myNAND_OV_2 : myNAND2
	port map (
		i_A => w_OV_0,
		i_B => w_OV_1,
		o_Z => w_OV_2);
		
	u_myNAND_OV_3 : myNAND2
	port map (
		i_A => i_AB_XNOR,
		i_B => w_OV_2_n,
		o_Z => w_OV_3);
	
	-- Create MUXes to select output.
	-- If no overflow detection is required for the given instruction,
	-- pass the output of the adder.  If this is an ADD or SUB
	-- instruction, pass the value of the register pointed to by RD.
	-- If this is an ADDI instruction, pass the value of the register
	-- pointed to by RT.
	u_myMUX4_32: myMUX4_N
	generic map (m_width => 32)
	port map (i_0 => i_S,  -- No Overflow Detection
				 i_1 => i_RD, -- ADD
				 i_2 => i_RD, -- SUB
				 i_3 => i_RT, -- ADDI
				 i_S => i_OVER_CTRL,
				 o_Z => w_data);
					
	-- If an overflow occured, pass the selected data from the output
	-- of the MUX4_32.  If no overflow occured, pass the result from the
	-- adder.
	u_myMUX2_32: myMUX2_N
	generic map (m_width => 32)
	port map (i_0 => i_S,
				 i_1 => w_data,
				 i_S => w_OV_3_n,
				 o_Z => o_Z);
		
end a_Over_Detect;