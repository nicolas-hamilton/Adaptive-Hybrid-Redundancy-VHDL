--| Combined_Controller_Test36.vhd
--| Switch between TMR MIPS and TSR MIPS operation depending on the radiation
--| environment.  Starts operating in TMR MIPS.  If no errors occur over a
--| predifined time period, automatically switches to operating in TSR MIPS.
--| If an error occurs while operating in TSR MIPS, automatically switches to
--| TMR MIPS.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Combined_Controller_Test36 is
   port (i_clk          : in  std_logic;
         i_reset        : in  std_logic;
         i_NEXT_INSTR   : in  std_logic;                        -- From TMR Voter   - used to determine next state
         i_TMR_ERROR    : in  std_logic;                        -- From TMR Voter   - used to determine next state
         i_MEM_READ     : in  std_logic;                        -- From TMR Voter   - used to determine next state   - controller can modify this signal
         i_MEM_WRITE    : in  std_logic;                        -- From TMR Voter   - used to determine next state   - controller can modify this signal
         i_MEM_ADDRESS  : in  std_logic_vector(31 downto 0);   -- From TMR Voter   - used to determine next state   - controller can modify this signal
         i_MEM_IN       : in  std_logic_vector(31 downto 0);   -- From TMR Voter                                    - controller can modify this signal
         i_MEM_READY    : in  std_logic;                        -- From Memory      - used to determine next state   - controller can modify this signal
         i_MEM_OUT      : in  std_logic_vector(31 downto 0);   -- From Memory                                       - controller can modify this signal
         i_MEM_DONE     : in  std_logic;                        -- From Memory                                       - controller can modify this signal
         i_MEM_READ0    : in  std_logic;                        -- From MIPS0      - used to determine next state   - controller can modify this signal
         i_MEM_WRITE0   : in  std_logic;                        -- From MIPS0                                       - controller can modify this signal
         i_MEM_ADDRESS0 : in  std_logic_vector(31 downto 0);   -- From MIPS0      - used to determine next state   - controller can modify this signal
         i_MEM_IN0      : in  std_logic_vector(31 downto 0);   -- From MIPS0                                       - controller can modify this signal
         i_MEM_READY0   : in  std_logic;                        -- From Voter                                       - controller can modify this signal
         i_MEM_OUT0     : in  std_logic_vector(31 downto 0);   -- From Voter                                       - controller can modify this signal
         i_RESET0       : in  std_logic;                        -- From Voter                                       - controller can modify this signal
         i_MEM_READY1   : in  std_logic;                        -- From Voter                                       - controller can modify this signal
         i_MEM_OUT1     : in  std_logic_vector(31 downto 0);   -- From Voter                                       - controller can modify this signal
         i_RESET1       : in  std_logic;                        -- From Voter                                       - controller can modify this signal
         i_MEM_READY2   : in  std_logic;                        -- From Voter                                       - controller can modify this signal
         i_MEM_OUT2     : in  std_logic_vector(31 downto 0);   -- From Voter                                       - controller can modify this signal
         i_RESET2       : in  std_logic;                        -- From Voter                                       - controller can modify this signal
         o_MEM_READ     : out std_logic;                        -- To Memory
         o_MEM_WRITE    : out std_logic;                        -- To Memory
         o_MEM_ADDRESS  : out std_logic_vector(31 downto 0);   -- To Memory
         o_MEM_IN       : out std_logic_vector(31 downto 0);   -- To Memory
         o_MEM_READY    : out std_logic;                        -- To TMR Voter
         o_MEM_OUT      : out std_logic_vector(31 downto 0);   -- To TMR Voter
         o_MEM_DONE     : out std_logic;                        -- To TMR Voter
         o_MEM_READY0   : out std_logic;                        -- To MIPS0
         o_MEM_OUT0     : out std_logic_vector(31 downto 0);   -- To MIPS0
         o_RESET0       : out std_logic;                        -- To MIPS0
         o_MEM_READY1   : out std_logic;                        -- To MIPS1
         o_MEM_OUT1     : out std_logic_vector(31 downto 0);   -- To MIPS1
         o_RESET1       : out std_logic;                        -- To MIPS1
         o_MEM_READY2   : out std_logic;                        -- To MIPS2
         o_MEM_OUT2     : out std_logic_vector(31 downto 0);   -- To MIPS2
         o_RESET2       : out std_logic);                        -- To MIPS2
end Combined_Controller_Test36;

architecture a_Combined_Controller_Test36 of Combined_Controller_Test36 is
--| Declare components
   -- 2-input 1-bit mux
   component myMUX2_1 is
      port (i_0 : in  std_logic;
            i_1 : in  std_logic;
            i_S : in  std_logic;
            o_Z : out std_logic
            );
   end component;
   
   -- 2-input 32-bit mux
   component myMUX2_N is
      generic (m_width : integer := 32);
      port (i_0 : in  std_logic_vector(m_width-1 downto 0);
            i_1 : in  std_logic_vector(m_width-1 downto 0);
            i_S : in  std_logic;
            o_Z : out std_logic_vector(m_width-1 downto 0)
            );
   end component;
   -- 4-input 1-bit mux
   component myMUX4_1 is
      port (i_0 : in  std_logic;
            i_1 : in  std_logic;
            i_2 : in  std_logic;
            i_3 : in  std_logic;
            i_S : in  std_logic_vector(1 downto 0);
            o_Z : out std_logic
            );
   end component;

--| Create state machine types
   -- Create states for the controller finite state machine
   type sm_cfsm is (s_cfsm_0, s_cfsm_1, s_cfsm_2, s_cfsm_3, s_cfsm_4,
                    s_cfsm_5, s_cfsm_6, s_cfsm_7, s_cfsm_8, s_cfsm_9,
                    s_cfsm_10,s_cfsm_11,s_cfsm_12,s_cfsm_13,s_cfsm_14,
                    s_cfsm_15,s_cfsm_16,s_cfsm_17,s_cfsm_18,s_cfsm_19,
                    s_cfsm_20,s_cfsm_21,s_cfsm_22,s_cfsm_23,s_cfsm_24,
                    s_cfsm_25,s_cfsm_26,s_cfsm_27,s_cfsm_28,s_cfsm_29,
                    s_cfsm_30,s_cfsm_31,s_cfsm_32,s_cfsm_33,s_cfsm_34,
                    s_cfsm_35,s_cfsm_36,s_cfsm_37,s_cfsm_38,s_cfsm_39,
                    s_cfsm_40,s_cfsm_41,s_cfsm_42,s_cfsm_43,s_cfsm_44,
                    s_cfsm_45,s_cfsm_46,s_cfsm_47,s_cfsm_48,s_cfsm_49,
                    s_cfsm_50,s_cfsm_51,s_cfsm_52);
                     
   -- Initialize the controller finite state machine register
   signal f_cfsm_state : sm_cfsm := s_cfsm_0;
   
--| Define Signals
   -- Counts instructions to determine when to transition from TMR to TSR
   signal f_instr_count : unsigned(31 downto 0) := (others => '0');
   
   -- Used to store the current iteration of the program loop when switching from TMR to TSR or vice versa - modified as needed
   signal f_loop : unsigned(31 downto 0) := (others => '0');
   -- Used to store an unaltered copy of the current iteration of the program loop when switching from TMR to TSR or vice versa
   signal f_loop1 : unsigned(31 downto 0) := (others => '0');
   
   -- Signal used to determine last value of i_NEXT_INSTR signal
   signal f_NEXT_INSTR      : std_logic := '0';
   
   -- Registers for holding output values when temporary values are needed
   --- Outputs to Memory
   signal f_MEM_ADDRESS      : std_logic_vector(31 downto 0) := (others => '0');
   signal f_MEM_IN         : std_logic_vector(31 downto 0) := (others => '0');
   -- Outputs to Voter
   signal f_MEM_OUT         : std_logic_vector(31 downto 0) := (others => '0');
   -- Outputs to MIPS Processors
   signal f_MEM_OUT0         : std_logic_vector(31 downto 0) := (others => '0');
   
   -- Intermediate address used for accessing recovery memory
   signal f_TEMP_ADDRESS   : std_logic_vector(31 downto 0);
   
   -- Wires for routing intermediate output values
   signal w_MEM_ADDRESS    : std_logic_vector(31 downto 0);
   signal w_MEM_IN         : std_logic_vector(31 downto 0);
   signal w_MEM_READY      : std_logic;
   signal w_MEM_OUT        : std_logic_vector(31 downto 0);
   signal w_MEM_DONE       : std_logic;
   signal w_MEM_OUT0       : std_logic_vector(31 downto 0);
   signal w_TMR_RESET0      : std_logic;
   signal w_TMR_RESET1      : std_logic;
   signal w_TMR_RESET2      : std_logic;
   signal w_TMR_RESET0a      : std_logic;
   signal w_TMR_RESET1a      : std_logic;
   signal w_TMR_RESET2a      : std_logic;
   signal w_MEM_RESET1     : std_logic;
   signal w_MEM_RESET2     : std_logic;
   
   -- Registers for controlling flow of outputs
   -- f_MEM_READ_SEL selects what read signal should be output to memory
   --- 00 - Voter Pass through
   --- 01 - MIPS0 Pass Through
   --- 10 - 0
   --- 11 - 1
   signal f_MEM_READ_SEL   : std_logic_vector(1 downto 0) := (others => '0');
   
   -- f_MEM_WRITE_SEL selects what write and data signals should be output to memory
   --- 00 - Voter Pass through
   --- 01 - MIPS0 Pass Through
   --- 10 - 0
   --- 11 - 1
   signal f_MEM_WRITE_SEL   : std_logic_vector(1 downto 0) := (others => '0');
   
   -- f_MEM_ADDRESS_SEL selects what address signal should be output to memory
   --- 00 - Voter Pass through
   --- 01 - MIPS0 Pass Through
   --- 10 - Controller Data Override
   --- 11 - Controller Data Override
   signal f_MEM_ADDRESS_SEL   : std_logic_vector(1 downto 0) := (others => '0');
   
   -- f_MEM_READY_SEL selects what memory ready and data signals should be output to the voter
   --- 00 - Memory Pass Through
   --- 01 - 0
   --- 10 - 1
   --- 11 - 1
   signal f_MEM_READY_SEL :std_logic_vector(1 downto 0) := (others => '0');
   
   -- f_MEM_DONE_SEL selects what done signal should be output to the voter
   --- 00 - Memory Pass Through
   --- 01 - 0
   --- 10 - 1
   --- 11 - 1
   signal f_MEM_DONE_SEL :std_logic_vector(1 downto 0) := (others => '0');
   
   -- f_MEM_READY0_SEL selects what ready and data signals should be output to MIPS0
   --- 00 - Voter Pass Through
   --- 01 - Memory Pass Through
   --- 10 - 0
   --- 11 - 1
   signal f_MEM_READY0_SEL :std_logic_vector(1 downto 0) := (others => '0');
   
   -- f_MEM_READY12_SEL selects what ready and data signals should be output to MIPS1 and MIPS2
   --- 0 - Voter Pass Through
   --- 1 - 0
   signal f_MEM_READY12_SEL :std_logic := '0';
   
   -- f_MEM_RESET0_SEL selects what resetignal should be output to MIPS0
   --- 00 - Voter Pass Through
   --- 01 - Memory Pass Through
   --- 10 - 0
   --- 11 - 1
   signal f_MEM_RESET0_SEL :std_logic_vector(1 downto 0) := (others => '0');
   
   -- f_MEM_RESET12_SEL selects what reset signal should be output to MIPS1 and MIPS2
   --- 00 - Voter Pass Through
   --- 01 - 0
   --- 10 - 1
   --- 11 - 1
   signal f_MEM_RESET12_SEL :std_logic_vector(1 downto 0) := (others => '0');
   
   
   -- Define Constants
   -- Constant used to compare instruction counter against
   constant k_switch_point : unsigned(31 downto 0) := "00000000000000000011101010011000";
   
   -- Location at which backup memory starts
   constant k_mem_location : std_logic_vector(31 downto 0) := "00000000000000000000010011001000";
   -- Important backup memory locations
   constant k_14_16 : std_logic_vector(15 downto 0) := "0000000000111000";
   constant k_02_32 : std_logic_vector(31 downto 0) := "00000000000000000000000000001000";
   constant k_14_32 : std_logic_vector(31 downto 0) := "00000000000000000000000000111000";
   constant k_29_32 : std_logic_vector(31 downto 0) := "00000000000000000000000001110100";
   constant k_30_32 : std_logic_vector(31 downto 0) := "00000000000000000000000001111000";
   constant k_31_32 : std_logic_vector(31 downto 0) := "00000000000000000000000001111100";
   constant k_62_32 : std_logic_vector(31 downto 0) := "00000000000000000000000011111000";
   constant k_63_32 : std_logic_vector(31 downto 0) := "00000000000000000000000011111100";
   constant k_64_32 : std_logic_vector(31 downto 0) := "00000000000000000000000100000000";
   constant k_mem_location14_16 : std_logic_vector(15 downto 0) := std_logic_vector(unsigned(k_mem_location(15 downto 0)) + unsigned(k_14_16));
   constant k_mem_location02_32 : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(k_mem_location) + unsigned(k_02_32));
   constant k_mem_location14_32 : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(k_mem_location) + unsigned(k_14_32));
   constant k_mem_location29_32 : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(k_mem_location) + unsigned(k_29_32));
   constant k_mem_location30_32 : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(k_mem_location) + unsigned(k_30_32));
   constant k_mem_location31_32 : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(k_mem_location) + unsigned(k_31_32));
   constant k_mem_location62_32 : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(k_mem_location) + unsigned(k_62_32));
   constant k_mem_location63_32 : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(k_mem_location) + unsigned(k_63_32));
   constant k_mem_location64_32 : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(k_mem_location) + unsigned(k_64_32));
   
   
   -- Location at which TMR loop starts
   constant k_TMR_LOOP_START : std_logic_vector(31 downto 0) := "00000000000000000000000000001000";
   -- Location at which TSR starts
   constant k_TSR_START_BRANCH : std_logic_vector(15 downto 0) := "0000000000100101";
   -- Location at which TSR loop starts
   constant k_TSR_LOOP_START_BRANCH : std_logic_vector(15 downto 0) := "0000000000100111";
   -- Location at which TSR Error Recovery Code Starts
   constant k_TSR_RECOVERY : std_logic_vector(31 downto 0) := "00000000000000000000001110011000";
   
   -- Zero constants
   constant k_zero_1 : std_logic := '0';
   constant k_zero_32 : std_logic_vector(31 downto 0) := (others => '0');
   
   -- One constant
   constant k_one_1 : std_logic := '1';
   
   -- Constant used to access the 64th memory location (0-30=R1-R31, 31=PC, 32-62=R1-R31, 63=PC, 64=sav_point)
   constant k_256_32 : std_logic_vector(31 downto 0) := "00000000000000000000000100000000";
   -- Constant used to access the 32nd memory location (0-30=R1-R31, 31=PC, 32-62=R1-R31, 63=PC, 64=sav_point)
   constant k_128_16 : std_logic_vector(15 downto 0) := "0000000010000000";
   -- Constant used to access the 31st memory location (0-30=R1-R31, 31=PC, 32-62=R1-R31, 63=PC, 64=sav_point)
   constant k_124_32 : std_logic_vector(31 downto 0) := "00000000000000000000000001111100";
   -- Constant used to access the 63rd memory location (0-30=R1-R31, 31=PC, 32-62=R1-R31, 63=PC, 64=sav_point)
   constant k_252_32 : std_logic_vector(31 downto 0) := "00000000000000000000000011111100";
   
begin
   w_TMR_RESET0 <= i_RESET0 or i_MEM_DONE; -- Reset MIPS0 on a Voter Reset0 signal or memory DONE signal
   w_TMR_RESET1 <= i_RESET1 or i_MEM_DONE; -- Reset MIPS1 on a Voter Reset1 signal or memory DONE signal
   w_TMR_RESET2 <= i_RESET2 or i_MEM_DONE; -- Reset MIPS2 on a Voter Reset2 signal or memory DONE signal
   
   -- Assign output reset signals
   o_RESET0 <= w_TMR_RESET0a or i_reset;
   o_RESET1 <= w_TMR_RESET1a or i_reset;
   o_RESET2 <= w_TMR_RESET2a or i_reset;
   
   -- MUX to determine the memory read signal to be sent to memory
   u_myMUX_MEM_READ: myMUX4_1
   port map (i_0 => i_MEM_READ,
             i_1 => i_MEM_READ0,
             i_2 => k_zero_1,
             i_3 => k_one_1,
             i_S => f_MEM_READ_SEL,
             o_Z => o_MEM_READ);

   -- MUX to determine the memory write signal to be sent to memory
   u_myMUX_MEM_WRITE: myMUX4_1
   port map (i_0 => i_MEM_WRITE,
             i_1 => i_MEM_WRITE0,
             i_2 => k_zero_1,
             i_3 => k_one_1,
             i_S => f_MEM_WRITE_SEL,
             o_Z => o_MEM_WRITE);
             
   -- MUX to determine the memory address signal to be sent to memory - selects between Voter or MIPS 0 - intermediate selector
   u_myMUX_MEM_ADDRESS_Intermediate: myMUX2_N
   generic map (m_width => 32)
   port map (i_0 => i_MEM_ADDRESS,
             i_1 => i_MEM_ADDRESS0,
             i_S => f_MEM_ADDRESS_SEL(0),
             o_Z => w_MEM_ADDRESS);
             
   -- MUX to determine the memory address signal to be sent to memory - selects between output of Voter or MIPS 0 selector MUX and the controller override
   u_myMUX_MEM_ADDRESS: myMUX2_N
   generic map (m_width => 32)
   port map (i_0 => w_MEM_ADDRESS,
             i_1 => f_MEM_ADDRESS,
             i_S => f_MEM_ADDRESS_SEL(1),
             o_Z => o_MEM_ADDRESS);
             
   -- MUX to determine the memory data input signal to be sent to memory - selects between Voter or MIPS 0 - intermediate selector
   u_myMUX_MEM_IN_Intermediate: myMUX2_N
   generic map (m_width => 32)
   port map (i_0 => i_MEM_IN,
             i_1 => i_MEM_IN0,
             i_S => f_MEM_WRITE_SEL(0),
             o_Z => w_MEM_IN);
             
   -- MUX to determine the memory data input signal to be sent to memory - selects between output of Voter or MIPS 0 selector MUX and the controller override
   u_myMUX_MEM_IN: myMUX2_N
   generic map (m_width => 32)
   port map (i_0 => w_MEM_IN,
             i_1 => f_MEM_IN,
             i_S => f_MEM_WRITE_SEL(1),
             o_Z => o_MEM_IN);

   -- MUX to determine the memory ready signal to be sent to the voter - selects between Memory or 0 - intermediate selector
   u_myMUX_MEM_READY_Intermediate: myMUX2_1
   port map (i_0 => i_MEM_READY,
             i_1 => k_zero_1,
             i_S => f_MEM_READY_SEL(0),
             o_Z => w_MEM_READY);

   -- MUX to determine the memory ready signal to be sent to the voter - selects between output of Memory or 0 selector MUX and 1
   u_myMUX_MEM_READY: myMUX2_1
   port map (i_0 => w_MEM_READY,
             i_1 => k_one_1,
             i_S => f_MEM_READY_SEL(1),
             o_Z => o_MEM_READY);

   -- MUX to determine the memory data signal to be sent to the voter - selects between Memory or 0 - intermediate selector
   u_myMUX_MEM_OUT_Intermediate: myMUX2_N
   generic map (m_width => 32)
   port map (i_0 => i_MEM_OUT,
             i_1 => k_zero_32,
             i_S => f_MEM_READY_SEL(0),
             o_Z => w_MEM_OUT);

   -- MUX to determine the memory data signal to be sent to the voter - selects between output of Memory or 0 selector MUX and the controller override
   u_myMUX_MEM_OUT: myMUX2_N
   generic map (m_width => 32)
   port map (i_0 => w_MEM_OUT,
             i_1 => f_MEM_OUT,
             i_S => f_MEM_READY_SEL(1),
             o_Z => o_MEM_OUT);

   -- MUX to determine the memory done signal to be sent to the voter - selects between Memory or 0 - intermediate selector
   u_myMUX_MEM_DONE_Intermediate: myMUX2_1
   port map (i_0 => i_MEM_DONE,
             i_1 => k_zero_1,
             i_S => f_MEM_DONE_SEL(0),
             o_Z => w_MEM_DONE);

   -- MUX to determine the memory done signal to be sent to the voter - selects between output of Memory or 0 selector MUX and 1
   u_myMUX_MEM_DONE: myMUX2_1
   port map (i_0 => w_MEM_DONE,
             i_1 => k_one_1,
             i_S => f_MEM_DONE_SEL(1),
             o_Z => o_MEM_DONE);
             
   -- MUX to determine the ready signal to be sent to MIPS0
   u_myMUX_MEM_READY0: myMUX4_1
   port map (i_0 => i_MEM_READY0,
             i_1 => i_MEM_READY,
             i_2 => k_zero_1,
             i_3 => k_one_1,
             i_S => f_MEM_READY0_SEL,
             o_Z => o_MEM_READY0);

   -- MUX to determine the ready signal to be sent to MIPS1
   u_myMUX_MEM_READY1: myMUX2_1
   port map (i_0 => i_MEM_READY1,
             i_1 => k_zero_1,
             i_S => f_MEM_READY12_SEL,
             o_Z => o_MEM_READY1);

   -- MUX to determine the ready signal to be sent to MIPS1
   u_myMUX_MEM_READY2: myMUX2_1
   port map (i_0 => i_MEM_READY2,
             i_1 => k_zero_1,
             i_S => f_MEM_READY12_SEL,
             o_Z => o_MEM_READY2);

   -- MUX to determine the memory data signal to be sent to MIPS0 - selects between Voter or Memory - intermediate selector
   u_myMUX_MEM_OUT0_Intermediate: myMUX2_N
   generic map (m_width => 32)
   port map (i_0 => i_MEM_OUT0,
             i_1 => i_MEM_OUT,
             i_S => f_MEM_READY0_SEL(0),
             o_Z => w_MEM_OUT0);

   -- MUX to determine the memory data signal to be sent to MIPS0 - selects between output of Voter or Memory selector MUX and the controller override
   u_myMUX_MEM_OUT0: myMUX2_N
   generic map (m_width => 32)
   port map (i_0 => w_MEM_OUT0,
             i_1 => f_MEM_OUT0,
             i_S => f_MEM_READY0_SEL(1),
             o_Z => o_MEM_OUT0);

   -- MUX to determine the memory data signal to be sent to MIPS1 - selects between output of Voter or 0
   u_myMUX_MEM_OUT1: myMUX2_N
   generic map (m_width => 32)
   port map (i_0 => i_MEM_OUT1,
             i_1 => k_zero_32,
             i_S => f_MEM_READY12_SEL,
             o_Z => o_MEM_OUT1);

   -- MUX to determine the memory data signal to be sent to MIPS2 - selects between output of Voter or 0
   u_myMUX_MEM_OUT2: myMUX2_N
   generic map (m_width => 32)
   port map (i_0 => i_MEM_OUT2,
             i_1 => k_zero_32,
             i_S => f_MEM_READY12_SEL,
             o_Z => o_MEM_OUT2);
             
   -- MUX to determine the reset signal to be sent to MIPS0
   u_myMUX_MEM_RESET0: myMUX4_1
   port map (i_0 => w_TMR_RESET0,
             i_1 => i_MEM_DONE,
             i_2 => k_zero_1,
             i_3 => k_one_1,
             i_S => f_MEM_RESET0_SEL,
             o_Z => w_TMR_RESET0a);
             
   -- MUX to determine the reset signal to be sent to MIPS1 - selects between output of Voter or 0
   u_myMUX_MEM_RESET1_Intermediate: myMUX2_1
   port map (i_0 => w_TMR_RESET1,
             i_1 => k_zero_1,
             i_S => f_MEM_RESET12_SEL(0),
             o_Z => w_MEM_RESET1);
             
   -- MUX to determine the reset signal to be sent to MIPS1 - selects between output of Voter or 0 selector MUX and 1
   u_myMUX_MEM_RESET1: myMUX2_1
   port map (i_0 => w_MEM_RESET1,
             i_1 => k_one_1,
             i_S => f_MEM_RESET12_SEL(1),
             o_Z => w_TMR_RESET1a);
             
   -- MUX to determine the reset signal to be sent to MIPS2 - selects between output of Voter or 0
   u_myMUX_MEM_RESET2_Intermediate: myMUX2_1
   port map (i_0 => w_TMR_RESET2,
             i_1 => k_zero_1,
             i_S => f_MEM_RESET12_SEL(0),
             o_Z => w_MEM_RESET2);
             
   -- MUX to determine the reset signal to be sent to MIPS2 - selects between output of Voter or 0 selector MUX and 1
   u_myMUX_MEM_RESET2: myMUX2_1
   port map (i_0 => w_MEM_RESET2,
             i_1 => k_one_1,
             i_S => f_MEM_RESET12_SEL(1),
             o_Z => w_TMR_RESET2a);
   
   
   cfsm: process(i_clk, i_reset, f_cfsm_state,i_NEXT_INSTR,i_TMR_ERROR)
   begin
      if (i_reset = '1') then
         f_cfsm_state      <= s_cfsm_0;
         f_instr_count      <= (others => '0');
         f_loop            <= (others => '0');
         f_loop1            <= (others => '0');
         f_TEMP_ADDRESS    <= (others => '0');
      elsif rising_edge(i_clk) then
         f_NEXT_INSTR <= i_NEXT_INSTR;
         case f_cfsm_state is
            -- TMR MIPS is running
            -- Determine when TMR MIPS completes processing an instruction or encounters an error
            when s_cfsm_0 =>
               if (i_TMR_ERROR = '1') then
                  f_cfsm_state <= s_cfsm_2;
               elsif ((f_instr_count >= k_switch_point) and (i_MEM_READ = '1') and (i_MEM_ADDRESS = k_TMR_LOOP_START)) then
                  f_cfsm_state <= s_cfsm_3;
               elsif ((i_NEXT_INSTR = '1') and (f_NEXT_INSTR = '0')) then
                  f_cfsm_state <= s_cfsm_1;
               else
                  f_cfsm_state <= s_cfsm_0;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
            
            -- Return to state 0
            when s_cfsm_1 =>
               f_cfsm_state <= s_cfsm_0;
               f_instr_count <= f_instr_count + 1;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- TMR MIPS has encountered an error
            when s_cfsm_2 =>
               if (i_TMR_ERROR = '0') then
                  f_cfsm_state <= s_cfsm_0;
                  f_instr_count <= (others => '0');
               else
                  f_cfsm_state <= s_cfsm_2;
                  f_instr_count <= f_instr_count + 1;
               end if;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
            
            -- Start transition from TMR MIPS to TSR MIPS
            -- Wait for Memory Ready signal
            when s_cfsm_3 =>
               if (i_MEM_READY = '1') then
                  f_cfsm_state <= s_cfsm_4;
               else
                  f_cfsm_state <= s_cfsm_3;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_4 =>
               if (i_MEM_READY = '0') then
                  f_cfsm_state <= s_cfsm_5;
               else
                  f_cfsm_state <= s_cfsm_4;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
            
            -- Wait for TMR Voter Read signal to return to 0
            when s_cfsm_5 =>
               if (i_MEM_READ = '0') then
                  f_cfsm_state <= s_cfsm_6;
               else
                  f_cfsm_state <= s_cfsm_5;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
            
            -- Wait for TMR Voter Write signal and watch out for an Error
            when s_cfsm_6 =>
               if (i_TMR_ERROR = '1') then
                  f_cfsm_state <= s_cfsm_2;
               elsif (i_MEM_WRITE = '1') then
                  f_cfsm_state <= s_cfsm_7;
               else
                  f_cfsm_state <= s_cfsm_6;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
            
            -- Wait for TMR Voter Write signal to return to 0
            when s_cfsm_7 =>
               if (i_MEM_WRITE = '0') then
                  f_cfsm_state <= s_cfsm_8;
                  f_loop <= f_loop;
                  f_loop1 <= f_loop1;
               else
                  f_cfsm_state <= s_cfsm_7;
                  f_loop <= unsigned(i_MEM_IN);
                  f_loop1 <= unsigned(i_MEM_IN);
               end if;
               f_instr_count <= f_instr_count;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
            
            -- Add 1 to the loop count
            when s_cfsm_8 =>
               f_cfsm_state <= s_cfsm_9;
               f_instr_count <= (others => '0');
               f_loop <= f_loop + 1;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
            
            -- Wait for Memory Ready Signal
            when s_cfsm_9 =>
               if (i_MEM_READY = '1') then
                  f_cfsm_state <= s_cfsm_10;
               else
                  f_cfsm_state <= s_cfsm_9;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_10 =>
               if (i_MEM_READY = '0') then
                  f_cfsm_state <= s_cfsm_11;
               else
                  f_cfsm_state <= s_cfsm_10;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
            
            -- Wait for Memory Ready Signal
            when s_cfsm_11 =>
               if (i_MEM_READY = '1') then
                  f_cfsm_state <= s_cfsm_12;
               else
                  f_cfsm_state <= s_cfsm_11;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_12 =>
               if (i_MEM_READY = '0') then
                  f_cfsm_state <= s_cfsm_13;
               else
                  f_cfsm_state <= s_cfsm_12;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
            
            -- Wait for Memory Ready Signal
            when s_cfsm_13 =>
               if (i_MEM_READY = '1') then
                  f_cfsm_state <= s_cfsm_14;
               else
                  f_cfsm_state <= s_cfsm_13;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_14 =>
               if (i_MEM_READY = '0') then
                  f_cfsm_state <= s_cfsm_15;
               else
                  f_cfsm_state <= s_cfsm_14;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
            
            -- Reset MIPS Processors
            when s_cfsm_15 =>
               f_cfsm_state <= s_cfsm_16;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for MIPS0 Read Signal
            when s_cfsm_16 =>
               if (i_MEM_READ0 = '1') then
                  f_cfsm_state <= s_cfsm_17;
               else
                  f_cfsm_state <= s_cfsm_16;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for MIPS0 Read Signal to return to 0
            when s_cfsm_17 =>
               if (i_MEM_READ0 = '0') then
                  f_cfsm_state <= s_cfsm_18;
               else
                  f_cfsm_state <= s_cfsm_17;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for MIPS0 Read Signal
            when s_cfsm_18 =>
               if (i_MEM_READ0 = '1') then
                  f_cfsm_state <= s_cfsm_19;
               else
                  f_cfsm_state <= s_cfsm_18;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for MIPS0 Read Signal to return to 0
            when s_cfsm_19 =>
               if (i_MEM_READ0 = '0') then
                  f_cfsm_state <= s_cfsm_20;
               else
                  f_cfsm_state <= s_cfsm_19;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for MIPS0 Read Signal
            when s_cfsm_20 =>
               if (i_MEM_READ0 = '1') then
                  f_cfsm_state <= s_cfsm_21;
               else
                  f_cfsm_state <= s_cfsm_20;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for MIPS0 Read Signal to return to 0
            when s_cfsm_21 =>
               if (i_MEM_READ0 = '0') then
                  f_cfsm_state <= s_cfsm_22;
               else
                  f_cfsm_state <= s_cfsm_21;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
            
            -- Wait for MIPS0 Read Signal
            when s_cfsm_22 =>
               if (i_MEM_READ0 = '1') then
                  f_cfsm_state <= s_cfsm_23;
               else
                  f_cfsm_state <= s_cfsm_22;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for MIPS0 Read signal to return to 0
            when s_cfsm_23 =>
               if (i_MEM_READ0 = '0') then
                  f_cfsm_state <= s_cfsm_24;
               else
                  f_cfsm_state <= s_cfsm_23;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for MIPS0 Read signal
            when s_cfsm_24 =>
               if (i_MEM_READ0 = '1') then
                  f_cfsm_state <= s_cfsm_25;
               else
                  f_cfsm_state <= s_cfsm_24;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
            
            -- TSR MIPS is Running
            -- Wait for an error to occur or the program to finish
            when s_cfsm_25 =>
               if ((i_MEM_READ0 = '1') and (i_MEM_ADDRESS0 = k_TSR_Recovery)) then
                  f_cfsm_state <= s_cfsm_29;
               elsif (i_MEM_DONE = '1') then
                  f_cfsm_state <= s_cfsm_26;
               else
                  f_cfsm_state <= s_cfsm_25;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Interrupt communications between MIPS0 and Memory.  Wait for MIPS0 Read Signal
            when s_cfsm_26 =>
               if (i_MEM_READ0 = '1') then
                  f_cfsm_state <= s_cfsm_27;
               else
                  f_cfsm_state <= s_cfsm_26;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Transmit branch instruction to branch to TSR Start.  Wait for MIPS0 Read Signal to return to 0
            when s_cfsm_27 =>
               if (i_MEM_READ0 = '0') then
                  f_cfsm_state <= s_cfsm_28;
               else
                  f_cfsm_state <= s_cfsm_27;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for MIPS0 Read Signal
            when s_cfsm_28 =>
               if (i_MEM_READ0 = '1') then
                  f_cfsm_state <= s_cfsm_25;
               else
                  f_cfsm_state <= s_cfsm_28;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
            
            -- Start transition from TSR MIPS to TMR MIPS
            -- Wait for Memory Ready Signal
            when s_cfsm_29 =>
               if (i_MEM_READY = '1') then
                  f_cfsm_state <= s_cfsm_30;
               else
                  f_cfsm_state <= s_cfsm_29;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_30 =>
               if (i_MEM_READY = '0') then
                  f_cfsm_state <= s_cfsm_31;
               else
                  f_cfsm_state <= s_cfsm_30;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Memory Ready Signal
            when s_cfsm_31 =>
               if (i_MEM_READY = '1') then
                  f_cfsm_state <= s_cfsm_32;
               else
                  f_cfsm_state <= s_cfsm_31;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_32 =>
               if (i_MEM_READY = '0') then
                  f_cfsm_state <= s_cfsm_33;
               else
                  f_cfsm_state <= s_cfsm_32;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= i_MEM_OUT;
               
            -- Wait for Memory Ready Signal
            when s_cfsm_33 =>
               if (i_MEM_READY = '1') then
                  f_cfsm_state <= s_cfsm_34;
               else
                  f_cfsm_state <= s_cfsm_33;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_34 =>
               if (i_MEM_READY = '0') then
                  f_cfsm_state <= s_cfsm_35;
                  f_loop <= f_loop;
                  f_loop1 <= f_loop1;
               else
                  f_cfsm_state <= s_cfsm_34;
                  f_loop <= unsigned(i_MEM_IN);
                  f_loop1 <= unsigned(i_MEM_IN);
               end if;
               f_instr_count <= f_instr_count;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
            
            -- Subtract 1 from the loop count
            when s_cfsm_35 =>
               f_cfsm_state <= s_cfsm_36;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop-1;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Memory Ready Signal
            when s_cfsm_36 =>
               if (i_MEM_READY = '1') then
                  f_cfsm_state <= s_cfsm_37;
               else
                  f_cfsm_state <= s_cfsm_36;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_37 =>
               if (i_MEM_READY = '0') then
                  f_cfsm_state <= s_cfsm_38;
               else
                  f_cfsm_state <= s_cfsm_37;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Memory Ready Signal
            when s_cfsm_38 =>
               if (i_MEM_READY = '1') then
                  f_cfsm_state <= s_cfsm_39;
               else
                  f_cfsm_state <= s_cfsm_38;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_39 =>
               if (i_MEM_READY = '0') then
                  f_cfsm_state <= s_cfsm_40;
               else
                  f_cfsm_state <= s_cfsm_39;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Memory Ready Signal
            when s_cfsm_40 =>
               if (i_MEM_READY = '1') then
                  f_cfsm_state <= s_cfsm_41;
               else
                  f_cfsm_state <= s_cfsm_40;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_41 =>
               if (i_MEM_READY = '0') then
                  f_cfsm_state <= s_cfsm_42;
               else
                  f_cfsm_state <= s_cfsm_41;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Memory Ready Signal
            when s_cfsm_42 =>
               if (i_MEM_READY = '1') then
                  f_cfsm_state <= s_cfsm_43;
               else
                  f_cfsm_state <= s_cfsm_42;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_43 =>
               if (i_MEM_READY = '0') then
                  f_cfsm_state <= s_cfsm_44;
               else
                  f_cfsm_state <= s_cfsm_43;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Memory Ready Signal
            when s_cfsm_44 =>
               if (i_MEM_READY = '1') then
                  f_cfsm_state <= s_cfsm_45;
               else
                  f_cfsm_state <= s_cfsm_44;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_45 =>
               if (i_MEM_READY = '0') then
                  f_cfsm_state <= s_cfsm_46;
               else
                  f_cfsm_state <= s_cfsm_45;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Voter Read Signal
            when s_cfsm_46 =>
               if (i_MEM_READ = '1') then
                  f_cfsm_state <= s_cfsm_47;
               else
                  f_cfsm_state <= s_cfsm_46;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Voter Read Signal to return to 0
            when s_cfsm_47 =>
               if (i_MEM_READ = '0') then
                  f_cfsm_state <= s_cfsm_48;
               else
                  f_cfsm_state <= s_cfsm_47;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Voter Read Signal
            when s_cfsm_48 =>
               if (i_MEM_READ = '1') then
                  f_cfsm_state <= s_cfsm_49;
               else
                  f_cfsm_state <= s_cfsm_48;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Voter Read Signal to return to 0
            when s_cfsm_49 =>
               if (i_MEM_READ = '0') then
                  f_cfsm_state <= s_cfsm_50;
               else
                  f_cfsm_state <= s_cfsm_49;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Voter Read Signal
            when s_cfsm_50 =>
               if (i_MEM_READ = '1') then
                  f_cfsm_state <= s_cfsm_51;
               else
                  f_cfsm_state <= s_cfsm_50;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
               
            -- Wait for Voter Read Signal to return to 0
            when s_cfsm_51 =>
               if (i_MEM_READ = '0') then
                  f_cfsm_state <= s_cfsm_52;
               else
                  f_cfsm_state <= s_cfsm_51;
               end if;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
            
            -- Return to normal TMR operation
            when s_cfsm_52 =>
               f_cfsm_state <= s_cfsm_0;
               f_instr_count <= f_instr_count;
               f_loop <= f_loop;
               f_loop1 <= f_loop1;
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
            
            -- This should never happen
            when others =>
               f_cfsm_state <= s_cfsm_0;
               f_instr_count <= (others => '0');
               f_loop <= (others => '0');
               f_loop1 <= (others => '0');
               f_TEMP_ADDRESS <= f_TEMP_ADDRESS;
         end case;
      end if;
   end process cfsm;
   
   
   
   controller_output_fsm: process(i_clk, i_reset, f_cfsm_state)
   begin
      if (i_reset = '1') then
         f_MEM_ADDRESS <= (others => '0');
         f_MEM_IN <= (others => '0');
         f_MEM_OUT <= (others => '0');
         f_MEM_OUT0 <= (others => '0');
         f_MEM_READ_SEL <= (others => '0');
         f_MEM_WRITE_SEL <= (others => '0');
         f_MEM_ADDRESS_SEL <= (others => '0');
         f_MEM_READY_SEL <= (others => '0');
         f_MEM_DONE_SEL <= (others => '0');
         f_MEM_READY0_SEL <= (others => '0');
         f_MEM_READY12_SEL <= '0';
         f_MEM_RESET0_SEL <= (others => '0');
         f_MEM_RESET12_SEL <= (others => '0');
      elsif rising_edge(i_clk) then
         case f_cfsm_state is
            -- TMR MIPS is running
            -- Determine when TMR MIPS completes processing an instruction or encounters an error
            when s_cfsm_0 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "00";
               f_MEM_WRITE_SEL <= "00";
               f_MEM_ADDRESS_SEL <= "00";
               f_MEM_READY_SEL <= "00";
               f_MEM_DONE_SEL <= "00";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "00";
               f_MEM_RESET12_SEL <= "00";
            
            -- Return to state 0
            when s_cfsm_1 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "00";
               f_MEM_WRITE_SEL <= "00";
               f_MEM_ADDRESS_SEL <= "00";
               f_MEM_READY_SEL <= "00";
               f_MEM_DONE_SEL <= "00";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "00";
               f_MEM_RESET12_SEL <= "00";
               
            -- TMR MIPS has encountered an error
            when s_cfsm_2 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "00";
               f_MEM_WRITE_SEL <= "00";
               f_MEM_ADDRESS_SEL <= "00";
               f_MEM_READY_SEL <= "00";
               f_MEM_DONE_SEL <= "00";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "00";
               f_MEM_RESET12_SEL <= "00";
            
            -- Start transition from TMR MIPS to TSR MIPS
            -- Wait for Memory Ready signal
            when s_cfsm_3 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "00";
               f_MEM_WRITE_SEL <= "00";
               f_MEM_ADDRESS_SEL <= "00";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "01";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "00";
               f_MEM_RESET12_SEL <= "00";
               
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_4 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= "1010110000011111" & k_mem_location14_16;
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "11";
               f_MEM_DONE_SEL <= "01";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "00";
               f_MEM_RESET12_SEL <= "00";
               
            
            -- Wait for TMR Voter Read signal to return to 0
            when s_cfsm_5 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= "1010110000011111" & k_mem_location14_16;
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "01";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "00";
               f_MEM_RESET12_SEL <= "00";
               
            
            -- Wait for TMR Voter Write signal and watch out for an Error
            when s_cfsm_6 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= "1010110000011111" & k_mem_location14_16;
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "01";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "00";
               f_MEM_RESET12_SEL <= "00";
               
            
            -- Wait for TMR Voter Write signal to return to 0
            when s_cfsm_7 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "10";
               f_MEM_DONE_SEL <= "01";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "00";
               f_MEM_RESET12_SEL <= "00";
               
            
            -- Add 1 to the loop count
            when s_cfsm_8 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "01";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "00";
               f_MEM_RESET12_SEL <= "00";
               
            
            -- Wait for Memory Ready Signal
            when s_cfsm_9 =>
               f_MEM_ADDRESS <= k_mem_location14_32;
               f_MEM_IN <= std_logic_vector(f_loop);
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "11";
               f_MEM_ADDRESS_SEL <= "11";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "01";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "00";
               f_MEM_RESET12_SEL <= "00";
               
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_10 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "01";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "00";
               f_MEM_RESET12_SEL <= "00";
               
            
            -- Wait for Memory Ready Signal
            when s_cfsm_11 =>
               f_MEM_ADDRESS <= k_mem_location29_32;
               f_MEM_IN <= std_logic_vector(f_loop);
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "11";
               f_MEM_ADDRESS_SEL <= "11";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "01";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "00";
               f_MEM_RESET12_SEL <= "00";
               
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_12 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "01";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "00";
               f_MEM_RESET12_SEL <= "00";
               
            
            -- Wait for Memory Ready Signal
            when s_cfsm_13 =>
               f_MEM_ADDRESS <= k_mem_location30_32;
               f_MEM_IN <= k_zero_32;
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "11";
               f_MEM_ADDRESS_SEL <= "11";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "01";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "00";
               f_MEM_RESET12_SEL <= "00";
               
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_14 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "01";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "00";
               f_MEM_RESET12_SEL <= "00";
               
            -- Reset all processors
            when s_cfsm_15 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "11";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for MIPS0 Read Signal
            when s_cfsm_16 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "10";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for MIPS0 Read Signal to return to 0
            when s_cfsm_17 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= "10001100000111110000000000000000";
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "11";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "10";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for MIPS0 Read Signal
            when s_cfsm_18 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= "10001100000111110000000000000000";
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "10";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for MIPS0 Read Signal to return to 0
            when s_cfsm_19 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= std_logic_vector(f_loop1);
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "11";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "10";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for MIPS0 Read Signal
            when s_cfsm_20 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= std_logic_vector(f_loop1);
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "10";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for MIPS0 Read Signal to return to 0
            when s_cfsm_21 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= "00100011111111100000000000000000";
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "11";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "10";
               f_MEM_RESET12_SEL <= "11";
               
            
            -- Wait for MIPS0 Read Signal
            when s_cfsm_22 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= "00100011111111100000000000000000";
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "10";
               f_MEM_RESET12_SEL <= "11";
               
               
            -- Wait for MIPS0 Read signal to return to 0
            when s_cfsm_23 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= "0001000000000000" & k_TSR_LOOP_START_BRANCH;
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "11";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "10";
               f_MEM_RESET12_SEL <= "11";
               
               
            -- Wait for MIPS0 Read signal
            when s_cfsm_24 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= "0001000000000000" & k_TSR_LOOP_START_BRANCH;
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "10";
               f_MEM_RESET12_SEL <= "11";
               
            
            -- TSR MIPS is Running
            -- Wait for an error to occur or the program to finish
            when s_cfsm_25 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "01";
               f_MEM_WRITE_SEL <= "01";
               f_MEM_ADDRESS_SEL <= "01";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "01";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "01";
               f_MEM_RESET12_SEL <= "11";
               
            -- Interrupt communications between MIPS0 and Memory.  Wait for MIPS0 Read Signal
            when s_cfsm_26 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "10";
               f_MEM_RESET12_SEL <= "11";
               
            -- Transmit branch instruction to branch to TSR Start.  Wait for MIPS0 Read Signal to return to 0
            when s_cfsm_27 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= "0001000000000000" & k_TSR_START_BRANCH;
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "11";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "10";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for MIPS0 Read Signal
            when s_cfsm_28 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= "0001000000000000" & k_TSR_START_BRANCH;
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "10";
               f_MEM_RESET12_SEL <= "11";
            
            
            -- Start transition from TSR MIPS to TMR MIPS
            -- Wait for Memory Ready Signal
            when s_cfsm_29 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "11";
               f_MEM_RESET12_SEL <= "11";
               
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_30 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "11";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for Memory Ready Signal
            when s_cfsm_31 =>
               f_MEM_ADDRESS <= k_mem_location30_32;
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "11";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "11";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "11";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_32 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "11";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for Memory Ready Signal
            when s_cfsm_33 =>
               f_MEM_ADDRESS <= std_logic_vector(unsigned(k_mem_location14_32)+unsigned(f_TEMP_ADDRESS));
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "11";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "11";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "11";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_34 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "11";
               f_MEM_RESET12_SEL <= "11";
               
            
            -- Subtract 1 from the loop count
            when s_cfsm_35 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "11";
               f_MEM_RESET12_SEL <= "11";
               
               
            -- Wait for Memory Ready Signal
            when s_cfsm_36 =>
               f_MEM_ADDRESS <= k_mem_location30_32;
               f_MEM_IN <= std_logic_vector(f_loop);
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "11";
               f_MEM_ADDRESS_SEL <= "11";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "11";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_37 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "11";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for Memory Ready Signal
            when s_cfsm_38 =>
               f_MEM_ADDRESS <= k_mem_location62_32;
               f_MEM_IN <= std_logic_vector(f_loop);
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "11";
               f_MEM_ADDRESS_SEL <= "11";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "11";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_39 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "11";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for Memory Ready Signal
            when s_cfsm_40 =>
               f_MEM_ADDRESS <= k_mem_location31_32;
               f_MEM_IN <= k_mem_location02_32;
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "11";
               f_MEM_ADDRESS_SEL <= "11";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "11";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_41 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "11";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for Memory Ready Signal
            when s_cfsm_42 =>
               f_MEM_ADDRESS <= k_mem_location63_32;
               f_MEM_IN <= k_mem_location02_32;
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "11";
               f_MEM_ADDRESS_SEL <= "11";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "11";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_43 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "11";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for Memory Ready Signal
            when s_cfsm_44 =>
               f_MEM_ADDRESS <= k_mem_location64_32;
               f_MEM_IN <= k_zero_32;
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "11";
               f_MEM_ADDRESS_SEL <= "11";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "11";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for Memory Ready signal to return to 0
            when s_cfsm_45 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "11";
               f_MEM_READY0_SEL <= "10";
               f_MEM_READY12_SEL <= '1';
               f_MEM_RESET0_SEL <= "11";
               f_MEM_RESET12_SEL <= "11";
               
            -- Wait for Voter Read Signal
            when s_cfsm_46 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "01";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "10";
               f_MEM_RESET12_SEL <= "01";
               
            -- Wait for Voter Read Signal to return to 0
            when s_cfsm_47 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= "10001100000111110000000000000000";
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "11";
               f_MEM_DONE_SEL <= "01";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "10";
               f_MEM_RESET12_SEL <= "01";
               
               
            -- Wait for Voter Read Signal
            when s_cfsm_48 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "01";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "10";
               f_MEM_RESET12_SEL <= "01";
               
            -- Wait for Voter Read Signal to return to 0
            when s_cfsm_49 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= std_logic_vector(f_loop);
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "11";
               f_MEM_DONE_SEL <= "01";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "10";
               f_MEM_RESET12_SEL <= "01";
               
            -- Wait for Voter Read Signal
            when s_cfsm_50 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "01";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "10";
               f_MEM_RESET12_SEL <= "01";
               
            -- Wait for Voter Read Signal to return to 0
            when s_cfsm_51 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= k_zero_32;
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "11";
               f_MEM_DONE_SEL <= "01";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "10";
               f_MEM_RESET12_SEL <= "01";
            
            -- Return to normal TMR operation
            when s_cfsm_52 =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "10";
               f_MEM_WRITE_SEL <= "10";
               f_MEM_ADDRESS_SEL <= "10";
               f_MEM_READY_SEL <= "01";
               f_MEM_DONE_SEL <= "01";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "10";
               f_MEM_RESET12_SEL <= "01";
            
            -- This should never happen
            when others =>
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_IN <= (others => '0');
               f_MEM_OUT <= (others => '0');
               f_MEM_OUT0 <= (others => '0');
               f_MEM_READ_SEL <= "00";
               f_MEM_WRITE_SEL <= "00";
               f_MEM_ADDRESS_SEL <= "00";
               f_MEM_READY_SEL <= "00";
               f_MEM_DONE_SEL <= "00";
               f_MEM_READY0_SEL <= "00";
               f_MEM_READY12_SEL <= '0';
               f_MEM_RESET0_SEL <= "00";
               f_MEM_RESET12_SEL <= "00";
         end case;
      end if;
   end process controller_output_fsm;
   
end a_Combined_Controller_Test36;
