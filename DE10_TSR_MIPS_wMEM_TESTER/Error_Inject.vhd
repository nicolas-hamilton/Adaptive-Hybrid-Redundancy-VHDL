--| Error_Inject.vhd
--| Inject an error into a register in Basic MIPS at the specified
--| program counter address and at the specified bit location.
--|
--| CONSTANTS:
--| k_reg_sel 	- register to which an error will be injected
--| k_PC_err  	- program counter address when error will be injected
--| k_loop_err	- loop index at which the error will be injected
--| k_err_bit	- bit where the error (bit flip) will be injected
--|
--| INPUTS:
--| i_clk			 - clock input
--| i_reset 		 - reset input
--| i_data			 - data to send
--| i_state 		 - current FSM state
--| i_PC				 - current program counter address
--| i_loop_count	 - current loop iteration number
--| i_Err_Override - Override the error injector when voter is performing save/restore point
--|						creation or error recovery
--|
--| OUTPUTS:
--| o_data			 - the erroneous data to write when an error is triggered
--| o_reg_sel		 - select the register to write the erroneous data
--| o_error			 - '1' when an error will be injected and '0' for normal operation
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Error_Inject is
	generic(k_reg_sel		: std_logic_vector(4 downto 0) := "00111";-- Location to which the data will be stored in the GPR Bank
			  k_PC_err		: std_logic_vector(31 downto 0) := "00000000000000000000000001110100";-- PC address at which the error will be injected
			  k_loop_err	: std_logic_vector(31 downto 0) := "00000000000000000000001011001000";-- Loop index at which the error will be injected
			  k_err_bit		: integer := 5); -- Bit where the error (bit flip) will be injected
	port (i_clk				: in  std_logic;
         i_reset			: in  std_logic;
         i_data			: in  std_logic_vector(31 downto 0);
         i_state			: in  std_logic_vector(3 downto 0);
         i_PC				: in  std_logic_vector(31 downto 0);
			i_loop_count	: in  std_logic_vector(31 downto 0);
			i_Err_Override	: in  std_logic;
         o_data			: out std_logic_vector(31 downto 0);
			o_reg_sel		: out std_logic_vector(4 downto 0);
         o_error			: out std_logic);
end Error_Inject;

architecture a_Error_Inject of Error_Inject is
	-- Register to keep track of whether the error has occured yet
	signal f_err_flag : std_logic;
		
	-- Registers to set output signals
	signal f_error : std_logic := '0';
	
--	-- Location to which the data will be stored in the GPR Bank
--	constant k_reg_sel	: std_logic_vector(4 downto 0) := "00111";
--	-- PC address at which to instantiate the error
--	constant k_PC_err		: std_logic_vector(31 downto 0) := "00000000000000000000000001110100";

begin
	o_error <= f_error;
	o_reg_sel <= k_reg_sel;
	
	--| Create data error output array by flipping one of the bits
	out_array: for bit_index in 0 to 31 generate
		bit_X: if (bit_index  = k_err_bit) generate
			o_data(bit_index) <= not i_data(bit_index);
		end generate bit_X;
		bit_others: if (bit_index /= k_err_bit) generate
			o_data(bit_index) <= i_data(bit_index);
		end generate bit_others;
	end generate out_array;

	Error_Inject_process : process (i_clk, i_reset, i_state, i_PC, f_err_flag)
	begin
		if i_reset = '1' then
			f_error <= '0';
			f_err_flag <= '0';
      elsif rising_edge(i_clk) then
			if (f_err_flag = '0') then
				if (i_Err_Override = '0') then
					if (i_loop_count = k_loop_err) then
						if (i_PC = k_PC_err) then
							if (i_state = "0000") then
								f_err_flag <= '1';
								f_error <= '1';
							else
								f_error <= '0';
								f_err_flag <= f_err_flag;
							end if;
						else
							f_error <= '0';
							f_err_flag <= f_err_flag;
						end if;
					else
						f_error <= '0';
						f_err_flag <= f_err_flag;
					end if;
				else
					f_error <= '0';
					f_err_flag <= f_err_flag;
				end if;
			else
				f_error <= '0';
				f_err_flag <= f_err_flag;
			end if;
		end if;
	end process Error_Inject_process;
end a_Error_Inject;
