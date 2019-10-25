--| Test54_Reg_TMR.vhd
--| Author: Nicolas Hamilton using write_TMR_VHDL_MEMULATOR.m
--| Created:  3 May 2019 at 14:11:22
--| Emulate the behaviour of a 32-bit addressable memory.  Uses incoming
--| address to determine which instruction to return next.  For write
--| operations, a single internal register will retain the value of i_data
--| until it is overwritten by the next write operation.  Write operations
--| occur when i_write_enable is '1'.
--|
--| INPUTS:
--| i_clk            - clock input
--| i_reset          - reset input
--| i_address	    - address
--| i_read_enable    - enable read
--| i_write_enable   - enable write
--| i_data           - input data
--| i_ack            - acknowlegement that error buffer has received an error
--|
--| OUTPUTS:
--| o_data           - output data
--| o_MEM_READY      - signal is 1 when read/write operation is complete
--| o_DONE           - signal is 1 when the instruction set is completed
--| o_DONE2          - Copy of o_DONE that is sent to a different output pin
--| o_error_detected - signal is 1 when an error has been detected
--| o_error          - indicates the type and location of the error
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Test54_Reg_TMR is
   port (i_clk             : in  std_logic;
         i_reset           : in  std_logic;
         i_address         : in  std_logic_vector(31 downto 0);
         i_read_enable     : in  std_logic;
         i_write_enable    : in  std_logic;
         i_data            : in  std_logic_vector(31 downto 0);
         i_ack             : in  std_logic;
         o_data            : out std_logic_vector(31 downto 0);
         o_MEM_READY       : out std_logic;
         o_DONE            : out std_logic;
         o_DONE2           : out std_logic;
         o_error_detected  : out std_logic;
         o_error           : out std_logic_vector(39 downto 0));
end Test54_Reg_TMR;

architecture a_Test54_Reg_TMR of Test54_Reg_TMR is
   --| Declare types to store memory addresses and values to store
   type addresses is array (1 to 93) of std_logic_vector (32-1 downto 0);
   type registers is array (1 to 93) of std_logic_vector (32-1 downto 0);

   --| Declare Signals

   -- Registers to delay the ready signal and ensure address is ready to be sampled by the processor
   signal f_MEM_READY : std_logic := '0';
   signal ff_MEM_READY : std_logic := '0';

   -- Registers to store the last value of i_read and i_write
   signal f_read : std_logic := '0';
   signal f_write : std_logic := '0';

   -- Register for data output
   signal f_data : std_logic_vector(31 downto 0) := (others => '0');

   -- Register for the o_DONE output
   signal f_done : std_logic := '0';

   -- Signals to help compute branch addresses for branch instructions
   signal w_branch22_zero : std_logic_vector(31 downto 0);
   signal w_branch22_ones : std_logic_vector(31 downto 0);
   signal w_branch23_zero : std_logic_vector(31 downto 0);
   signal w_branch23_ones : std_logic_vector(31 downto 0);

   -- Registers for program counter and program flow errors
   signal f_sw_instr       : std_logic := '0'; -- Store word instruction Flag
   signal f_lw_instr       : std_logic := '0'; -- Load word instruction Flag
   signal f_br_instr       : std_logic := '0'; -- Banch instruction flag
   signal f_last_address   : std_logic_vector(31 downto 0) := (others => '0'); -- Address of last instruction
   signal f_next_address   : std_logic_vector(31 downto 0) := (others => '0'); -- Address of next instruction
   signal f_sw_address     : std_logic_vector(31 downto 0) := (others => '0'); -- Address to store word on write
   signal f_lw_address     : std_logic_vector(31 downto 0) := (others => '0'); -- Address to load word on read
   signal f_branch_address : std_logic_vector(31 downto 0) := (others => '0'); -- Address to branch to on branch instruction

   -- Registers for recovery error detection
   signal f_timeout_flag : std_logic := '0';
   signal f_recovery_flag : std_logic := '0';

   -- Register for timeout error detection
   signal f_clk_count : unsigned(9 downto 0) := (others => '0');

   -- Registers for error outputs
   signal f_error_detected : std_logic := '0'; -- Signal error detection to error buffer
   signal f_error_flag     : std_logic := '0'; -- If error detected while another is being acknowledged by the error buffer
   signal f_error          : std_logic_vector(39 downto 0) := (others => '0'); -- Error data to send to error buffer

   -- Initialize constant for timeout error detection
   constant k_timeout1 : unsigned(9 downto 0) := "0000010100";
   constant k_timeout2 : unsigned(9 downto 0) := "1111101000";

   -- Initialize constants for error types
   constant k_errA : std_logic_vector(7 downto 0) := "01000001";
   constant k_errB : std_logic_vector(7 downto 0) := "01000010";
   constant k_errC : std_logic_vector(7 downto 0) := "01000011";
   constant k_errD : std_logic_vector(7 downto 0) := "01000100";
   constant k_errE : std_logic_vector(7 downto 0) := "01000101";
   constant k_errF : std_logic_vector(7 downto 0) := "01000110";
   constant k_errG : std_logic_vector(7 downto 0) := "01000111";
   constant k_errH : std_logic_vector(7 downto 0) := "01001000";
   constant k_errI : std_logic_vector(7 downto 0) := "01001001";
   constant k_errJ : std_logic_vector(7 downto 0) := "01001010";
   constant k_errK : std_logic_vector(7 downto 0) := "01001011";
   constant k_errX : std_logic_vector(7 downto 0) := "01011000";

   -- Initialize constants for instruction opcodes
   constant k_sw_opcode : std_logic_vector (5 downto 0) := "101011";
   constant k_lw_opcode : std_logic_vector (5 downto 0) := "100011";
   constant k_bgez_bltz_opcode : std_logic_vector (5 downto 0) := "000001";
   constant k_beq_opcode : std_logic_vector (5 downto 0) := "000100";
   constant k_bne_opcode : std_logic_vector (5 downto 0) := "000101";
   constant k_blez_opcode : std_logic_vector (5 downto 0) := "000110";
   constant k_bgtz_opcode : std_logic_vector (5 downto 0) := "000111";

   -- Initialize additional constants
   constant k_zero2 : std_logic_vector (1 downto 0) := (others => '0');
   constant k_zero14 : std_logic_vector (13 downto 0) := (others => '0');
   constant k_zero16 : std_logic_vector (15 downto 0) := (others => '0');
   constant k_ones14 : std_logic_vector (13 downto 0) := (others => '1');
   constant k_four32 : std_logic_vector (31 downto 0) := "00000000000000000000000000000100";

   -- Initialize addresses
   constant k_prog : addresses := (-- Instruction Number - Memory Address
      "00000000000000000000000000000000", --    0 -    0
      "00000000000000000000000000000100", --    1 -    4
      "00000000000000000000000000001000", --    2 -    8
      "00000000000000000000000000001100", --    3 -   12
      "00000000000000000000000000010000", --    4 -   16
      "00000000000000000000000000010100", --    5 -   20
      "00000000000000000000000000011000", --    6 -   24
      "00000000000000000000000000011100", --    7 -   28
      "00000000000000000000000000100000", --    8 -   32
      "00000000000000000000000000100100", --    9 -   36
      "00000000000000000000000000101000", --   10 -   40
      "00000000000000000000000000101100", --   11 -   44
      "00000000000000000000000000110000", --   12 -   48
      "00000000000000000000000000110100", --   13 -   52
      "00000000000000000000000000111000", --   14 -   56
      "00000000000000000000000000111100", --   15 -   60
      "00000000000000000000000001000000", --   16 -   64
      "00000000000000000000000001000100", --   17 -   68
      "00000000000000000000000001001000", --   18 -   72
      "00000000000000000000000001001100", --   19 -   76
      "00000000000000000000000001010000", --   20 -   80
      "00000000000000000000000001010100", --   21 -   84
      "00000000000000000000000001011000", --   22 -   88
      "00000000000000000000000001011100", --   23 -   92
      "00000000000000000000000001100000", --   24 -   96
      "00000000000000000000000001100100", --   25 -  100
      "00000000000000000000000001101000", --   26 -  104
      "00000000000000000000000001101100", --   27 -  108
      "00000000000000000000000001110000", --   28 -  112
      "00000000000000000000000001110100", --   29 -  116
      "00000000000000000000000001111000", --   30 -  120
      "00000000000000000000000001111100", --   31 -  124
      "00000000000000000000000010000000", --   32 -  128
      "00000000000000000000000010000100", --   33 -  132
      "00000000000000000000000010001000", --   34 -  136
      "00000000000000000000000010001100", --   35 -  140
      "00000000000000000000000010010000", --   36 -  144
      "00000000000000000000000010010100", --   37 -  148
      "00000000000000000000000010011000", --   38 -  152
      "00000000000000000000000010011100", --   39 -  156
      "00000000000000000000000010100000", --   40 -  160
      "00000000000000000000000010100100", --   41 -  164
      "00000000000000000000000010101000", --   42 -  168
      "00000000000000000000000010101100", --   43 -  172
      "00000000000000000000000010110000", --   44 -  176
      "00000000000000000000000010110100", --   45 -  180
      "00000000000000000000000010111000", --   46 -  184
      "00000000000000000000000010111100", --   47 -  188
      "00000000000000000000000011000000", --   48 -  192
      "00000000000000000000000011000100", --   49 -  196
      "00000000000000000000000011001000", --   50 -  200
      "00000000000000000000000011001100", --   51 -  204
      "00000000000000000000000011010000", --   52 -  208
      "00000000000000000000000011010100", --   53 -  212
      "00000000000000000000000011011000", --   54 -  216
      "00000000000000000000000011011100", --   55 -  220
      "00000000000000000000000011100000", --   56 -  224
      "00000000000000000000000011100100", --   57 -  228
      "00000000000000000000000011101000", --   58 -  232
      "00000000000000000000000011101100", --   59 -  236
      "00000000000000000000000011110000", --   60 -  240
      "00000000000000000000000011110100", --   61 -  244
      "00000000000000000000000011111000", --   62 -  248
      "00000000000000000000000011111100", --   63 -  252
      "00000000000000000000000100000000", --   64 -  256
      "00000000000000000000000100000100", --   65 -  260
      "00000000000000000000000100001000", --   66 -  264
      "00000000000000000000000100001100", --   67 -  268
      "00000000000000000000000100010000", --   68 -  272
      "00000000000000000000000100010100", --   69 -  276
      "00000000000000000000000100011000", --   70 -  280
      "00000000000000000000000100011100", --   71 -  284
      "00000000000000000000000100100000", --   72 -  288
      "00000000000000000000000100100100", --   73 -  292
      "00000000000000000000000100101000", --   74 -  296
      "00000000000000000000000100101100", --   75 -  300
      "00000000000000000000000100110000", --   76 -  304
      "00000000000000000000000100110100", --   77 -  308
      "00000000000000000000000100111000", --   78 -  312
      "00000000000000000000000100111100", --   79 -  316
      "00000000000000000000000101000000", --   80 -  320
      "00000000000000000000000101000100", --   81 -  324
      "00000000000000000000000101001000", --   82 -  328
      "00000000000000000000000101001100", --   83 -  332
      "00000000000000000000000101010000", --   84 -  336
      "00000000000000000000000101010100", --   85 -  340
      "00000000000000000000000101011000", --   86 -  344
      "00000000000000000000000101011100", --   87 -  348
      "00000000000000000000000101100000", --   88 -  352
      "00000000000000000000000101100100", --   89 -  356
      "00000000000000000000000101101000", --   90 -  360
      "00000000000000000000000101101100", --   91 -  364
      "00000000000000000000000101110000");--   92 -  368

   --| Initialize values stored in memory
   signal f_reg: registers := (-- Instruction Number - Memory Address
      "00111100000111110000001111100111", --    0 -    0
      "00000000000111111111110000000010", --    1 -    4
      "00111100000000010000101111110000", --    2 -    8
      "00000000000000000001001100000011", --    3 -   12
      "00000000010000100001100000100111", --    4 -   16
      "00000000000000000010001110000011", --    5 -   20
      "00000000000000000000000000000000", --    6 -   24
      "00110000100001010011101101010110", --    7 -   28
      "00000000011001010011000000100011", --    8 -   32
      "10101100000000110000000001011100", --    9 -   36
      "00110100110001110100010111100111", --   10 -   40
      "00111100000010001001100100001101", --   11 -   44
      "00000001000000110100100000101010", --   12 -   48
      "00111001001010100000100011001100", --   13 -   52
      "00100101010010110100010110110011", --   14 -   56
      "10101100000001110000000001100000", --   15 -   60
      "00111001011011001111101110111111", --   16 -   64
      "00000000000000000000000000000000", --   17 -   68
      "10101100000011000000000001100100", --   18 -   72
      "10101100000000010000000001101000", --   19 -   76
      "00100011111111111111111111111111", --   20 -   80
      "00011111111000001111111111101101", --   21 -   84
      "00010000000000000000000001000110", --   22 -   88
      "00000000000000000000000000000000", --   23 -   92
      "00000000000000000000000000000000", --   24 -   96
      "00000000000000000000000000000000", --   25 -  100
      "00000000000000000000000000000000", --   26 -  104
      "00000000000000000000000000000000", --   27 -  108
      "00000000000000000000000000000000", --   28 -  112
      "00000000000000000000000000000000", --   29 -  116
      "00000000000000000000000000000000", --   30 -  120
      "00000000000000000000000000000000", --   31 -  124
      "00000000000000000000000000000000", --   32 -  128
      "00000000000000000000000000000000", --   33 -  132
      "00000000000000000000000000000000", --   34 -  136
      "00000000000000000000000000000000", --   35 -  140
      "00000000000000000000000000000000", --   36 -  144
      "00000000000000000000000000000000", --   37 -  148
      "00000000000000000000000000000000", --   38 -  152
      "00000000000000000000000000000000", --   39 -  156
      "00000000000000000000000000000000", --   40 -  160
      "00000000000000000000000000000000", --   41 -  164
      "00000000000000000000000000000000", --   42 -  168
      "00000000000000000000000000000000", --   43 -  172
      "00000000000000000000000000000000", --   44 -  176
      "00000000000000000000000000000000", --   45 -  180
      "00000000000000000000000000000000", --   46 -  184
      "00000000000000000000000000000000", --   47 -  188
      "00000000000000000000000000000000", --   48 -  192
      "00000000000000000000000000000000", --   49 -  196
      "00000000000000000000000000000000", --   50 -  200
      "00000000000000000000000000000000", --   51 -  204
      "00000000000000000000000000000000", --   52 -  208
      "00000000000000000000000000000000", --   53 -  212
      "00000000000000000000000000000000", --   54 -  216
      "00000000000000000000000000000000", --   55 -  220
      "00000000000000000000000000000000", --   56 -  224
      "00000000000000000000001111100111", --   57 -  228
      "00000000000000000000000000000000", --   58 -  232
      "00000000000000000000000000000000", --   59 -  236
      "00000000000000000000000000000000", --   60 -  240
      "00000000000000000000000000000000", --   61 -  244
      "00000000000000000000000000000000", --   62 -  248
      "00000000000000000000000000000000", --   63 -  252
      "00000000000000000000000000000000", --   64 -  256
      "00000000000000000000000000000000", --   65 -  260
      "00000000000000000000000000000000", --   66 -  264
      "00000000000000000000000000000000", --   67 -  268
      "00000000000000000000000000000000", --   68 -  272
      "00000000000000000000000000000000", --   69 -  276
      "00000000000000000000000000000000", --   70 -  280
      "00000000000000000000000000000000", --   71 -  284
      "00000000000000000000000000000000", --   72 -  288
      "00000000000000000000000000000000", --   73 -  292
      "00000000000000000000000000000000", --   74 -  296
      "00000000000000000000000000000000", --   75 -  300
      "00000000000000000000000000000000", --   76 -  304
      "00000000000000000000000000000000", --   77 -  308
      "00000000000000000000000000000000", --   78 -  312
      "00000000000000000000000000000000", --   79 -  316
      "00000000000000000000000000000000", --   80 -  320
      "00000000000000000000000000000000", --   81 -  324
      "00000000000000000000000000000000", --   82 -  328
      "00000000000000000000000000000000", --   83 -  332
      "00000000000000000000000000000000", --   84 -  336
      "00000000000000000000000000000000", --   85 -  340
      "00000000000000000000000000000000", --   86 -  344
      "00000000000000000000000000000000", --   87 -  348
      "00000000000000000000000000000000", --   88 -  352
      "00000000000000000000000000000000", --   89 -  356
      "00000000000000000000000000000000", --   90 -  360
      "00000000000000000000000000000000", --   91 -  364
      "00000000000000000000000000000000");--   92 -  368

begin
   -- Assign output signals
   o_MEM_READY <= ff_MEM_READY;
   o_DONE <= f_DONE;
   o_DONE2 <= f_DONE;
   o_error <= f_error;
   o_error_detected <= f_error_detected;
   o_data <= f_data;

   -- Assign signals that help compute branch addresses for branch instructions
   w_branch22_zero <= k_zero14 & std_logic_vector(f_reg(22)(15 downto 0)) & k_zero2;
   w_branch22_ones <= k_ones14 & std_logic_vector(f_reg(22)(15 downto 0)) & k_zero2;
   w_branch23_zero <= k_zero14 & std_logic_vector(f_reg(23)(15 downto 0)) & k_zero2;
   w_branch23_ones <= k_ones14 & std_logic_vector(f_reg(23)(15 downto 0)) & k_zero2;

   mem_read_process : process (i_clk, i_reset, i_read_enable, i_write_enable)
   begin
      -- When the reset signal is asserted
      if (i_reset = '1') then
         f_done <= '0';
         f_data <= (others => '0');
         f_MEM_READY <= '0';
         ff_MEM_READY <= '0';
         f_read <= '0';
         f_write <= '0';
         f_sw_instr <= '0';
         f_lw_instr <= '0';
         f_br_instr <= '0';
         f_last_address <= (others => '0');
         f_next_address <= (others => '0');
         f_sw_address <= (others => '0');
         f_lw_address <= (others => '0');
         f_branch_address <= (others => '0');
         f_error_detected <= '0';
         f_error_flag <= '0';
         f_error <= (others => '0');
         f_clk_count <= (others => '0');
         f_timeout_flag <= '0';
         f_recovery_flag <= '0';
         f_reg(1) <= "00111100000111110000001111100111";
         f_reg(2) <= "00000000000111111111110000000010";
         f_reg(3) <= "00111100000000010000101111110000";
         f_reg(4) <= "00000000000000000001001100000011";
         f_reg(5) <= "00000000010000100001100000100111";
         f_reg(6) <= "00000000000000000010001110000011";
         f_reg(7) <= "00000000000000000000000000000000";
         f_reg(8) <= "00110000100001010011101101010110";
         f_reg(9) <= "00000000011001010011000000100011";
         f_reg(10) <= "10101100000000110000000001011100";
         f_reg(11) <= "00110100110001110100010111100111";
         f_reg(12) <= "00111100000010001001100100001101";
         f_reg(13) <= "00000001000000110100100000101010";
         f_reg(14) <= "00111001001010100000100011001100";
         f_reg(15) <= "00100101010010110100010110110011";
         f_reg(16) <= "10101100000001110000000001100000";
         f_reg(17) <= "00111001011011001111101110111111";
         f_reg(18) <= "00000000000000000000000000000000";
         f_reg(19) <= "10101100000011000000000001100100";
         f_reg(20) <= "10101100000000010000000001101000";
         f_reg(21) <= "00100011111111111111111111111111";
         f_reg(22) <= "00011111111000001111111111101101";
         f_reg(23) <= "00010000000000000000000001000110";
         f_reg(24) <= "00000000000000000000000000000000";
         f_reg(25) <= "00000000000000000000000000000000";
         f_reg(26) <= "00000000000000000000000000000000";
         f_reg(27) <= "00000000000000000000000000000000";
         f_reg(28) <= "00000000000000000000000000000000";
         f_reg(29) <= "00000000000000000000000000000000";
         f_reg(30) <= "00000000000000000000000000000000";
         f_reg(31) <= "00000000000000000000000000000000";
         f_reg(32) <= "00000000000000000000000000000000";
         f_reg(33) <= "00000000000000000000000000000000";
         f_reg(34) <= "00000000000000000000000000000000";
         f_reg(35) <= "00000000000000000000000000000000";
         f_reg(36) <= "00000000000000000000000000000000";
         f_reg(37) <= "00000000000000000000000000000000";
         f_reg(38) <= "00000000000000000000000000000000";
         f_reg(39) <= "00000000000000000000000000000000";
         f_reg(40) <= "00000000000000000000000000000000";
         f_reg(41) <= "00000000000000000000000000000000";
         f_reg(42) <= "00000000000000000000000000000000";
         f_reg(43) <= "00000000000000000000000000000000";
         f_reg(44) <= "00000000000000000000000000000000";
         f_reg(45) <= "00000000000000000000000000000000";
         f_reg(46) <= "00000000000000000000000000000000";
         f_reg(47) <= "00000000000000000000000000000000";
         f_reg(48) <= "00000000000000000000000000000000";
         f_reg(49) <= "00000000000000000000000000000000";
         f_reg(50) <= "00000000000000000000000000000000";
         f_reg(51) <= "00000000000000000000000000000000";
         f_reg(52) <= "00000000000000000000000000000000";
         f_reg(53) <= "00000000000000000000000000000000";
         f_reg(54) <= "00000000000000000000000000000000";
         f_reg(55) <= "00000000000000000000000000000000";
         f_reg(56) <= "00000000000000000000000000000000";
         f_reg(57) <= "00000000000000000000000000000000";
         f_reg(58) <= "00000000000000000000001111100111";
         f_reg(59) <= "00000000000000000000000000000000";
         f_reg(60) <= "00000000000000000000000000000000";
         f_reg(61) <= "00000000000000000000000000000000";
         f_reg(62) <= "00000000000000000000000000000000";
         f_reg(63) <= "00000000000000000000000000000000";
         f_reg(64) <= "00000000000000000000000000000000";
         f_reg(65) <= "00000000000000000000000000000000";
         f_reg(66) <= "00000000000000000000000000000000";
         f_reg(67) <= "00000000000000000000000000000000";
         f_reg(68) <= "00000000000000000000000000000000";
         f_reg(69) <= "00000000000000000000000000000000";
         f_reg(70) <= "00000000000000000000000000000000";
         f_reg(71) <= "00000000000000000000000000000000";
         f_reg(72) <= "00000000000000000000000000000000";
         f_reg(73) <= "00000000000000000000000000000000";
         f_reg(74) <= "00000000000000000000000000000000";
         f_reg(75) <= "00000000000000000000000000000000";
         f_reg(76) <= "00000000000000000000000000000000";
         f_reg(77) <= "00000000000000000000000000000000";
         f_reg(78) <= "00000000000000000000000000000000";
         f_reg(79) <= "00000000000000000000000000000000";
         f_reg(80) <= "00000000000000000000000000000000";
         f_reg(81) <= "00000000000000000000000000000000";
         f_reg(82) <= "00000000000000000000000000000000";
         f_reg(83) <= "00000000000000000000000000000000";
         f_reg(84) <= "00000000000000000000000000000000";
         f_reg(85) <= "00000000000000000000000000000000";
         f_reg(86) <= "00000000000000000000000000000000";
         f_reg(87) <= "00000000000000000000000000000000";
         f_reg(88) <= "00000000000000000000000000000000";
         f_reg(89) <= "00000000000000000000000000000000";
         f_reg(90) <= "00000000000000000000000000000000";
         f_reg(91) <= "00000000000000000000000000000000";
         f_reg(92) <= "00000000000000000000000000000000";
      -- At every rising clock edge
      elsif rising_edge(i_clk) then
         if (f_DONE = '0') then
            ff_MEM_READY <= f_MEM_READY;

            -- When attempting to read from memory
            if (i_read_enable = '1') then
               case i_address is
                  when k_prog(1) =>
                     -- LUI R31 999
                     f_data <= f_reg(1);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(2) =>
                     -- SRL R31 R31 16
                     f_data <= f_reg(2);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(3) =>
                     -- LUI R1 3056
                     f_data <= f_reg(3);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(4) =>
                     -- SRA R2 R0 12
                     f_data <= f_reg(4);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(5) =>
                     -- NOR R3 R2 R2
                     f_data <= f_reg(5);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(6) =>
                     -- SRA R4 R0 14
                     f_data <= f_reg(6);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(7) =>
                     -- NOP
                     f_data <= f_reg(7);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(8) =>
                     -- ANDI R5 R4 15190
                     f_data <= f_reg(8);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(9) =>
                     -- SUBU R6 R3 R5
                     f_data <= f_reg(9);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(10) =>
                     -- SW R3 R0 92
                     f_data <= f_reg(10);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the sw address
                           f_sw_instr <= f_sw_instr;
                           f_sw_address <= k_zero16 & f_reg(10)(15 downto 0);

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the sw address
                           f_sw_instr <= '1';
                           f_br_instr <= '0';
                           f_sw_address <= k_zero16 & f_reg(10)(15 downto 0);

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the sw address
                           f_sw_instr <= '1';
                           f_sw_address <= k_zero16 & f_reg(10)(15 downto 0);

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the sw address
                           f_sw_instr <= '1';
                           f_sw_address <= k_zero16 & f_reg(10)(15 downto 0);

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(11) =>
                     -- ORI R7 R6 17895
                     f_data <= f_reg(11);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(12) =>
                     -- LUI R8 -26355
                     f_data <= f_reg(12);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(13) =>
                     -- SLT R9 R8 R3
                     f_data <= f_reg(13);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(14) =>
                     -- XORI R10 R9 2252
                     f_data <= f_reg(14);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(15) =>
                     -- ADDIU R11 R10 17843
                     f_data <= f_reg(15);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(16) =>
                     -- SW R7 R0 96
                     f_data <= f_reg(16);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the sw address
                           f_sw_instr <= f_sw_instr;
                           f_sw_address <= k_zero16 & f_reg(16)(15 downto 0);

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the sw address
                           f_sw_instr <= '1';
                           f_br_instr <= '0';
                           f_sw_address <= k_zero16 & f_reg(16)(15 downto 0);

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the sw address
                           f_sw_instr <= '1';
                           f_sw_address <= k_zero16 & f_reg(16)(15 downto 0);

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the sw address
                           f_sw_instr <= '1';
                           f_sw_address <= k_zero16 & f_reg(16)(15 downto 0);

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(17) =>
                     -- XORI R12 R11 -1089
                     f_data <= f_reg(17);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(18) =>
                     -- NOP
                     f_data <= f_reg(18);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(19) =>
                     -- SW R12 R0 100
                     f_data <= f_reg(19);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the sw address
                           f_sw_instr <= f_sw_instr;
                           f_sw_address <= k_zero16 & f_reg(19)(15 downto 0);

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the sw address
                           f_sw_instr <= '1';
                           f_br_instr <= '0';
                           f_sw_address <= k_zero16 & f_reg(19)(15 downto 0);

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the sw address
                           f_sw_instr <= '1';
                           f_sw_address <= k_zero16 & f_reg(19)(15 downto 0);

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the sw address
                           f_sw_instr <= '1';
                           f_sw_address <= k_zero16 & f_reg(19)(15 downto 0);

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(20) =>
                     -- SW R1 R0 104
                     f_data <= f_reg(20);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the sw address
                           f_sw_instr <= f_sw_instr;
                           f_sw_address <= k_zero16 & f_reg(20)(15 downto 0);

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the sw address
                           f_sw_instr <= '1';
                           f_br_instr <= '0';
                           f_sw_address <= k_zero16 & f_reg(20)(15 downto 0);

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the sw address
                           f_sw_instr <= '1';
                           f_sw_address <= k_zero16 & f_reg(20)(15 downto 0);

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the sw address
                           f_sw_instr <= '1';
                           f_sw_address <= k_zero16 & f_reg(20)(15 downto 0);

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(21) =>
                     -- ADDI R31 R31 -1
                     f_data <= f_reg(21);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(22) =>
                     -- BGTZ R31 -19
                     f_data <= f_reg(22);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the branch address
                           f_br_instr <= '1';
                           f_sw_instr <= '0';
                           if (f_reg(22)(15) = '0') then
                              f_branch_address <= std_logic_vector((unsigned(i_address)) + (unsigned(w_branch22_zero)));
                           else
                              f_branch_address <= std_logic_vector((unsigned(i_address)) + (unsigned(w_branch22_ones)));
                           end if;

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= f_br_instr;
                           -- Determine the branch address
                           if (f_reg(22)(15) = '0') then
                              f_branch_address <= std_logic_vector((unsigned(i_address)) + (unsigned(w_branch22_zero)));
                           else
                              f_branch_address <= std_logic_vector((unsigned(i_address)) + (unsigned(w_branch22_ones)));
                           end if;

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the branch address
                           f_br_instr <= '1';
                           if (f_reg(22)(15) = '0') then
                              f_branch_address <= std_logic_vector((unsigned(i_address)) + (unsigned(w_branch22_zero)));
                           else
                              f_branch_address <= std_logic_vector((unsigned(i_address)) + (unsigned(w_branch22_ones)));
                           end if;

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the branch address
                           f_br_instr <= '1';
                           if (f_reg(22)(15) = '0') then
                              f_branch_address <= std_logic_vector((unsigned(i_address)) + (unsigned(w_branch22_zero)));
                           else
                              f_branch_address <= std_logic_vector((unsigned(i_address)) + (unsigned(w_branch22_ones)));
                           end if;

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(23) =>
                     -- BEQ R0 R0 70
                     f_data <= f_reg(23);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the branch address
                           f_br_instr <= '1';
                           f_sw_instr <= '0';
                           if (f_reg(23)(15) = '0') then
                              f_branch_address <= std_logic_vector((unsigned(i_address)) + (unsigned(w_branch23_zero)));
                           else
                              f_branch_address <= std_logic_vector((unsigned(i_address)) + (unsigned(w_branch23_ones)));
                           end if;

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= f_br_instr;
                           -- Determine the branch address
                           if (f_reg(23)(15) = '0') then
                              f_branch_address <= std_logic_vector((unsigned(i_address)) + (unsigned(w_branch23_zero)));
                           else
                              f_branch_address <= std_logic_vector((unsigned(i_address)) + (unsigned(w_branch23_ones)));
                           end if;

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the branch address
                           f_br_instr <= '1';
                           if (f_reg(23)(15) = '0') then
                              f_branch_address <= std_logic_vector((unsigned(i_address)) + (unsigned(w_branch23_zero)));
                           else
                              f_branch_address <= std_logic_vector((unsigned(i_address)) + (unsigned(w_branch23_ones)));
                           end if;

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           -- Determine the branch address
                           f_br_instr <= '1';
                           if (f_reg(23)(15) = '0') then
                              f_branch_address <= std_logic_vector((unsigned(i_address)) + (unsigned(w_branch23_zero)));
                           else
                              f_branch_address <= std_logic_vector((unsigned(i_address)) + (unsigned(w_branch23_ones)));
                           end if;

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(24) =>
                     -- NOP
                     f_data <= f_reg(24);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(25) =>
                     -- NOP
                     f_data <= f_reg(25);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(26) =>
                     -- NOP
                     f_data <= f_reg(26);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(27) =>
                     -- NOP
                     f_data <= f_reg(27);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        f_last_address <= i_address;
                        f_recovery_flag <= '0';
                        -- Check for previous instruction being a store word instruction
                        -- The processor should be attempting to write to the processor,
                        -- but is attempting to read instead.  An error has occured
                        if (f_sw_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_sw_instr <= '0';

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errA & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errA & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- Check for previous instruction being a load word instruction
                        elsif (f_lw_instr = '1') then
                           -- The next address should not be updated since it previously
                           -- referened the next instruction and not the next address to
                           -- be read from memory by the load word instruction.  Set load
                           -- word instruction flag to 0.
                           f_lw_instr <= '0';
                           -- Check to see if the f_lw_address matches the current address
                           -- There is no error if the addresses match
                           if (f_lw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_lw_address does not match the current address.  An
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errB & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errB & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- Check for previous instruction being a branch instruction
                        elsif (f_br_instr = '1') then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));
                           f_br_instr <= '0';

                           -- Check to see if the f_branch_address matches the current address
                           -- There is no error if the addresses match -- Branch was taken
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- Check to see if the f_next_address matches the current address
                           -- There is no error if the addresses match -- Branch was not taken
                           elsif (f_next_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;

                           -- The f_next_address and f_branch_address do not match the current
                           -- address.  An error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errC & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errC & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address = the current address, no error
                        elsif (f_next_address = i_address) then
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        -- The previous instruction was not a store word,
                        -- load word, or branch instruction.  If next
                        -- address ~= the current address, an error occured
                        else
                           -- Determine the next address
                           f_next_address <= std_logic_vector((unsigned(i_address)) + (unsigned(k_four32)));

                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errD & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errD & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(28) =>
                     -- NOP
                     f_data <= f_reg(28);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(29) =>
                     -- NOP
                     f_data <= f_reg(29);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(30) =>
                     -- NOP
                     f_data <= f_reg(30);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(31) =>
                     -- NOP
                     f_data <= f_reg(31);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(32) =>
                     -- NOP
                     f_data <= f_reg(32);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(33) =>
                     -- NOP
                     f_data <= f_reg(33);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(34) =>
                     -- NOP
                     f_data <= f_reg(34);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(35) =>
                     -- NOP
                     f_data <= f_reg(35);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(36) =>
                     -- NOP
                     f_data <= f_reg(36);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(37) =>
                     -- NOP
                     f_data <= f_reg(37);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(38) =>
                     -- NOP
                     f_data <= f_reg(38);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(39) =>
                     -- NOP
                     f_data <= f_reg(39);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(40) =>
                     -- NOP
                     f_data <= f_reg(40);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(41) =>
                     -- NOP
                     f_data <= f_reg(41);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(42) =>
                     -- NOP
                     f_data <= f_reg(42);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(43) =>
                     -- NOP
                     f_data <= f_reg(43);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(44) =>
                     -- NOP
                     f_data <= f_reg(44);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(45) =>
                     -- NOP
                     f_data <= f_reg(45);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(46) =>
                     -- NOP
                     f_data <= f_reg(46);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(47) =>
                     -- NOP
                     f_data <= f_reg(47);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(48) =>
                     -- NOP
                     f_data <= f_reg(48);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(49) =>
                     -- NOP
                     f_data <= f_reg(49);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(50) =>
                     -- NOP
                     f_data <= f_reg(50);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(51) =>
                     -- NOP
                     f_data <= f_reg(51);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(52) =>
                     -- NOP
                     f_data <= f_reg(52);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(53) =>
                     -- NOP
                     f_data <= f_reg(53);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(54) =>
                     -- NOP
                     f_data <= f_reg(54);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(55) =>
                     -- NOP
                     f_data <= f_reg(55);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(56) =>
                     -- NOP
                     f_data <= f_reg(56);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(57) =>
                     -- NOP
                     f_data <= f_reg(57);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(58) =>
                     -- NOP
                     f_data <= f_reg(58);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(59) =>
                     -- NOP
                     f_data <= f_reg(59);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(60) =>
                     -- NOP
                     f_data <= f_reg(60);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(61) =>
                     -- NOP
                     f_data <= f_reg(61);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(62) =>
                     -- NOP
                     f_data <= f_reg(62);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(63) =>
                     -- NOP
                     f_data <= f_reg(63);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(64) =>
                     -- NOP
                     f_data <= f_reg(64);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(65) =>
                     -- NOP
                     f_data <= f_reg(65);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(66) =>
                     -- NOP
                     f_data <= f_reg(66);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(67) =>
                     -- NOP
                     f_data <= f_reg(67);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(68) =>
                     -- NOP
                     f_data <= f_reg(68);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(69) =>
                     -- NOP
                     f_data <= f_reg(69);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(70) =>
                     -- NOP
                     f_data <= f_reg(70);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(71) =>
                     -- NOP
                     f_data <= f_reg(71);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(72) =>
                     -- NOP
                     f_data <= f_reg(72);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(73) =>
                     -- NOP
                     f_data <= f_reg(73);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(74) =>
                     -- NOP
                     f_data <= f_reg(74);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(75) =>
                     -- NOP
                     f_data <= f_reg(75);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(76) =>
                     -- NOP
                     f_data <= f_reg(76);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(77) =>
                     -- NOP
                     f_data <= f_reg(77);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(78) =>
                     -- NOP
                     f_data <= f_reg(78);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(79) =>
                     -- NOP
                     f_data <= f_reg(79);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(80) =>
                     -- NOP
                     f_data <= f_reg(80);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(81) =>
                     -- NOP
                     f_data <= f_reg(81);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(82) =>
                     -- NOP
                     f_data <= f_reg(82);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(83) =>
                     -- NOP
                     f_data <= f_reg(83);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(84) =>
                     -- NOP
                     f_data <= f_reg(84);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(85) =>
                     -- NOP
                     f_data <= f_reg(85);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(86) =>
                     -- NOP
                     f_data <= f_reg(86);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(87) =>
                     -- NOP
                     f_data <= f_reg(87);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(88) =>
                     -- NOP
                     f_data <= f_reg(88);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(89) =>
                     -- NOP
                     f_data <= f_reg(89);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(90) =>
                     -- NOP
                     f_data <= f_reg(90);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(91) =>
                     -- NOP
                     f_data <= f_reg(91);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                           -- Set the next address to be the recovery address so that
                           -- an error will not occur after recovering from ERR1
                           if (f_reg(92)(0) = '1') then
                              f_next_address <= f_reg(91);
                           else
                              f_next_address <= f_reg(59);
                           end if;
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errK & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errK & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(92) =>
                     -- NOP
                     f_data <= f_reg(92);
                     f_MEM_READY <= '1';
                     f_DONE <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        f_clk_count <= (others => '0');
                        f_timeout_flag <= '0';
                        -- This memory location is part of the save/restore point
                        -- Check if the recovery flag is 0
                        if (f_recovery_flag = '0') then
                           f_recovery_flag <= '1';
                           -- LW, SW, and Branch flags should be returned to 0 when,
                           -- returning from error recovery
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';

                        -- The recovery flag has been set to 1
                        else
                           -- Check for previous error being acknowledged
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                           -- Check for previous error acknowledged and an error flag being set
                           elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                              -- Set f_error_flag back to 0 and transmit the error now
                              f_error_flag <= '0';
                              f_error_detected <= '1';
                           end if;
                        end if;
                     end if;
                  when k_prog(93) =>
                     -- End of Program
                     f_data <= B"00000000000000000000000000000000";
                     f_DONE <= '1';
                     f_MEM_READY <= '0';
                     ff_MEM_READY <= '0';
                     f_sw_instr <= '0';
                     f_lw_instr <= '0';
                     f_br_instr <= '0';
                     f_last_address <= (others => '0');
                     f_next_address <= (others => '0');
                     f_sw_address <= (others => '0');
                     f_lw_address <= (others => '0');
                     f_branch_address <= (others => '0');
                     f_error_detected <= '0';
                     f_error_flag <= '0';
                     f_error <= (others => '0');
                     f_timeout_flag <= '0';
                     f_recovery_flag <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        -- The end of the program should only be reached by executing a branch
                        -- instruction.  Check that the branch instruction flag is set
                        if (f_br_instr = '1') then
                           -- Check that the branch address matches the current address.  If not,
                           -- an error has occured
                           if (f_branch_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errE & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errE & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;
                        -- If the branch instruction flag is not set, then an error occurred
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errE & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errE & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                     f_reg(1) <= "00111100000111110000001111100111";
                     f_reg(2) <= "00000000000111111111110000000010";
                     f_reg(3) <= "00111100000000010000101111110000";
                     f_reg(4) <= "00000000000000000001001100000011";
                     f_reg(5) <= "00000000010000100001100000100111";
                     f_reg(6) <= "00000000000000000010001110000011";
                     f_reg(7) <= "00000000000000000000000000000000";
                     f_reg(8) <= "00110000100001010011101101010110";
                     f_reg(9) <= "00000000011001010011000000100011";
                     f_reg(10) <= "10101100000000110000000001011100";
                     f_reg(11) <= "00110100110001110100010111100111";
                     f_reg(12) <= "00111100000010001001100100001101";
                     f_reg(13) <= "00000001000000110100100000101010";
                     f_reg(14) <= "00111001001010100000100011001100";
                     f_reg(15) <= "00100101010010110100010110110011";
                     f_reg(16) <= "10101100000001110000000001100000";
                     f_reg(17) <= "00111001011011001111101110111111";
                     f_reg(18) <= "00000000000000000000000000000000";
                     f_reg(19) <= "10101100000011000000000001100100";
                     f_reg(20) <= "10101100000000010000000001101000";
                     f_reg(21) <= "00100011111111111111111111111111";
                     f_reg(22) <= "00011111111000001111111111101101";
                     f_reg(23) <= "00010000000000000000000001000110";
                     f_reg(24) <= "00000000000000000000000000000000";
                     f_reg(25) <= "00000000000000000000000000000000";
                     f_reg(26) <= "00000000000000000000000000000000";
                     f_reg(27) <= "00000000000000000000000000000000";
                     f_reg(28) <= "00000000000000000000000000000000";
                     f_reg(29) <= "00000000000000000000000000000000";
                     f_reg(30) <= "00000000000000000000000000000000";
                     f_reg(31) <= "00000000000000000000000000000000";
                     f_reg(32) <= "00000000000000000000000000000000";
                     f_reg(33) <= "00000000000000000000000000000000";
                     f_reg(34) <= "00000000000000000000000000000000";
                     f_reg(35) <= "00000000000000000000000000000000";
                     f_reg(36) <= "00000000000000000000000000000000";
                     f_reg(37) <= "00000000000000000000000000000000";
                     f_reg(38) <= "00000000000000000000000000000000";
                     f_reg(39) <= "00000000000000000000000000000000";
                     f_reg(40) <= "00000000000000000000000000000000";
                     f_reg(41) <= "00000000000000000000000000000000";
                     f_reg(42) <= "00000000000000000000000000000000";
                     f_reg(43) <= "00000000000000000000000000000000";
                     f_reg(44) <= "00000000000000000000000000000000";
                     f_reg(45) <= "00000000000000000000000000000000";
                     f_reg(46) <= "00000000000000000000000000000000";
                     f_reg(47) <= "00000000000000000000000000000000";
                     f_reg(48) <= "00000000000000000000000000000000";
                     f_reg(49) <= "00000000000000000000000000000000";
                     f_reg(50) <= "00000000000000000000000000000000";
                     f_reg(51) <= "00000000000000000000000000000000";
                     f_reg(52) <= "00000000000000000000000000000000";
                     f_reg(53) <= "00000000000000000000000000000000";
                     f_reg(54) <= "00000000000000000000000000000000";
                     f_reg(55) <= "00000000000000000000000000000000";
                     f_reg(56) <= "00000000000000000000000000000000";
                     f_reg(57) <= "00000000000000000000000000000000";
                     f_reg(58) <= "00000000000000000000001111100111";
                     f_reg(59) <= "00000000000000000000000000000000";
                     f_reg(60) <= "00000000000000000000000000000000";
                     f_reg(61) <= "00000000000000000000000000000000";
                     f_reg(62) <= "00000000000000000000000000000000";
                     f_reg(63) <= "00000000000000000000000000000000";
                     f_reg(64) <= "00000000000000000000000000000000";
                     f_reg(65) <= "00000000000000000000000000000000";
                     f_reg(66) <= "00000000000000000000000000000000";
                     f_reg(67) <= "00000000000000000000000000000000";
                     f_reg(68) <= "00000000000000000000000000000000";
                     f_reg(69) <= "00000000000000000000000000000000";
                     f_reg(70) <= "00000000000000000000000000000000";
                     f_reg(71) <= "00000000000000000000000000000000";
                     f_reg(72) <= "00000000000000000000000000000000";
                     f_reg(73) <= "00000000000000000000000000000000";
                     f_reg(74) <= "00000000000000000000000000000000";
                     f_reg(75) <= "00000000000000000000000000000000";
                     f_reg(76) <= "00000000000000000000000000000000";
                     f_reg(77) <= "00000000000000000000000000000000";
                     f_reg(78) <= "00000000000000000000000000000000";
                     f_reg(79) <= "00000000000000000000000000000000";
                     f_reg(80) <= "00000000000000000000000000000000";
                     f_reg(81) <= "00000000000000000000000000000000";
                     f_reg(82) <= "00000000000000000000000000000000";
                     f_reg(83) <= "00000000000000000000000000000000";
                     f_reg(84) <= "00000000000000000000000000000000";
                     f_reg(85) <= "00000000000000000000000000000000";
                     f_reg(86) <= "00000000000000000000000000000000";
                     f_reg(87) <= "00000000000000000000000000000000";
                     f_reg(88) <= "00000000000000000000000000000000";
                     f_reg(89) <= "00000000000000000000000000000000";
                     f_reg(90) <= "00000000000000000000000000000000";
                     f_reg(91) <= "00000000000000000000000000000000";
                     f_reg(92) <= "00000000000000000000000000000000";
                  when others =>
                     -- Jump to Location Outside of Program -- An error has occured
                     f_data <= B"00000000000000000000000000000000";
                     f_DONE <= '1';
                     f_MEM_READY <= '0';
                     ff_MEM_READY <= '0';
                     f_sw_instr <= '0';
                     f_lw_instr <= '0';
                     f_br_instr <= '0';
                     f_last_address <= (others => '0');
                     f_next_address <= (others => '0');
                     f_sw_address <= (others => '0');
                     f_lw_address <= (others => '0');
                     f_branch_address <= (others => '0');
                     f_error_detected <= '0';
                     f_error_flag <= '0';
                     f_error <= (others => '0');
                     f_timeout_flag <= '0';
                     f_recovery_flag <= '0';
                     if (f_read = '0') then
                        f_read <= '1';
                        -- Check for a previous error being acknowledged at the same
                        -- time this error is detected.
                        if ((f_error_detected = '1') and (i_ack = '1')) then
                           -- Return error detected to 0 so i_ack will return to 0
                           f_error_detected <= '0';
                           -- Set error flag so this error can be transmitted as
                           -- soon as i_ack returns to 0
                           f_error_flag <= '1';
                           -- Set new error value
                           f_error <= k_errF & f_last_address;

                        -- If there is no error or if there is an unacknowledged
                        -- error.  Unacknowledged errors will be lost because the
                        -- error buffer is currently full
                        else
                           f_error_detected <= '1';
                           f_error <= k_errF & f_last_address; 
                           -- If there is an error flag, then the error associated
                           -- with it is lost.
                           f_error_flag <= '0';
                        end if;
                     end if;
                     f_reg(1) <= "00111100000111110000001111100111";
                     f_reg(2) <= "00000000000111111111110000000010";
                     f_reg(3) <= "00111100000000010000101111110000";
                     f_reg(4) <= "00000000000000000001001100000011";
                     f_reg(5) <= "00000000010000100001100000100111";
                     f_reg(6) <= "00000000000000000010001110000011";
                     f_reg(7) <= "00000000000000000000000000000000";
                     f_reg(8) <= "00110000100001010011101101010110";
                     f_reg(9) <= "00000000011001010011000000100011";
                     f_reg(10) <= "10101100000000110000000001011100";
                     f_reg(11) <= "00110100110001110100010111100111";
                     f_reg(12) <= "00111100000010001001100100001101";
                     f_reg(13) <= "00000001000000110100100000101010";
                     f_reg(14) <= "00111001001010100000100011001100";
                     f_reg(15) <= "00100101010010110100010110110011";
                     f_reg(16) <= "10101100000001110000000001100000";
                     f_reg(17) <= "00111001011011001111101110111111";
                     f_reg(18) <= "00000000000000000000000000000000";
                     f_reg(19) <= "10101100000011000000000001100100";
                     f_reg(20) <= "10101100000000010000000001101000";
                     f_reg(21) <= "00100011111111111111111111111111";
                     f_reg(22) <= "00011111111000001111111111101101";
                     f_reg(23) <= "00010000000000000000000001000110";
                     f_reg(24) <= "00000000000000000000000000000000";
                     f_reg(25) <= "00000000000000000000000000000000";
                     f_reg(26) <= "00000000000000000000000000000000";
                     f_reg(27) <= "00000000000000000000000000000000";
                     f_reg(28) <= "00000000000000000000000000000000";
                     f_reg(29) <= "00000000000000000000000000000000";
                     f_reg(30) <= "00000000000000000000000000000000";
                     f_reg(31) <= "00000000000000000000000000000000";
                     f_reg(32) <= "00000000000000000000000000000000";
                     f_reg(33) <= "00000000000000000000000000000000";
                     f_reg(34) <= "00000000000000000000000000000000";
                     f_reg(35) <= "00000000000000000000000000000000";
                     f_reg(36) <= "00000000000000000000000000000000";
                     f_reg(37) <= "00000000000000000000000000000000";
                     f_reg(38) <= "00000000000000000000000000000000";
                     f_reg(39) <= "00000000000000000000000000000000";
                     f_reg(40) <= "00000000000000000000000000000000";
                     f_reg(41) <= "00000000000000000000000000000000";
                     f_reg(42) <= "00000000000000000000000000000000";
                     f_reg(43) <= "00000000000000000000000000000000";
                     f_reg(44) <= "00000000000000000000000000000000";
                     f_reg(45) <= "00000000000000000000000000000000";
                     f_reg(46) <= "00000000000000000000000000000000";
                     f_reg(47) <= "00000000000000000000000000000000";
                     f_reg(48) <= "00000000000000000000000000000000";
                     f_reg(49) <= "00000000000000000000000000000000";
                     f_reg(50) <= "00000000000000000000000000000000";
                     f_reg(51) <= "00000000000000000000000000000000";
                     f_reg(52) <= "00000000000000000000000000000000";
                     f_reg(53) <= "00000000000000000000000000000000";
                     f_reg(54) <= "00000000000000000000000000000000";
                     f_reg(55) <= "00000000000000000000000000000000";
                     f_reg(56) <= "00000000000000000000000000000000";
                     f_reg(57) <= "00000000000000000000000000000000";
                     f_reg(58) <= "00000000000000000000001111100111";
                     f_reg(59) <= "00000000000000000000000000000000";
                     f_reg(60) <= "00000000000000000000000000000000";
                     f_reg(61) <= "00000000000000000000000000000000";
                     f_reg(62) <= "00000000000000000000000000000000";
                     f_reg(63) <= "00000000000000000000000000000000";
                     f_reg(64) <= "00000000000000000000000000000000";
                     f_reg(65) <= "00000000000000000000000000000000";
                     f_reg(66) <= "00000000000000000000000000000000";
                     f_reg(67) <= "00000000000000000000000000000000";
                     f_reg(68) <= "00000000000000000000000000000000";
                     f_reg(69) <= "00000000000000000000000000000000";
                     f_reg(70) <= "00000000000000000000000000000000";
                     f_reg(71) <= "00000000000000000000000000000000";
                     f_reg(72) <= "00000000000000000000000000000000";
                     f_reg(73) <= "00000000000000000000000000000000";
                     f_reg(74) <= "00000000000000000000000000000000";
                     f_reg(75) <= "00000000000000000000000000000000";
                     f_reg(76) <= "00000000000000000000000000000000";
                     f_reg(77) <= "00000000000000000000000000000000";
                     f_reg(78) <= "00000000000000000000000000000000";
                     f_reg(79) <= "00000000000000000000000000000000";
                     f_reg(80) <= "00000000000000000000000000000000";
                     f_reg(81) <= "00000000000000000000000000000000";
                     f_reg(82) <= "00000000000000000000000000000000";
                     f_reg(83) <= "00000000000000000000000000000000";
                     f_reg(84) <= "00000000000000000000000000000000";
                     f_reg(85) <= "00000000000000000000000000000000";
                     f_reg(86) <= "00000000000000000000000000000000";
                     f_reg(87) <= "00000000000000000000000000000000";
                     f_reg(88) <= "00000000000000000000000000000000";
                     f_reg(89) <= "00000000000000000000000000000000";
                     f_reg(90) <= "00000000000000000000000000000000";
                     f_reg(91) <= "00000000000000000000000000000000";
                     f_reg(92) <= "00000000000000000000000000000000";
               end case;

            -- When attempting to write to memory
            elsif (i_write_enable = '1') then
               f_clk_count <= (others => '0');
               f_timeout_flag <= '0';
               case i_address is
                  when k_prog(1) =>
                     -- LUI R31 999
                     f_reg(1) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(2) =>
                     -- SRL R31 R31 16
                     f_reg(2) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(3) =>
                     -- LUI R1 3056
                     f_reg(3) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(4) =>
                     -- SRA R2 R0 12
                     f_reg(4) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(5) =>
                     -- NOR R3 R2 R2
                     f_reg(5) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(6) =>
                     -- SRA R4 R0 14
                     f_reg(6) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(7) =>
                     -- NOP
                     f_reg(7) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(8) =>
                     -- ANDI R5 R4 15190
                     f_reg(8) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(9) =>
                     -- SUBU R6 R3 R5
                     f_reg(9) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(10) =>
                     -- SW R3 R0 92
                     f_reg(10) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(11) =>
                     -- ORI R7 R6 17895
                     f_reg(11) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(12) =>
                     -- LUI R8 -26355
                     f_reg(12) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(13) =>
                     -- SLT R9 R8 R3
                     f_reg(13) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(14) =>
                     -- XORI R10 R9 2252
                     f_reg(14) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(15) =>
                     -- ADDIU R11 R10 17843
                     f_reg(15) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(16) =>
                     -- SW R7 R0 96
                     f_reg(16) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(17) =>
                     -- XORI R12 R11 -1089
                     f_reg(17) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(18) =>
                     -- NOP
                     f_reg(18) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(19) =>
                     -- SW R12 R0 100
                     f_reg(19) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(20) =>
                     -- SW R1 R0 104
                     f_reg(20) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(21) =>
                     -- ADDI R31 R31 -1
                     f_reg(21) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(22) =>
                     -- BGTZ R31 -19
                     f_reg(22) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(23) =>
                     -- BEQ R0 R0 70
                     f_reg(23) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(24) =>
                     -- NOP
                     f_reg(24) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(25) =>
                     -- NOP
                     f_reg(25) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(26) =>
                     -- NOP
                     f_reg(26) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(27) =>
                     -- NOP
                     f_reg(27) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- If the last instruction was not a store word instruction,
                        -- the processor should not be attempting to write to memory
                        else
                           -- Check for a previous error being acknowledged at the same
                           -- time this error is detected.
                           if ((f_error_detected = '1') and (i_ack = '1')) then
                              -- Return error detected to 0 so i_ack will return to 0
                              f_error_detected <= '0';
                              -- Set error flag so this error can be transmitted as
                              -- soon as i_ack returns to 0
                              f_error_flag <= '1';
                              -- Set new error value
                              f_error <= k_errH & f_last_address;

                           -- If there is no error or if there is an unacknowledged
                           -- error.  Unacknowledged errors will be lost because the
                           -- error buffer is currently full
                           else
                              f_error_detected <= '1';
                              f_error <= k_errH & f_last_address; 
                              -- If there is an error flag, then the error associated
                              -- with it is lost.
                              f_error_flag <= '0';
                           end if;
                        end if;
                     end if;
                  when k_prog(28) =>
                     -- NOP
                     f_reg(28) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(29) =>
                     -- NOP
                     f_reg(29) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(30) =>
                     -- NOP
                     f_reg(30) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(31) =>
                     -- NOP
                     f_reg(31) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(32) =>
                     -- NOP
                     f_reg(32) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(33) =>
                     -- NOP
                     f_reg(33) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(34) =>
                     -- NOP
                     f_reg(34) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(35) =>
                     -- NOP
                     f_reg(35) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(36) =>
                     -- NOP
                     f_reg(36) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(37) =>
                     -- NOP
                     f_reg(37) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(38) =>
                     -- NOP
                     f_reg(38) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(39) =>
                     -- NOP
                     f_reg(39) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(40) =>
                     -- NOP
                     f_reg(40) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(41) =>
                     -- NOP
                     f_reg(41) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(42) =>
                     -- NOP
                     f_reg(42) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(43) =>
                     -- NOP
                     f_reg(43) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(44) =>
                     -- NOP
                     f_reg(44) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(45) =>
                     -- NOP
                     f_reg(45) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(46) =>
                     -- NOP
                     f_reg(46) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(47) =>
                     -- NOP
                     f_reg(47) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(48) =>
                     -- NOP
                     f_reg(48) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(49) =>
                     -- NOP
                     f_reg(49) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(50) =>
                     -- NOP
                     f_reg(50) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(51) =>
                     -- NOP
                     f_reg(51) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(52) =>
                     -- NOP
                     f_reg(52) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(53) =>
                     -- NOP
                     f_reg(53) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(54) =>
                     -- NOP
                     f_reg(54) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(55) =>
                     -- NOP
                     f_reg(55) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(56) =>
                     -- NOP
                     f_reg(56) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(57) =>
                     -- NOP
                     f_reg(57) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(58) =>
                     -- NOP
                     f_reg(58) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(59) =>
                     -- NOP
                     f_reg(59) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(60) =>
                     -- NOP
                     f_reg(60) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(61) =>
                     -- NOP
                     f_reg(61) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(62) =>
                     -- NOP
                     f_reg(62) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(63) =>
                     -- NOP
                     f_reg(63) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(64) =>
                     -- NOP
                     f_reg(64) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(65) =>
                     -- NOP
                     f_reg(65) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(66) =>
                     -- NOP
                     f_reg(66) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(67) =>
                     -- NOP
                     f_reg(67) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(68) =>
                     -- NOP
                     f_reg(68) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(69) =>
                     -- NOP
                     f_reg(69) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(70) =>
                     -- NOP
                     f_reg(70) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(71) =>
                     -- NOP
                     f_reg(71) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(72) =>
                     -- NOP
                     f_reg(72) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(73) =>
                     -- NOP
                     f_reg(73) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(74) =>
                     -- NOP
                     f_reg(74) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(75) =>
                     -- NOP
                     f_reg(75) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(76) =>
                     -- NOP
                     f_reg(76) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(77) =>
                     -- NOP
                     f_reg(77) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(78) =>
                     -- NOP
                     f_reg(78) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(79) =>
                     -- NOP
                     f_reg(79) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(80) =>
                     -- NOP
                     f_reg(80) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(81) =>
                     -- NOP
                     f_reg(81) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(82) =>
                     -- NOP
                     f_reg(82) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(83) =>
                     -- NOP
                     f_reg(83) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(84) =>
                     -- NOP
                     f_reg(84) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(85) =>
                     -- NOP
                     f_reg(85) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(86) =>
                     -- NOP
                     f_reg(86) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(87) =>
                     -- NOP
                     f_reg(87) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(88) =>
                     -- NOP
                     f_reg(88) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(89) =>
                     -- NOP
                     f_reg(89) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(90) =>
                     -- NOP
                     f_reg(90) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(91) =>
                     -- NOP
                     f_reg(91) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(92) =>
                     -- NOP
                     f_reg(92) <= i_data;
                     f_MEM_READY <= '1';
                     f_done <= '0';
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for last instruction being a store word instruction
                        if (f_sw_instr = '1') then
                           f_sw_instr <= '0';
                           -- Check that the f_sw_address matches the current address
                           if (f_sw_address = i_address) then
                              -- Check for previous error being acknowledged
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                              -- Check for previous error acknowledged and an error flag being set
                              elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                                 -- Set f_error_flag back to 0 and transmit the error now
                                 f_error_flag <= '0';
                                 f_error_detected <= '1';
                              end if;
                           -- If the f_sw_address does not match the current address, an
                           -- error has occured
                           else
                              -- Check for a previous error being acknowledged at the same
                              -- time this error is detected.
                              if ((f_error_detected = '1') and (i_ack = '1')) then
                                 -- Return error detected to 0 so i_ack will return to 0
                                 f_error_detected <= '0';
                                 -- Set error flag so this error can be transmitted as
                                 -- soon as i_ack returns to 0
                                 f_error_flag <= '1';
                                 -- Set new error value
                                 f_error <= k_errG & f_last_address;

                              -- If there is no error or if there is an unacknowledged
                              -- error.  Unacknowledged errors will be lost because the
                              -- error buffer is currently full
                              else
                                 f_error_detected <= '1';
                                 f_error <= k_errG & f_last_address; 
                                 -- If there is an error flag, then the error associated
                                 -- with it is lost.
                                 f_error_flag <= '0';
                              end if;
                           end if;

                        -- LW, SW, and Branch flags should be returned to 0 when,
                        -- creating a save restore point
                        else
                           f_lw_instr <= '0';
                           f_sw_instr <= '0';
                           f_br_instr <= '0';
                        end if;
                     end if;
                  when k_prog(93) =>
                     -- Error if this occurs as there should never be a write to this address
                     f_DONE <= '1';
                     f_MEM_READY <= '0';
                     f_data <= B"00000000000000000000000000000000";
                     ff_MEM_READY <= '0';
                     f_sw_instr <= '0';
                     f_lw_instr <= '0';
                     f_br_instr <= '0';
                     f_last_address <= (others => '0');
                     f_next_address <= (others => '0');
                     f_sw_address <= (others => '0');
                     f_lw_address <= (others => '0');
                     f_branch_address <= (others => '0');
                     f_error_detected <= '0';
                     f_error_flag <= '0';
                     f_error <= (others => '0');
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for a previous error being acknowledged at the same
                        -- time this error is detected.
                        if ((f_error_detected = '1') and (i_ack = '1')) then
                           -- Return error detected to 0 so i_ack will return to 0
                           f_error_detected <= '0';
                           -- Set error flag so this error can be transmitted as
                           -- soon as i_ack returns to 0
                           f_error_flag <= '1';
                           -- Set new error value
                           f_error <= k_errI & f_last_address;

                        -- If there is no error or if there is an unacknowledged
                        -- error.  Unacknowledged errors will be lost because the
                        -- error buffer is currently full
                        else
                           f_error_detected <= '1';
                           f_error <= k_errI & f_last_address; 
                           -- If there is an error flag, then the error associated
                           -- with it is lost.
                           f_error_flag <= '0';
                        end if;
                     end if;

                     f_reg(1) <= "00111100000111110000001111100111";
                     f_reg(2) <= "00000000000111111111110000000010";
                     f_reg(3) <= "00111100000000010000101111110000";
                     f_reg(4) <= "00000000000000000001001100000011";
                     f_reg(5) <= "00000000010000100001100000100111";
                     f_reg(6) <= "00000000000000000010001110000011";
                     f_reg(7) <= "00000000000000000000000000000000";
                     f_reg(8) <= "00110000100001010011101101010110";
                     f_reg(9) <= "00000000011001010011000000100011";
                     f_reg(10) <= "10101100000000110000000001011100";
                     f_reg(11) <= "00110100110001110100010111100111";
                     f_reg(12) <= "00111100000010001001100100001101";
                     f_reg(13) <= "00000001000000110100100000101010";
                     f_reg(14) <= "00111001001010100000100011001100";
                     f_reg(15) <= "00100101010010110100010110110011";
                     f_reg(16) <= "10101100000001110000000001100000";
                     f_reg(17) <= "00111001011011001111101110111111";
                     f_reg(18) <= "00000000000000000000000000000000";
                     f_reg(19) <= "10101100000011000000000001100100";
                     f_reg(20) <= "10101100000000010000000001101000";
                     f_reg(21) <= "00100011111111111111111111111111";
                     f_reg(22) <= "00011111111000001111111111101101";
                     f_reg(23) <= "00010000000000000000000001000110";
                     f_reg(24) <= "00000000000000000000000000000000";
                     f_reg(25) <= "00000000000000000000000000000000";
                     f_reg(26) <= "00000000000000000000000000000000";
                     f_reg(27) <= "00000000000000000000000000000000";
                     f_reg(28) <= "00000000000000000000000000000000";
                     f_reg(29) <= "00000000000000000000000000000000";
                     f_reg(30) <= "00000000000000000000000000000000";
                     f_reg(31) <= "00000000000000000000000000000000";
                     f_reg(32) <= "00000000000000000000000000000000";
                     f_reg(33) <= "00000000000000000000000000000000";
                     f_reg(34) <= "00000000000000000000000000000000";
                     f_reg(35) <= "00000000000000000000000000000000";
                     f_reg(36) <= "00000000000000000000000000000000";
                     f_reg(37) <= "00000000000000000000000000000000";
                     f_reg(38) <= "00000000000000000000000000000000";
                     f_reg(39) <= "00000000000000000000000000000000";
                     f_reg(40) <= "00000000000000000000000000000000";
                     f_reg(41) <= "00000000000000000000000000000000";
                     f_reg(42) <= "00000000000000000000000000000000";
                     f_reg(43) <= "00000000000000000000000000000000";
                     f_reg(44) <= "00000000000000000000000000000000";
                     f_reg(45) <= "00000000000000000000000000000000";
                     f_reg(46) <= "00000000000000000000000000000000";
                     f_reg(47) <= "00000000000000000000000000000000";
                     f_reg(48) <= "00000000000000000000000000000000";
                     f_reg(49) <= "00000000000000000000000000000000";
                     f_reg(50) <= "00000000000000000000000000000000";
                     f_reg(51) <= "00000000000000000000000000000000";
                     f_reg(52) <= "00000000000000000000000000000000";
                     f_reg(53) <= "00000000000000000000000000000000";
                     f_reg(54) <= "00000000000000000000000000000000";
                     f_reg(55) <= "00000000000000000000000000000000";
                     f_reg(56) <= "00000000000000000000000000000000";
                     f_reg(57) <= "00000000000000000000000000000000";
                     f_reg(58) <= "00000000000000000000001111100111";
                     f_reg(59) <= "00000000000000000000000000000000";
                     f_reg(60) <= "00000000000000000000000000000000";
                     f_reg(61) <= "00000000000000000000000000000000";
                     f_reg(62) <= "00000000000000000000000000000000";
                     f_reg(63) <= "00000000000000000000000000000000";
                     f_reg(64) <= "00000000000000000000000000000000";
                     f_reg(65) <= "00000000000000000000000000000000";
                     f_reg(66) <= "00000000000000000000000000000000";
                     f_reg(67) <= "00000000000000000000000000000000";
                     f_reg(68) <= "00000000000000000000000000000000";
                     f_reg(69) <= "00000000000000000000000000000000";
                     f_reg(70) <= "00000000000000000000000000000000";
                     f_reg(71) <= "00000000000000000000000000000000";
                     f_reg(72) <= "00000000000000000000000000000000";
                     f_reg(73) <= "00000000000000000000000000000000";
                     f_reg(74) <= "00000000000000000000000000000000";
                     f_reg(75) <= "00000000000000000000000000000000";
                     f_reg(76) <= "00000000000000000000000000000000";
                     f_reg(77) <= "00000000000000000000000000000000";
                     f_reg(78) <= "00000000000000000000000000000000";
                     f_reg(79) <= "00000000000000000000000000000000";
                     f_reg(80) <= "00000000000000000000000000000000";
                     f_reg(81) <= "00000000000000000000000000000000";
                     f_reg(82) <= "00000000000000000000000000000000";
                     f_reg(83) <= "00000000000000000000000000000000";
                     f_reg(84) <= "00000000000000000000000000000000";
                     f_reg(85) <= "00000000000000000000000000000000";
                     f_reg(86) <= "00000000000000000000000000000000";
                     f_reg(87) <= "00000000000000000000000000000000";
                     f_reg(88) <= "00000000000000000000000000000000";
                     f_reg(89) <= "00000000000000000000000000000000";
                     f_reg(90) <= "00000000000000000000000000000000";
                     f_reg(91) <= "00000000000000000000000000000000";
                     f_reg(92) <= "00000000000000000000000000000000";
                  when others =>
                     -- Error if this occurs as there should never be a write to this address
                     f_DONE <= '1';
                     f_MEM_READY <= '0';
                     f_data <= B"00000000000000000000000000000000";
                     ff_MEM_READY <= '0';
                     f_sw_instr <= '0';
                     f_lw_instr <= '0';
                     f_br_instr <= '0';
                     f_last_address <= (others => '0');
                     f_next_address <= (others => '0');
                     f_sw_address <= (others => '0');
                     f_lw_address <= (others => '0');
                     f_branch_address <= (others => '0');
                     f_error_detected <= '0';
                     f_error_flag <= '0';
                     f_error <= (others => '0');
                     if (f_write = '0') then
                        f_write <= '1';
                        -- Check for a previous error being acknowledged at the same
                        -- time this error is detected.
                        if ((f_error_detected = '1') and (i_ack = '1')) then
                           -- Return error detected to 0 so i_ack will return to 0
                           f_error_detected <= '0';
                           -- Set error flag so this error can be transmitted as
                           -- soon as i_ack returns to 0
                           f_error_flag <= '1';
                           -- Set new error value
                           f_error <= k_errI & f_last_address;

                        -- If there is no error or if there is an unacknowledged
                        -- error.  Unacknowledged errors will be lost because the
                        -- error buffer is currently full
                        else
                           f_error_detected <= '1';
                           f_error <= k_errI & f_last_address; 
                           -- If there is an error flag, then the error associated
                           -- with it is lost.
                           f_error_flag <= '0';
                        end if;
                     end if;

                     f_reg(1) <= "00111100000111110000001111100111";
                     f_reg(2) <= "00000000000111111111110000000010";
                     f_reg(3) <= "00111100000000010000101111110000";
                     f_reg(4) <= "00000000000000000001001100000011";
                     f_reg(5) <= "00000000010000100001100000100111";
                     f_reg(6) <= "00000000000000000010001110000011";
                     f_reg(7) <= "00000000000000000000000000000000";
                     f_reg(8) <= "00110000100001010011101101010110";
                     f_reg(9) <= "00000000011001010011000000100011";
                     f_reg(10) <= "10101100000000110000000001011100";
                     f_reg(11) <= "00110100110001110100010111100111";
                     f_reg(12) <= "00111100000010001001100100001101";
                     f_reg(13) <= "00000001000000110100100000101010";
                     f_reg(14) <= "00111001001010100000100011001100";
                     f_reg(15) <= "00100101010010110100010110110011";
                     f_reg(16) <= "10101100000001110000000001100000";
                     f_reg(17) <= "00111001011011001111101110111111";
                     f_reg(18) <= "00000000000000000000000000000000";
                     f_reg(19) <= "10101100000011000000000001100100";
                     f_reg(20) <= "10101100000000010000000001101000";
                     f_reg(21) <= "00100011111111111111111111111111";
                     f_reg(22) <= "00011111111000001111111111101101";
                     f_reg(23) <= "00010000000000000000000001000110";
                     f_reg(24) <= "00000000000000000000000000000000";
                     f_reg(25) <= "00000000000000000000000000000000";
                     f_reg(26) <= "00000000000000000000000000000000";
                     f_reg(27) <= "00000000000000000000000000000000";
                     f_reg(28) <= "00000000000000000000000000000000";
                     f_reg(29) <= "00000000000000000000000000000000";
                     f_reg(30) <= "00000000000000000000000000000000";
                     f_reg(31) <= "00000000000000000000000000000000";
                     f_reg(32) <= "00000000000000000000000000000000";
                     f_reg(33) <= "00000000000000000000000000000000";
                     f_reg(34) <= "00000000000000000000000000000000";
                     f_reg(35) <= "00000000000000000000000000000000";
                     f_reg(36) <= "00000000000000000000000000000000";
                     f_reg(37) <= "00000000000000000000000000000000";
                     f_reg(38) <= "00000000000000000000000000000000";
                     f_reg(39) <= "00000000000000000000000000000000";
                     f_reg(40) <= "00000000000000000000000000000000";
                     f_reg(41) <= "00000000000000000000000000000000";
                     f_reg(42) <= "00000000000000000000000000000000";
                     f_reg(43) <= "00000000000000000000000000000000";
                     f_reg(44) <= "00000000000000000000000000000000";
                     f_reg(45) <= "00000000000000000000000000000000";
                     f_reg(46) <= "00000000000000000000000000000000";
                     f_reg(47) <= "00000000000000000000000000000000";
                     f_reg(48) <= "00000000000000000000000000000000";
                     f_reg(49) <= "00000000000000000000000000000000";
                     f_reg(50) <= "00000000000000000000000000000000";
                     f_reg(51) <= "00000000000000000000000000000000";
                     f_reg(52) <= "00000000000000000000000000000000";
                     f_reg(53) <= "00000000000000000000000000000000";
                     f_reg(54) <= "00000000000000000000000000000000";
                     f_reg(55) <= "00000000000000000000000000000000";
                     f_reg(56) <= "00000000000000000000000000000000";
                     f_reg(57) <= "00000000000000000000000000000000";
                     f_reg(58) <= "00000000000000000000001111100111";
                     f_reg(59) <= "00000000000000000000000000000000";
                     f_reg(60) <= "00000000000000000000000000000000";
                     f_reg(61) <= "00000000000000000000000000000000";
                     f_reg(62) <= "00000000000000000000000000000000";
                     f_reg(63) <= "00000000000000000000000000000000";
                     f_reg(64) <= "00000000000000000000000000000000";
                     f_reg(65) <= "00000000000000000000000000000000";
                     f_reg(66) <= "00000000000000000000000000000000";
                     f_reg(67) <= "00000000000000000000000000000000";
                     f_reg(68) <= "00000000000000000000000000000000";
                     f_reg(69) <= "00000000000000000000000000000000";
                     f_reg(70) <= "00000000000000000000000000000000";
                     f_reg(71) <= "00000000000000000000000000000000";
                     f_reg(72) <= "00000000000000000000000000000000";
                     f_reg(73) <= "00000000000000000000000000000000";
                     f_reg(74) <= "00000000000000000000000000000000";
                     f_reg(75) <= "00000000000000000000000000000000";
                     f_reg(76) <= "00000000000000000000000000000000";
                     f_reg(77) <= "00000000000000000000000000000000";
                     f_reg(78) <= "00000000000000000000000000000000";
                     f_reg(79) <= "00000000000000000000000000000000";
                     f_reg(80) <= "00000000000000000000000000000000";
                     f_reg(81) <= "00000000000000000000000000000000";
                     f_reg(82) <= "00000000000000000000000000000000";
                     f_reg(83) <= "00000000000000000000000000000000";
                     f_reg(84) <= "00000000000000000000000000000000";
                     f_reg(85) <= "00000000000000000000000000000000";
                     f_reg(86) <= "00000000000000000000000000000000";
                     f_reg(87) <= "00000000000000000000000000000000";
                     f_reg(88) <= "00000000000000000000000000000000";
                     f_reg(89) <= "00000000000000000000000000000000";
                     f_reg(90) <= "00000000000000000000000000000000";
                     f_reg(91) <= "00000000000000000000000000000000";
                     f_reg(92) <= "00000000000000000000000000000000";
               end case;

            -- Not attempting to read from or write to memory
            else
               f_read <= '0';
               f_write <= '0';
               f_MEM_READY <= '0';
               f_done <= '0';
               -- Check for a timeout error occuring
               if ((f_clk_count >= k_timeout1) and (f_clk_count < k_timeout2)) then
                  f_clk_count <= f_clk_count + 1;
                  -- Check timeout flag set to 0.  If 0, trigger an error
                  if (f_timeout_flag = '0') then
                     -- Set the timeout flag because error TMR may be recovering
                     -- from a single processor error
                     f_timeout_flag <= '1';
                     -- LW, SW, and Branch flags should be returned to 0 when,
                     -- creating a save restore point
                     f_lw_instr <= '0';
                     f_sw_instr <= '0';
                     f_br_instr <= '0';
                     -- Set next address to be the last address in case an ERR0
                     -- has been encountered so another error is not triggered
                     -- when ERR0 recovery completes
                     f_next_address <= f_last_address;
                     -- Check for a previous error being acknowledged at the same
                     -- time this error is detected.
                     if ((f_error_detected = '1') and (i_ack = '1')) then
                        -- Return error detected to 0 so i_ack will return to 0
                        f_error_detected <= '0';
                        -- Set error flag so this error can be transmitted as
                        -- soon as i_ack returns to 0
                        f_error_flag <= '1';
                        -- Set new error value
                        f_error <= k_errJ & f_last_address;

                     -- If there is no error or if there is an unacknowledged
                     -- error.  Unacknowledged errors will be lost because the
                     -- error buffer is currently full
                     else
                        f_error_detected <= '1';
                        f_error <= k_errJ & f_last_address; 
                        -- If there is an error flag, then the error associated
                        -- with it is lost.
                        f_error_flag <= '0';
                     end if;

                  -- The timeout flag is already set to 1 and error was already triggered
                  else
                     -- Check for previous error being acknowledged
                     if ((f_error_detected = '1') and (i_ack = '1')) then
                        -- Return error detected to 0 so i_ack will return to 0
                        f_error_detected <= '0';
                        -- Check for previous error acknowledged and an error flag being set
                     elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                        -- Set f_error_flag back to 0 and transmit the error now
                        f_error_flag <= '0';
                        f_error_detected <= '1';
                     end if;
                  end if;

               -- Timeout error has occured because error recovery did not complete
               elsif (f_clk_count = k_timeout2) then
                  f_clk_count <= f_clk_count + 1;
                  -- Check for a previous error being acknowledged at the same
                  -- time this error is detected.
                  if ((f_error_detected = '1') and (i_ack = '1')) then
                     -- Return error detected to 0 so i_ack will return to 0
                     f_error_detected <= '0';
                     -- Set error flag so this error can be transmitted as
                     -- soon as i_ack returns to 0
                     f_error_flag <= '1';
                     -- Set new error value
                     f_error <= k_errX & f_last_address;

                  -- If there is no error or if there is an unacknowledged
                  -- error.  Unacknowledged errors will be lost because the
                  -- error buffer is currently full
                  else
                     f_error_detected <= '1';
                     f_error <= k_errX & f_last_address; 
                     -- If there is an error flag, then the error associated
                     -- with it is lost.
                     f_error_flag <= '0';
                  end if;

               -- Timeout error has occured because error recovery did not complete
               -- Do not continuously signal an error
               elsif (f_clk_count > k_timeout2) then
                  -- Check for previous error being acknowledged
                  if ((f_error_detected = '1') and (i_ack = '1')) then
                     -- Return error detected to 0 so i_ack will return to 0
                     f_error_detected <= '0';
                     -- Check for previous error acknowledged and an error flag being set
                  elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                     -- Set f_error_flag back to 0 and transmit the error now
                     f_error_flag <= '0';
                     f_error_detected <= '1';
                  end if;

               -- Timeout error has not occured
               else
                  f_clk_count <= f_clk_count + 1;
                  -- Check for previous error being acknowledged
                  if ((f_error_detected = '1') and (i_ack = '1')) then
                     -- Return error detected to 0 so i_ack will return to 0
                     f_error_detected <= '0';
                     -- Check for previous error acknowledged and an error flag being set
                  elsif ((f_error_detected = '0') and (f_error_flag = '1')) then
                     -- Set f_error_flag back to 0 and transmit the error now
                     f_error_flag <= '0';
                     f_error_detected <= '1';
                  end if;
               end if;
            end if;
         else
            f_DONE <= '0';
            f_data <= B"00000000000000000000000000000000";
            f_MEM_READY <= '0';
            ff_MEM_READY <= '0';
            f_read <= '0';
            f_write <= '0';
            f_sw_instr <= '0';
            f_lw_instr <= '0';
            f_br_instr <= '0';
            f_last_address <= (others => '0');
            f_next_address <= (others => '0');
            f_sw_address <= (others => '0');
            f_lw_address <= (others => '0');
            f_branch_address <= (others => '0');
            f_error_detected <= '0';
            f_error_flag <= '0';
            f_error <= (others => '0');
            f_timeout_flag <= '0';
            f_recovery_flag <= '0';
         end if;
      end if;
   end process;
end a_Test54_Reg_TMR;
