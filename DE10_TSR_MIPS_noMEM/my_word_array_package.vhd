library IEEE;
use IEEE.std_logic_1164.all;
package my_word_array_package is
	type word_array is array (31 downto 0) of std_logic_vector(31 downto 0);
end my_word_array_package;