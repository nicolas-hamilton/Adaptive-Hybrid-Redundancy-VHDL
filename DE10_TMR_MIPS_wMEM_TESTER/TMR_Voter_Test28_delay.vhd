--| TMR_Voter_Test28_delay.vhd
--| Test the functionality of the Basic_MIPS using the MEM_EMULATOR
--| so that the controller can "read" instructions from memory, transition
--| through the appropriate states, and send the proper control signals out
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity TMR_Voter_Test28_delay is
   port (i_clk            : in  std_logic;
         i_reset          : in  std_logic;
         i_MEM_READ0      : in  std_logic;
         i_MEM_READ1      : in  std_logic;
         i_MEM_READ2      : in  std_logic;
         i_MEM_WRITE0     : in  std_logic;
         i_MEM_WRITE1     : in  std_logic;
         i_MEM_WRITE2     : in  std_logic;
         i_MEM_IN0        : in  std_logic_vector(31 downto 0);
         i_MEM_IN1        : in  std_logic_vector(31 downto 0);
         i_MEM_IN2        : in  std_logic_vector(31 downto 0);
         i_MEM_ADDRESS0   : in  std_logic_vector(31 downto 0);
         i_MEM_ADDRESS1   : in  std_logic_vector(31 downto 0);
         i_MEM_ADDRESS2   : in  std_logic_vector(31 downto 0);
         i_MEM_OUT        : in  std_logic_vector(31 downto 0);
         i_MEM_READY      : in  std_logic;
         o_MEM_READ       : out std_logic;
         o_MEM_WRITE      : out std_logic;
         o_MEM_IN         : out std_logic_vector(31 downto 0);
         o_MEM_ADDRESS    : out std_logic_vector(31 downto 0);
         o_MEM_OUT0       : out std_logic_vector(31 downto 0);
         o_MEM_OUT1       : out std_logic_vector(31 downto 0);
         o_MEM_OUT2       : out std_logic_vector(31 downto 0);
         o_MEM_READY0     : out std_logic;
         o_MEM_READY1     : out std_logic;
         o_MEM_READY2     : out std_logic;
         o_RESET0         : out std_logic;
         o_RESET1         : out std_logic;
         o_RESET2         : out std_logic;
         o_Err_Override   : out std_logic);
end TMR_Voter_Test28_delay;

architecture a_TMR_Voter_Test28_delay of TMR_Voter_Test28_delay is
--| Declare components
--| Create state machine types
   -- Create states for the voter finite state machine
   type sm_vfsm is (s_vfsm_0, s_vfsm_1, s_vfsm_2, s_vfsm_3,
                    s_vfsm_3a,s_vfsm_4, s_vfsm_5,s_vfsm_5a, 
                    s_vfsm_6, s_vfsm_7,s_vfsm_7a, s_vfsm_8,
                    s_vfsm_8a,s_vfsm_9,s_vfsm_9a,s_vfsm_10,
                    s_vfsm_11,s_vfsm_12,
                    s_vfsm_err0, s_vfsm_err1, s_vfsm_save);
   -- Create states for the voter err0 finite state machine
   type sm_verr0 is (s_verr0_0, s_verr0_1, s_verr0_2, s_verr0_3,
                     s_verr0_4, s_verr0_5, s_verr0_6, s_verr0_7,
                     s_verr0_8, s_verr0_9, s_verr0_10,s_verr0_11,
                     s_verr0_12,s_verr0_13,s_verr0_14,s_verr0_err1);
   -- Create states for the voter err1 finite state machine
   type sm_verr1 is (s_verr1_0, s_verr1_1, s_verr1_2,s_verr1_2a,
                     s_verr1_3, s_verr1_4, s_verr1_5, s_verr1_6,
                     s_verr1_6a,s_verr1_7, s_verr1_8,s_verr1_8a,
                     s_verr1_9,s_verr1_10,s_verr1_11,s_verr1_12,
                     s_verr1_13,s_verr1_14);
   -- Create states for the voter sav finite state machine
   type sm_vsave is (s_vsave_0, s_vsave_1, s_vsave_2,s_vsave_2a,
                     s_vsave_3, s_vsave_4, s_vsave_5, s_vsave_6,
                     s_vsave_6a,s_vsave_7, s_vsave_8, s_vsave_9,
                     s_vsave_10,s_vsave_10a,s_vsave_11,
                     s_vsave_12,s_vsave_err1);
                     
   -- Initialize the voter finite state macine register
   signal f_vfsm_state : sm_vfsm := s_vfsm_0;
   -- Initialize the err0 finite state macine register
   signal f_verr0_state : sm_verr0 := s_verr0_0;
   -- Initialize the err0 finite state macine register
   signal f_verr1_state : sm_verr1 := s_verr1_0;
   -- Initialize the save finite state machine register
   signal f_vsave_state : sm_vsave := s_vsave_0;
   
--| Define Signals
   -- Counter used to determine when to create a save point
   signal f_instr_count : unsigned(31 downto 0) := (others => '0');
   -- Constant used to compare instruction counter against
   constant k_save_point : unsigned(31 downto 0) := "00000000000000000010011100010000";
   
   -- Singlas to determine which processor is wrong in the s_vfsm_err0 state
   signal f_wrong0 : std_logic := '0';
   signal f_wrong1 : std_logic := '0';
   signal f_wrong2 : std_logic := '0';
   -- Determine when to return from the s_vfsm_err0 state
   signal f_done_wrong0 : std_logic := '0';
   signal f_done_wrong1 : std_logic := '0';
   signal f_done_wrong2 : std_logic := '0';
   -- Determine when to return from the s_vfsm_err1 state
   signal f_done_all_wrong : std_logic := '0';
   -- Determine when to return from the s_vfsm_save state
   signal f_done_save : std_logic := '0';
   -- Count signals to determine which register to load in error correction processes
   signal f_err0_count   : unsigned(4 downto 0) := (others => '0');
   signal f_err1_count   : unsigned(4 downto 0) := (others => '0');
   -- Count signal to determine which register to save in save point processes
   signal f_save_count   : unsigned(4 downto 0) := (others => '0');
   -- Signal to temporarily store data to be transferred from memory to processors
   -- for non-erroneous uperation
   signal f_data : std_logic_vector(31 downto 0) := (others => '0');
   -- Signal to temporarily store data to be transferred from correct processors
   -- to incorrect processor for type 0 errors
   signal f_err0_data : std_logic_vector(31 downto 0) := (others => '0');
   -- Signal to temporarily store data to be transferred from memory to processors
   -- for type 1 errors
   signal f_err1_data : std_logic_vector(31 downto 0) := (others => '0');
   -- Signal to store the address at which the error occured
   signal f_err_address : std_logic_vector(31 downto 0) := (others => '0');
   -- Signal to store the address of the current instruction
   signal f_current_address : std_logic_vector(31 downto 0) := (others => '0');
   -- Signal to store the address of the current instruction
   signal f_save_current_address : std_logic_vector(31 downto 0) := (others => '0');
   -- Signal to store the address of the instruction at which save point creation started
   signal f_save_address : std_logic_vector(31 downto 0) := (others => '0');
   -- Signals to compute the branch distance for type 0 errors
   signal w_correct_branch_distance32 : std_logic_vector(31 downto 0);
   signal w_correct_branch_distance16 : std_logic_vector(15 downto 0);
   signal w_incorrect_branch_distance32 : std_logic_vector(31 downto 0);
   signal w_incorrect_branch_distance16 : std_logic_vector(15 downto 0);
   -- Signals to compute the branch distance for type 1 errors
   signal w_err1_branch_distance32 : std_logic_vector(31 downto 0);
   signal w_err1_branch_distance16 : std_logic_vector(15 downto 0);
   -- Signals to compute the branch distance for returning after creating a save point
   signal w_save_branch_distance32 : std_logic_vector(31 downto 0);
   signal w_save_branch_distance16 : std_logic_vector(15 downto 0);
   
   -- Watchdog timers to detect a timeout error
   signal f_fsm_timer : unsigned(5 downto 0) := (others => '0');
   signal f_err0_timer : unsigned(5 downto 0) := (others => '0');
   signal f_err1_timer : unsigned(5 downto 0) := (others => '0');
   signal f_save_timer : unsigned(5 downto 0) := (others => '0');
   constant k_timeout : unsigned(5 downto 0) := "110010";
   -- Registers to keep track of memory save point (0 or 1)
   signal f_err1_save_point32 : std_logic_vector(31 downto 0) := (others => '0');
   signal f_save_save_point32 : std_logic_vector(31 downto 0) := (others => '0');
   -- Location at which backup memory location starts
   constant k_mem_location : std_logic_vector(31 downto 0) := "00000000000000000000000011001000";
   -- Constant used to access the 64th memory location (0-30=R1-R31, 31=PC, 32-62=R1-R31, 63=PC, 64=sav_point)
   constant k_256_32 : std_logic_vector(31 downto 0) := "00000000000000000000000100000000";
   -- Constant used to access the 32nd memory location (0-30=R1-R31, 31=PC, 32-62=R1-R31, 63=PC, 64=sav_point)
   constant k_128_16 : std_logic_vector(15 downto 0) := "0000000010000000";
   -- Constant used to access the 31st memory location (0-30=R1-R31, 31=PC, 32-62=R1-R31, 63=PC, 64=sav_point)
   constant k_124_32 : std_logic_vector(31 downto 0) := "00000000000000000000000001111100";
   -- Constant used to access the 63rd memory location (0-30=R1-R31, 31=PC, 32-62=R1-R31, 63=PC, 64=sav_point)
   constant k_252_32 : std_logic_vector(31 downto 0) := "00000000000000000000000011111100";
   -- Constant used to retrieve the desired PC location for type 1 error recovery
   signal f_err1_pc : std_logic_vector(31 downto 0) := (others => '0');
   
   -- Registers for holding output values
   signal f_MEM_READ      : std_logic := '0';
   signal ff_MEM_READ      : std_logic := '0';
   signal fff_MEM_READ      : std_logic := '0';
   signal f_MEM_WRITE     : std_logic := '0';
   signal ff_MEM_WRITE     : std_logic := '0';
   signal fff_MEM_WRITE     : std_logic := '0';
   signal f_MEM_IN        : std_logic_vector(31 downto 0) := (others => '0');
   signal f_MEM_ADDRESS   : std_logic_vector(31 downto 0) := (others => '0');
   signal f_MEM_OUT0      : std_logic_vector(31 downto 0) := (others => '0');
   signal f_MEM_OUT1      : std_logic_vector(31 downto 0) := (others => '0');
   signal f_MEM_OUT2      : std_logic_vector(31 downto 0) := (others => '0');
   signal f_MEM_READY0    : std_logic := '0';
   signal f_MEM_READY1    : std_logic := '0';
   signal f_MEM_READY2    : std_logic := '0';
   signal ff_MEM_READY0    : std_logic := '0';
   signal ff_MEM_READY1    : std_logic := '0';
   signal ff_MEM_READY2    : std_logic := '0';
   signal f_RESET0        : std_logic := '0';
   signal f_RESET1        : std_logic := '0';
   signal f_RESET2        : std_logic := '0';
   signal f_Err_Override	 : std_logic := '0';
   
begin
   o_MEM_READ <= f_MEM_READ and fff_MEM_READ;
   o_MEM_WRITE <= f_MEM_WRITE and fff_MEM_WRITE;
   o_MEM_IN <= f_MEM_IN;
   o_MEM_ADDRESS <= f_MEM_ADDRESS;
   o_MEM_OUT0 <= f_MEM_OUT0;
   o_MEM_OUT1 <= f_MEM_OUT1;
   o_MEM_OUT2 <= f_MEM_OUT2;
   o_MEM_READY0 <= f_MEM_READY0 and ff_MEM_READY0;
   o_MEM_READY1 <= f_MEM_READY1 and ff_MEM_READY1;
   o_MEM_READY2 <= f_MEM_READY2 and ff_MEM_READY2;
   o_RESET0 <= f_RESET0;
   o_RESET1 <= f_RESET1;
   o_RESET2 <= f_RESET2;
   o_Err_Override <= f_Err_Override;
   
   -- Compute the branch distance for correct processors when a type 0 error occurs
   w_correct_branch_distance32 <= std_logic_vector(unsigned(f_err_address) - unsigned(f_current_address));
   -- Branch instructions use 16 bit offsets that are shifted left by 2 to calculate the offset in MIPS
   w_correct_branch_distance16 <= w_correct_branch_distance32(17 downto 2);
   
   -- Compute the branch distance for the incorrect processor when a type 0 error occurs
   w_incorrect_branch_distance32 <= std_logic_vector(unsigned(f_err_address) - unsigned(k_124_32));
   -- Branch instructions use 16 bit offsets that are shifted left by 2 to calculate the offset in MIPS
   w_incorrect_branch_distance16 <= w_incorrect_branch_distance32(17 downto 2);
   
   -- Compute the branch distance for type 1 errors
   w_err1_branch_distance32 <= std_logic_vector(unsigned(f_err1_pc) - unsigned(k_124_32));
   w_err1_branch_distance16 <= w_err1_branch_distance32(17 downto 2);
   
   w_save_branch_distance32 <= std_logic_vector(unsigned(f_save_address) - unsigned(f_save_current_address)); 
   w_save_branch_distance16 <= w_save_branch_distance32(17 downto 2);
   
   vfsm: process(i_clk, i_reset, f_vfsm_state,
                 i_MEM_READ0, i_MEM_READ1, i_MEM_READ2,
                 i_MEM_WRITE0, i_MEM_WRITE1, i_MEM_WRITE2,
                 i_MEM_ADDRESS0, i_MEM_ADDRESS1, i_MEM_ADDRESS2,
                 i_MEM_IN0, i_MEM_IN1, i_MEM_IN2,
                 i_MEM_READY, i_MEM_OUT,
                 f_done_wrong0, f_done_wrong1, f_done_wrong2,
                 f_done_all_wrong, f_done_save)
   begin
      if (i_reset = '1') then
         f_vfsm_state      <= s_vfsm_0;
         f_instr_count      <= (others => '0');
         f_wrong0            <= '0';
         f_wrong1            <= '0';
         f_wrong2            <= '0';
         f_fsm_timer         <= (others => '0');
      elsif rising_edge(i_clk) then
         case f_vfsm_state is
            -- Determine when all three processors are attempting to read or write.
            when s_vfsm_0 =>
               if ((i_MEM_READ0 = '1') and (i_MEM_READ1 = '1')) or ((i_MEM_READ1 = '1') and (i_MEM_READ2 = '1')) or ((i_MEM_READ0 = '1') and (i_MEM_READ2 = '1')) then
                  f_vfsm_state <= s_vfsm_1;
                  f_fsm_timer <= (others => '0');
                  f_instr_count <= f_instr_count;
               elsif f_fsm_timer > k_timeout then
                  f_vfsm_state <= s_vfsm_err1;
                  f_instr_count <= (others => '0');
               else
                  f_vfsm_state <= s_vfsm_0;
                  f_fsm_timer <= f_fsm_timer + 1;
                  f_instr_count <= f_instr_count;
               end if;
            
            -- Determine whether an error has occured with one or more processors when reading an instruction from memory
            when s_vfsm_1 =>
               -- All three processors attempting to read a word from the same memory address
               if (i_MEM_READ0 = '1')  and (i_MEM_READ1 = '1') and (i_MEM_READ2 = '1') and (i_MEM_ADDRESS0 = i_MEM_ADDRESS1) and (i_MEM_ADDRESS1 = i_MEM_ADDRESS2) then
                  if f_instr_count >= k_save_point then
                     f_vfsm_state <= s_vfsm_save;
                     f_save_address <= i_MEM_ADDRESS0;
                     f_instr_count <= (others => '0');
                  else
                     f_vfsm_state <= s_vfsm_2;
                     f_instr_count <= f_instr_count + 1;
                     f_err_address <= i_MEM_ADDRESS0;
                  end if;
               -- Processors 0 and 1 attempting to read a word from the same memory address, and processor 2 in error
               elsif (i_MEM_READ0 = '1')  and (i_MEM_READ1 = '1') and (i_MEM_ADDRESS0 = i_MEM_ADDRESS1) then
                  f_vfsm_state <= s_vfsm_err0;
                  f_wrong2 <= '1';
                  f_err_address <= i_MEM_ADDRESS0;
                  f_instr_count <= f_instr_count;
               -- Processors 1 and 2 attempting to read a word from the same memory address, and processor 0 in error
               elsif (i_MEM_READ1 = '1')  and (i_MEM_READ2 = '1') and (i_MEM_ADDRESS1 = i_MEM_ADDRESS2) then
                  f_vfsm_state <= s_vfsm_err0;
                  f_wrong0 <= '1';
                  f_err_address <= i_MEM_ADDRESS1;
                  f_instr_count <= f_instr_count;
               -- Processors 0 and 2 attempting to read a word from the same memory address, and processor 1 in error
               elsif (i_MEM_READ0 = '1')  and (i_MEM_READ2 = '1') and (i_MEM_ADDRESS0 = i_MEM_ADDRESS2) then
                  f_vfsm_state <= s_vfsm_err0;
                  f_wrong1 <= '1';
                  f_err_address <= i_MEM_ADDRESS0;
                  f_instr_count <= f_instr_count;
               else
                  f_vfsm_state <= s_vfsm_err1;
                  f_instr_count <= (others => '0');
               end if;
            
            -- Request data from memory by sending address and awaiting response from memory.
            when s_vfsm_2 =>
               f_instr_count <= f_instr_count;
               -- Data has been returned from memory
               if i_MEM_READY = '1' then
                  f_vfsm_state <= s_vfsm_3;
                  f_data <= i_MEM_OUT;
               -- Data has not yet returned from memory
               else
                  f_vfsm_state <= s_vfsm_2;
               end if;
            
            -- Pass the instruction to all three processors
            when s_vfsm_3 =>
               -- If all three processors have received the instruction...
               if (i_MEM_READ0 = '0') and (i_MEM_READ1 = '0') and (i_MEM_READ2 = '0') then
                  f_instr_count <= f_instr_count;
                  f_vfsm_state <= s_vfsm_3a;
                  f_fsm_timer <= (others => '0');
               -- One of the processors has not received the instruction prior to the timeout
               elsif f_fsm_timer > k_timeout then
                  f_vfsm_state <= s_vfsm_err1;
                  f_fsm_timer <= (others => '0');
                  f_instr_count <= (others => '0');
               -- At least one of the three processors has not received the instruction yet.
               else
                  f_vfsm_state <= s_vfsm_3;
                  f_fsm_timer <= f_fsm_timer + 1;
                  f_instr_count <= f_instr_count;
               end if;
            -- Wait for memory ready signal to return to 0
            when s_vfsm_3a =>
               if i_MEM_READY = '0' then
                  -- Instruction is a load word instruction
                  if i_MEM_OUT(31 downto 26) = "100011" then
                     f_vfsm_state <= s_vfsm_4;
                  -- Instruction is a store word instruction
                  elsif i_MEM_OUT(31 downto 26) = "101011" then
                     f_vfsm_state <= s_vfsm_8;
                  -- Instruction is not a load or store word instruction
                  else
                     f_vfsm_state <= s_vfsm_0;
                  end if;
                  f_fsm_timer <= (others => '0');
               else
                  f_vfsm_state <= s_vfsm_3a;
               end if;
            
            -- This is a load word operation.  Wait for all three processors to request data from memory
            when s_vfsm_4 =>
               if ((i_MEM_READ0 = '1')  and (i_MEM_READ1 = '1')) or ((i_MEM_READ1 = '1')  and (i_MEM_READ2 = '1')) or ((i_MEM_READ0 = '1')  and (i_MEM_READ2 = '1')) then
                  f_vfsm_state <= s_vfsm_5;
                  f_fsm_timer <= (others => '0');
                  f_instr_count <= f_instr_count;
               elsif f_fsm_timer > k_timeout then
                  f_instr_count <= f_instr_count;
                  f_vfsm_state <= s_vfsm_err1;
                  f_fsm_timer <= (others => '0');
                  f_instr_count <= (others => '0');
               else
                  f_vfsm_state <= s_vfsm_4;
                  f_fsm_timer <= f_fsm_timer + 1;
                  f_instr_count <= f_instr_count;
               end if;
            
            -- Check to make sure all three processors agree.  If not, at least one processor is in error.
            when s_vfsm_5 =>
               -- All three processors attempting to read a word from the same memory address
               if (i_MEM_READ0 = '1')  and (i_MEM_READ1 = '1') and (i_MEM_READ2 = '1') and (i_MEM_ADDRESS0 = i_MEM_ADDRESS1) and (i_MEM_ADDRESS1 = i_MEM_ADDRESS2) then
                  f_vfsm_state <= s_vfsm_6;
                  f_instr_count <= f_instr_count;
               -- Processors 0 and 1 attempting to read a word from the same memory address, and processor 2 in error
               elsif (i_MEM_READ0 = '1')  and (i_MEM_READ1 = '1') and (i_MEM_ADDRESS0 = i_MEM_ADDRESS1) then
                  f_vfsm_state <= s_vfsm_5a;
                  f_wrong2 <= '1';
                  f_instr_count <= f_instr_count;
               -- Processors 1 and 2 attempting to read a word from the same memory address, and processor 0 in error
               elsif (i_MEM_READ1 = '1')  and (i_MEM_READ2 = '1') and (i_MEM_ADDRESS1 = i_MEM_ADDRESS2) then
                  f_vfsm_state <= s_vfsm_5a;
                  f_wrong0 <= '1';
                  f_instr_count <= f_instr_count;
               -- Processors 0 and 2 attempting to read a word from the same memory address, and processor 1 in error
               elsif (i_MEM_READ0 = '1')  and (i_MEM_READ2 = '1') and (i_MEM_ADDRESS0 = i_MEM_ADDRESS2) then
                  f_vfsm_state <= s_vfsm_5a;
                  f_wrong1 <= '1';
                  f_instr_count <= f_instr_count;
               else
                  f_vfsm_state <= s_vfsm_err1;
                  f_instr_count <= (others => '0');
               end if;
               
            -- When a read error has occured because one processor disagrees, send the mem ready signal and wait for
            -- the mem read signals to return to zero
            when s_vfsm_5a =>
               if (f_wrong0 = '1') then
                  if (i_MEM_READ1 = '0') and (i_MEM_READ2 = '0') then
                     f_vfsm_state <= s_vfsm_err0;
                     f_fsm_timer <= (others => '0');
                     f_instr_count <= f_instr_count;
                  elsif f_fsm_timer > k_timeout then
                     f_vfsm_state <= s_vfsm_err1;
                     f_fsm_timer <= (others => '0');
                     f_instr_count <= (others => '0');
                  else
                     f_vfsm_state <= s_vfsm_5a;
                     f_fsm_timer <= f_fsm_timer + 1;
                     f_instr_count <= f_instr_count;
                  end if;
               elsif (f_wrong1 = '1') then
                  if (i_MEM_READ0 = '0') and (i_MEM_READ2 = '0') then
                     f_vfsm_state <= s_vfsm_err0;
                     f_fsm_timer <= (others => '0');
                     f_instr_count <= f_instr_count;
                  elsif f_fsm_timer > k_timeout then
                     f_vfsm_state <= s_vfsm_err1;
                     f_fsm_timer <= (others => '0');
                     f_instr_count <= (others => '0');
                  else
                     f_vfsm_state <= s_vfsm_5a;
                     f_fsm_timer <= f_fsm_timer + 1;
                     f_instr_count <= f_instr_count;
                  end if;
                  
               elsif (f_wrong2 = '1') then
                  if (i_MEM_READ0 = '0') and (i_MEM_READ1 = '0') then
                     f_vfsm_state <= s_vfsm_err0;
                     f_fsm_timer <= (others => '0');
                     f_instr_count <= f_instr_count;
                  elsif f_fsm_timer > k_timeout then
                     f_vfsm_state <= s_vfsm_err1;
                     f_fsm_timer <= (others => '0');
                     f_instr_count <= (others => '0');
                  else
                     f_vfsm_state <= s_vfsm_5a;
                     f_fsm_timer <= f_fsm_timer + 1;
                     f_instr_count <= f_instr_count;
                  end if;
               end if;
            
            -- Request data from memory by sending address and awaiting response from memory.
            when s_vfsm_6 =>
               f_instr_count <= f_instr_count;
               -- Data has been returned from memory
               if (i_MEM_READY = '1') then
                  f_vfsm_state <= s_vfsm_7;
                  f_data <= i_MEM_OUT;
               -- Data has not yet returned from memory
               else
                  f_vfsm_state <= s_vfsm_6;
               end if;
            
            -- Pass data back to all three processors
            when s_vfsm_7 =>
               -- If all three processors have received the data...
               if (i_MEM_READ0 = '0') and (i_MEM_READ1 = '0') and (i_MEM_READ2 = '0') then
                  f_vfsm_state <= s_vfsm_7a;
                  f_instr_count <= f_instr_count;
               elsif f_fsm_timer > k_timeout then
                  f_vfsm_state <= s_vfsm_err1;
                  f_fsm_timer <= (others => '0');
                  f_instr_count <= (others => '0');
               -- At least one of the three processors has not received the instruction.
               else
                  f_vfsm_state <= s_vfsm_7;
                  f_fsm_timer <= f_fsm_timer + 1;
                  f_instr_count <= f_instr_count;
               end if;
               
            when s_vfsm_7a =>
               if (i_MEM_READY = '0') then
                  f_vfsm_state <= s_vfsm_0;
               else
                  f_vfsm_state <= s_vfsm_7a;
               end if;
                  f_instr_count <= f_instr_count;
                  f_fsm_timer <= (others => '0');
               
            -- This is a store word operation.  Wait for at least two of three processors to send data to memory
            when s_vfsm_8 =>
               if ((i_MEM_WRITE0 = '1')  and (i_MEM_WRITE1 = '1')) or ((i_MEM_WRITE1 = '1')  and (i_MEM_WRITE2 = '1')) or ((i_MEM_WRITE0 = '1')  and (i_MEM_WRITE2 = '1')) then
                  f_vfsm_state <= s_vfsm_9;
                  f_fsm_timer <= (others => '0');
                  f_instr_count <= f_instr_count;
               elsif f_fsm_timer > k_timeout then
                  f_vfsm_state <= s_vfsm_err1;
                  f_fsm_timer <= (others => '0');
                  f_instr_count <= (others => '0');
               else
                  f_vfsm_state <= s_vfsm_8;
                  f_fsm_timer <= f_fsm_timer + 1;
                  f_instr_count <= f_instr_count;
               end if;
            
            -- Check to make sure all three processors agree.  If not, at least one processor is in error.
            when s_vfsm_9 =>
               -- All three processors attempting to write a word to the same memory address
               if (i_MEM_WRITE0 = '1')  and (i_MEM_WRITE1 = '1') and (i_MEM_WRITE2 = '1') and (i_MEM_ADDRESS0 = i_MEM_ADDRESS1) and (i_MEM_ADDRESS1 = i_MEM_ADDRESS2) then
                  -- Check to make sure all three processors are attempting to write the same word to memory
                  if (i_MEM_IN0 = i_MEM_IN1) and (i_MEM_IN1 = i_MEM_IN2) then
                     f_vfsm_state <= s_vfsm_10;
                     f_instr_count <= f_instr_count;
                  -- Processors 0 and 1 attempting to write the same data and processor 2 attempting to write different data
                  elsif (i_MEM_IN0 = i_MEM_IN1) then
                     f_vfsm_state <= s_vfsm_9a;
                     f_wrong2 <= '1';
                     f_instr_count <= f_instr_count;
                  -- Processors 1 and 2 attempting to write the same data and processor 0 attempting to write different data
                  elsif (i_MEM_IN1 = i_MEM_IN2) then
                     f_vfsm_state <= s_vfsm_9a;
                     f_wrong0 <= '1';
                     f_instr_count <= f_instr_count;
                  -- Processors 0 and 2 attempting to write the same data and processor 1 attempting to write different data
                  elsif (i_MEM_IN0 = i_MEM_IN2) then
                     f_vfsm_state <= s_vfsm_9a;
                     f_wrong1 <= '1';
                     f_instr_count <= f_instr_count;
                  -- All processors are attempting to write different data
                  else
                     f_vfsm_state <= s_vfsm_err1;
                     f_instr_count <= (others => '0');
                  end if;
               -- Processors 0 and 1 attempting to write a word to the same memory address, and processor 2 in error
               elsif (i_MEM_WRITE0 = '1')  and (i_MEM_WRITE1 = '1') and (i_MEM_ADDRESS0 = i_MEM_ADDRESS1) then
                  -- Check to make sure processors 0 and 1 are attempting to write the same data
                  if (i_MEM_IN0 = i_MEM_IN1) then
                     f_vfsm_state <= s_vfsm_9a;
                     f_wrong2 <= '1';
                     f_err_address <= i_MEM_ADDRESS0;
                     f_instr_count <= f_instr_count;
                  else
                     f_vfsm_state <= s_vfsm_err1;
                     f_instr_count <= (others => '0');
                  end if;
               -- Processors 1 and 2 attempting to write a word to the same memory address, and processor 0 in error
               elsif (i_MEM_WRITE1 = '1')  and (i_MEM_WRITE2 = '1') and (i_MEM_ADDRESS1 = i_MEM_ADDRESS2) then
                  -- Check to make sure processors 1 and 2 are attempting to write the same data
                  if (i_MEM_IN1 = i_MEM_IN2) then
                     f_vfsm_state <= s_vfsm_9a;
                     f_wrong0 <= '1';
                     f_err_address <= i_MEM_ADDRESS1;
                     f_instr_count <= f_instr_count;
                  else
                     f_vfsm_state <= s_vfsm_err1;
                     f_instr_count <= (others => '0');
                  end if;
               -- Processors 0 and 2 attempting to read a word from the same memory address, and processor 1 in error
               elsif (i_MEM_WRITE0 = '1')  and (i_MEM_WRITE2 = '1') and (i_MEM_ADDRESS0 = i_MEM_ADDRESS2) then
                  -- Check to make sure processors 0 and 2 are attempting to write the same data
                  if (i_MEM_IN0 = i_MEM_IN2) then
                     f_vfsm_state <= s_vfsm_9a;
                     f_wrong1 <= '1';
                     f_err_address <= i_MEM_ADDRESS0;
                     f_instr_count <= f_instr_count;
                  else
                     f_vfsm_state <= s_vfsm_err1;
                     f_instr_count <= (others => '0');
                  end if;
               else
                  f_vfsm_state <= s_vfsm_err1;
                  f_instr_count <= (others => '0');
               end if;
            
            -- When a write error has occured because one processor disagrees, send the mem ready signal and wait for
            -- the mem write signals to return to zero
            when s_vfsm_9a =>
               if (f_wrong0 = '1') then
                  if (i_MEM_WRITE1 = '0') and (i_MEM_WRITE2 = '0') then
                     f_vfsm_state <= s_vfsm_err0;
                     f_fsm_timer <= (others => '0');
                     f_instr_count <= f_instr_count;
                  elsif f_fsm_timer > k_timeout then
                     f_vfsm_state <= s_vfsm_err1;
                     f_fsm_timer <= (others => '0');
                     f_instr_count <= (others => '0');
                  else
                     f_vfsm_state <= s_vfsm_9a;
                     f_fsm_timer <= f_fsm_timer + 1;
                     f_instr_count <= f_instr_count;
                  end if;
               elsif (f_wrong1 = '1') then
                  if (i_MEM_WRITE0 = '0') and (i_MEM_WRITE2 = '0') then
                     f_vfsm_state <= s_vfsm_err0;
                     f_fsm_timer <= (others => '0');
                     f_instr_count <= f_instr_count;
                  elsif f_fsm_timer > k_timeout then
                     f_vfsm_state <= s_vfsm_err1;
                     f_fsm_timer <= (others => '0');
                     f_instr_count <= (others => '0');
                  else
                     f_vfsm_state <= s_vfsm_9a;
                     f_fsm_timer <= f_fsm_timer + 1;
                     f_instr_count <= f_instr_count;
                  end if;
                  
               elsif (f_wrong2 = '1') then
                  if (i_MEM_WRITE0 = '0') and (i_MEM_WRITE1 = '0') then
                     f_vfsm_state <= s_vfsm_err0;
                     f_fsm_timer <= (others => '0');
                     f_instr_count <= f_instr_count;
                  elsif f_fsm_timer > k_timeout then
                     f_vfsm_state <= s_vfsm_err1;
                     f_fsm_timer <= (others => '0');
                     f_instr_count <= (others => '0');
                  else
                     f_vfsm_state <= s_vfsm_9a;
                     f_fsm_timer <= f_fsm_timer + 1;
                     f_instr_count <= f_instr_count;
                  end if;
               end if;
            -- Write data to memory by sending address and data and awaiting response from memory.
            when s_vfsm_10 =>
               f_instr_count <= f_instr_count;
               -- Data has been written to memory
               if (i_MEM_READY = '1') then
                  f_vfsm_state <= s_vfsm_11;
               -- Data has not yet been written to memory
               else
                  f_vfsm_state <= s_vfsm_10;
               end if;
            
            -- Pass MEM_READY signal back to all processors
            when s_vfsm_11 =>
               -- If all three processors have received the data...
               if (i_MEM_WRITE0 = '0') and (i_MEM_WRITE1 = '0') and (i_MEM_WRITE2 = '0') then
                  f_vfsm_state <= s_vfsm_12;
                  f_fsm_timer <= (others => '0');
                  f_instr_count <= f_instr_count;
               elsif f_fsm_timer > k_timeout then
                  f_vfsm_state <= s_vfsm_err1;
                  f_fsm_timer <= (others => '0');
                  f_instr_count <= (others => '0');
               -- At least one of the three processors has not received the instruction.
               else
                  f_vfsm_state <= s_vfsm_11;
                  f_fsm_timer <= f_fsm_timer + 1;
                  f_instr_count <= f_instr_count;
               end if;
               
            when s_vfsm_12 =>
               if (i_MEM_READY = '0') then
                  f_vfsm_state <= s_vfsm_0;
               else
                  f_vfsm_state <= s_vfsm_12;
               end if;
                  f_fsm_timer <= (others => '0');
                  f_instr_count <= f_instr_count;
            
            -- Enter this state when one of three processors are wrong
            when s_vfsm_err0 =>
               if (f_wrong0 = '1') and (f_done_wrong0 = '1') then
                  if (i_MEM_READ0 = '1') then
                     f_vfsm_state <= s_vfsm_0;
                     f_wrong0 <= '0';
                     f_instr_count <= f_instr_count;
                  elsif f_fsm_timer > k_timeout then
                     f_vfsm_state <= s_vfsm_err1;
                     f_fsm_timer <= (others => '0');
                     f_instr_count <= (others => '0');
                  else
                     f_vfsm_state <= s_vfsm_err0;
                     f_fsm_timer <= f_fsm_timer + 1;
                     f_instr_count <= f_instr_count;
                  end if;
               elsif (f_wrong1 = '1') and (f_done_wrong1 = '1') then
                  if (i_MEM_READ1 = '1') then
                     f_vfsm_state <= s_vfsm_0;
                     f_wrong1 <= '0';
                     f_instr_count <= f_instr_count;
                  elsif f_fsm_timer > k_timeout then
                     f_vfsm_state <= s_vfsm_err1;
                     f_fsm_timer <= (others => '0');
                     f_instr_count <= (others => '0');
                  else
                     f_vfsm_state <= s_vfsm_err0;
                     f_fsm_timer <= f_fsm_timer + 1;
                     f_instr_count <= f_instr_count;
                  end if;
               elsif (f_wrong2 = '1') and (f_done_wrong2 = '1') then
                  if (i_MEM_READ2 = '1') then
                     f_vfsm_state <= s_vfsm_0;
                     f_wrong2 <= '0';
                     f_instr_count <= f_instr_count;
                  elsif f_fsm_timer > k_timeout then
                     f_vfsm_state <= s_vfsm_err1;
                     f_fsm_timer <= (others => '0');
                     f_instr_count <= (others => '0');
                  else
                     f_vfsm_state <= s_vfsm_err0;
                     f_fsm_timer <= f_fsm_timer + 1;
                     f_instr_count <= f_instr_count;
                  end if;
               elsif f_verr0_state = s_verr0_err1 then
                  f_vfsm_state <= s_vfsm_err1;
                  f_wrong0 <= '0';
                  f_wrong1 <= '0';
                  f_wrong2 <= '0';
                  f_fsm_timer <= (others => '0');
                  f_instr_count <= (others => '0');
               else
                  f_vfsm_state <= s_vfsm_err0;
                  f_instr_count <= f_instr_count;
               end if;
            
            -- Enter this state when all three processors are wrong
            when s_vfsm_err1 =>
               f_instr_count <= (others => '0');
               if (f_done_all_wrong = '1') then
                  f_vfsm_state <= s_vfsm_0;
               else
                  f_vfsm_state <= s_vfsm_err1;
               end if;
            -- Enter this state when it is time to create a save point from which a recovery may take place
            when s_vfsm_save =>
               f_instr_count <= (others => '0');
               if (f_done_save = '1') then
                  f_vfsm_state <= s_vfsm_0;
               elsif (f_vsave_state = s_vsave_err1) then
                  f_vfsm_state <= s_vfsm_err1;
               else
                  f_vfsm_state <= s_vfsm_save;
               end if;
            -- This should never happen
            when others =>
            
            
         end case;
      end if;
   end process vfsm;
   
   err0: process(i_clk, i_reset, f_vfsm_state, f_verr0_state,
                 i_MEM_READ0, i_MEM_READ1, i_MEM_READ2,
                 i_MEM_WRITE0, i_MEM_WRITE1, i_MEM_WRITE2,
                 i_MEM_ADDRESS0, i_MEM_ADDRESS1, i_MEM_ADDRESS2,
                 i_MEM_IN0, i_MEM_IN1, i_MEM_IN2,
                 i_MEM_READY, i_MEM_OUT,
                 f_err0_timer)
   begin
      if (i_reset = '1') then
         f_verr0_state <= s_verr0_0;
         f_done_wrong0 <= '0';
         f_done_wrong1 <= '0';
         f_done_wrong2 <= '0';
         f_err0_timer <= (others => '0');
         f_err0_count <= (others => '0');
      elsif rising_edge(i_clk) then
         if f_vfsm_state = s_vfsm_err0 then
            case f_verr0_state is
               -- Waiting for an error to occur in one of the processors
               when s_verr0_0 =>
                  f_verr0_state <= s_verr0_1;
               
               -- Reset the processor that is in error
               when s_verr0_1 =>
                  f_verr0_state <= s_verr0_2;
               
               --| Copy data from correct processors to incorrect processor one register at a time
               -- Wait for correct processors to attempt to retrieve an instruction from memory`
               when s_verr0_2 =>
                  -- If processor 0 is wrong
                  if (f_wrong0 = '1') then
                     if (i_MEM_READ1 = '1') and (i_MEM_READ2 = '1') and (i_MEM_ADDRESS1 = i_MEM_ADDRESS2) then
                        f_verr0_state <= s_verr0_3;
                        f_err0_timer <= (others => '0');
                        f_current_address <= i_MEM_ADDRESS1;
                     elsif (i_MEM_READ1 = '1') and (i_MEM_READ2 = '1') then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_2;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 1 is wrong
                  elsif (f_wrong1 = '1') then
                     if (i_MEM_READ0 = '1') and (i_MEM_READ2 = '1') and (i_MEM_ADDRESS0 = i_MEM_ADDRESS2) then
                        f_verr0_state <= s_verr0_3;
                        f_err0_timer <= (others => '0');
                        f_current_address <= i_MEM_ADDRESS0;
                     elsif (i_MEM_READ0 = '1') and (i_MEM_READ2 = '1') then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_2;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 2 is wrong
                  else
                     if (i_MEM_READ0 = '1') and (i_MEM_READ1 = '1') and (i_MEM_ADDRESS0 = i_MEM_ADDRESS1) then
                        f_verr0_state <= s_verr0_3;
                        f_err0_timer <= (others => '0');
                        f_current_address <= i_MEM_ADDRESS0;
                     elsif (i_MEM_READ0 = '1') and (i_MEM_READ1 = '1') then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_2;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  end if;
               
               -- Issue store word commands to the correct processors
               when s_verr0_3 =>
                  -- If processor 0 is wrong
                  if (f_wrong0 = '1') then
                     if (i_MEM_READ1 = '0') and (i_MEM_READ2 = '0') then
                        f_verr0_state <= s_verr0_4;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_3;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 1 is wrong
                  elsif (f_wrong1 = '1') then
                     if (i_MEM_READ0 = '0') and (i_MEM_READ2 = '0') then
                        f_verr0_state <= s_verr0_4;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_3;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 2 is wrong
                  else
                     if (i_MEM_READ0 = '0') and (i_MEM_READ1 = '0') then
                        f_verr0_state <= s_verr0_4;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_3;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  end if;
               
               -- Wait for correct processors to issue store word requests
               when s_verr0_4 =>
                  -- If processor 0 is wrong
                  if (f_wrong0 = '1') then
                     if (i_MEM_WRITE1 = '1') and (i_MEM_WRITE2 = '1') then
                        f_verr0_state <= s_verr0_5;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_4;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 1 is wrong
                  elsif (f_wrong1 = '1') then
                     if (i_MEM_WRITE0 = '1') and (i_MEM_WRITE2 = '1') then
                        f_verr0_state <= s_verr0_5;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_4;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 2 is wrong
                  else
                     if (i_MEM_WRITE0 = '1') and (i_MEM_WRITE1 = '1') then
                        f_verr0_state <= s_verr0_5;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_4;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  end if;
               
               -- Check that data from the correct processors is a match and wait for write signals to return to 0
               when s_verr0_5 =>
                  -- If processor 0 is wrong
                  if (f_wrong0 = '1') then
                     if (i_MEM_WRITE1 = '0') and (i_MEM_WRITE2 = '0') then
                        if (i_MEM_IN1 = i_MEM_IN2) then
                           f_verr0_state <= s_verr0_6;
                           f_err0_data <= i_MEM_IN1;
                           f_err0_timer <= (others => '0');
                        else
                           f_verr0_state <= s_verr0_err1;
                           f_err0_timer <= (others => '0');
                        end if;
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_5;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 1 is wrong
                  elsif (f_wrong1 = '1') then
                     if (i_MEM_WRITE0 = '0') and (i_MEM_WRITE2 = '0') then
                        if (i_MEM_IN0 = i_MEM_IN2) then
                           f_verr0_state <= s_verr0_6;
                           f_err0_data <= i_MEM_IN0;
                        else
                           f_verr0_state <= s_verr0_err1;
                           f_err0_timer <= (others => '0');
                        end if;
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_5;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 2 is wrong
                  else
                     if (i_MEM_WRITE0 = '0') and (i_MEM_WRITE1 = '0') then
                        if (i_MEM_IN0 = i_MEM_IN1) then
                           f_verr0_state <= s_verr0_6;
                           f_err0_data <= i_MEM_IN0;
                        else
                           f_verr0_state <= s_verr0_err1;
                           f_err0_timer <= (others => '0');
                        end if;
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_5;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  end if;
               
               -- Wait for incorrect processor to attempt to retrieve an instruction from memory
               when s_verr0_6 =>
                  -- If processor 0 is wrong
                  if (f_wrong0 = '1') then
                     if (i_MEM_READ0 = '1') then
                        f_verr0_state <= s_verr0_7;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_6;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 1 is wrong
                  elsif (f_wrong1 = '1') then
                     if (i_MEM_READ1 = '1') then
                        f_verr0_state <= s_verr0_7;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_6;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 2 is wrong
                  else
                     if (i_MEM_READ2 = '1') then
                        f_verr0_state <= s_verr0_7;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_6;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  end if;
               
               -- Issue load word command to the incorrect processor
               when s_verr0_7 =>
                  -- If processor 0 is wrong
                  if (f_wrong0 = '1') then
                     if (i_MEM_READ0 = '0') then
                        f_verr0_state <= s_verr0_8;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_7;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 1 is wrong
                  elsif (f_wrong1 = '1') then
                     if (i_MEM_READ1 = '0') then
                        f_verr0_state <= s_verr0_8;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_7;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 2 is wrong
                  else
                     if (i_MEM_READ2 = '0') then
                        f_verr0_state <= s_verr0_8;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_7;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  end if;
               
               -- Wait for incorrect processor to attempt to load the requested data from memory
               when s_verr0_8 =>
                  -- If processor 0 is wrong
                  if (f_wrong0 = '1') then
                     if (i_MEM_READ0 = '1') then
                        f_verr0_state <= s_verr0_9;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_8;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 1 is wrong
                  elsif (f_wrong1 = '1') then
                     if (i_MEM_READ1 = '1') then
                        f_verr0_state <= s_verr0_9;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_8;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 2 is wrong
                  else
                     if (i_MEM_READ2 = '1') then
                        f_verr0_state <= s_verr0_9;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_8;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  end if;
                  
               -- Return desired data to the incorrect processor
               when s_verr0_9 =>
                  -- If processor 0 is wrong
                  if (f_wrong0 = '1') then
                     if (i_MEM_READ0 = '0') then
                        -- If all the registers have been copied
                        if (to_integer(f_err0_count) = 30) then
                           f_verr0_state <= s_verr0_10;
                           f_err0_count <= (others => '0');
                        -- If all the registers have not been copied
                        else
                           f_verr0_state <= s_verr0_2;
                           f_err0_count <= f_err0_count + 1;
                        end if;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_9;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 1 is wrong
                  elsif (f_wrong1 = '1') then
                     if (i_MEM_READ1 = '0') then
                        -- If all the registers have been copied
                        if (to_integer(f_err0_count) = 30) then
                           f_verr0_state <= s_verr0_10;
                           f_err0_count <= (others => '0');
                        -- If all the registers have not been copied
                        else
                           f_verr0_state <= s_verr0_2;
                           f_err0_count <= f_err0_count + 1;
                        end if;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     end if;
                  -- If processor 2 is wrong
                  else
                     if (i_MEM_READ2 = '0') then
                        -- If all the registers have been copied
                        if (to_integer(f_err0_count) = 30) then
                           f_verr0_state <= s_verr0_10;
                           f_err0_count <= (others => '0');
                        -- If all the registers have not been copied
                        else
                           f_verr0_state <= s_verr0_2;
                           f_err0_count <= f_err0_count + 1;
                        end if;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_9;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  end if;
                  
               --| Return processor's program counters to the point at which the error was encountered
               --Wait for correct processors to request next instruction
               when s_verr0_10 =>
                  -- If processor 0 is wrong
                  if (f_wrong0 = '1') then
                     if (i_MEM_READ1 = '1') and (i_MEM_READ2 = '1') and (i_MEM_ADDRESS1 = i_MEM_ADDRESS2) then
                        f_verr0_state <= s_verr0_11;
                        f_err0_timer <= (others => '0');
                        f_current_address <= i_MEM_ADDRESS1;
                     elsif (i_MEM_READ1 = '1') and (i_MEM_READ2 = '1') then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_10;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 1 is wrong
                  elsif (f_wrong1 = '1') then
                     if (i_MEM_READ0 = '1') and (i_MEM_READ2 = '1') and (i_MEM_ADDRESS0 = i_MEM_ADDRESS2) then
                        f_verr0_state <= s_verr0_11;
                        f_err0_timer <= (others => '0');
                        f_current_address <= i_MEM_ADDRESS0;
                     elsif (i_MEM_READ0 = '1') and (i_MEM_READ2 = '1') then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_10;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 2 is wrong
                  else
                     if (i_MEM_READ0 = '1') and (i_MEM_READ1 = '1') and (i_MEM_ADDRESS0 = i_MEM_ADDRESS1) then
                        f_verr0_state <= s_verr0_11;
                        f_err0_timer <= (others => '0');
                        f_current_address <= i_MEM_ADDRESS0;
                     elsif (i_MEM_READ0 = '1') and (i_MEM_READ1 = '1') then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_10;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  end if;
                  
               -- Issue branch command to correct processors to return to the instruction call
               -- that caused the error.  Wait for processors to acknowledge command
               when s_verr0_11 =>
                  -- If processor 0 is wrong
                  if (f_wrong0 = '1') then
                     if (i_MEM_READ1 = '0') and (i_MEM_READ2 = '0') then
                        f_verr0_state <= s_verr0_12;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_11;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 1 is wrong
                  elsif (f_wrong1 = '1') then
                     if (i_MEM_READ0 = '0') and (i_MEM_READ2 = '0') then
                        f_verr0_state <= s_verr0_12;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_11;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 2 is wrong
                  else
                     if (i_MEM_READ0 = '0') and (i_MEM_READ1 = '0') then
                        f_verr0_state <= s_verr0_12;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_11;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  end if;
                  
               --Wait for incorrect processor to request next instruction
               when s_verr0_12 =>
                  -- If processor 0 is wrong
                  if (f_wrong0 = '1') then
                     if (i_MEM_READ0 = '1') then
                        f_verr0_state <= s_verr0_13;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_12;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 1 is wrong
                  elsif (f_wrong1 = '1') then
                     if (i_MEM_READ1 = '1') then
                        f_verr0_state <= s_verr0_13;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_12;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 2 is wrong
                  else
                     if (i_MEM_READ2 = '1') then
                        f_verr0_state <= s_verr0_13;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_12;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  end if;
                  
               -- Issue branch command to incorrect processor to return to the instruction call
               -- that caused the error.  Wait for processor to acknowledge command
               when s_verr0_13 =>
                  -- If processor 0 is wrong
                  if (f_wrong0 = '1') then
                     if (i_MEM_READ0 = '0') then
                        f_verr0_state <= s_verr0_14;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_13;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 1 is wrong
                  elsif (f_wrong1 = '1') then
                     if (i_MEM_READ1 = '0') then
                        f_verr0_state <= s_verr0_14;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_13;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  -- If processor 2 is wrong
                  else
                     if (i_MEM_READ2 = '0') then
                        f_verr0_state <= s_verr0_14;
                        f_err0_timer <= (others => '0');
                     elsif (f_err0_timer > k_timeout) then
                        f_verr0_state <= s_verr0_err1;
                        f_err0_timer <= (others => '0');
                     else
                        f_verr0_state <= s_verr0_13;
                        f_err0_timer <= f_err0_timer + 1;
                     end if;
                  end if;
                  
               -- Wait for vfsm to retake control.  If f_vfsm_state dows not equal s_vfsm_err0,
               -- then f_verr0_state will be set equal to s_verr0_0
               when s_verr0_14 =>
                  f_verr0_state <= s_verr0_14;
                  -- If processor 0 is wrong
                  if (f_wrong0 = '1') then
                     f_done_wrong0 <= '1';
                  -- If processor 1 is wrong
                  elsif (f_wrong1 = '1') then
                     f_done_wrong1 <= '1';
                  -- If processor 2 is wrong
                  else
                     f_done_wrong2 <= '1';
                  end if;
                  
               -- This happens when the two processors assumed to be correct have a data mismatch 
               -- between their registers when copying data to the incorrect processor
               when s_verr0_err1 =>
                  f_verr0_state <= s_verr0_err1;  -- This will be overidden when vfsm transitions out of s_vfsm_err0 state.
               
               -- This should never happen
               when others =>
                  f_verr0_state <= s_verr0_0;
            end case;
         -- Stay in s_verr0_0 state until a single processor error occurs
         else
            f_verr0_state <= s_verr0_0;
            f_done_wrong0 <= '0';
            f_done_wrong1 <= '0';
            f_done_wrong2 <= '0';
            f_err0_count <= (others => '0');
            f_err0_timer <= (others => '0');
         end if;
      end if;
   end process err0;
   
   err1: process(i_clk, i_reset, f_vfsm_state)
   begin
      if (i_reset = '1') then
         f_verr1_state <= s_verr1_0;
         f_done_all_wrong <= '0';
         f_err1_count <= (others => '0');
         f_err1_timer <= (others => '0');
      elsif rising_edge(i_clk) then
         if f_vfsm_state = s_vfsm_err1 then
            case f_verr1_state is
               -- Wait for an error to occur
               when s_verr1_0 =>
                  f_verr1_state <= s_verr1_1;
               
               -- Reset all three processors and wait for save location to load from memory
               when s_verr1_1 =>
                  if i_MEM_READY = '1' then
                     f_verr1_state <= s_verr1_2;
                     f_err1_save_point32 <= i_MEM_OUT;
                  else
                     f_verr1_state <= s_verr1_1;
                  end if;
                  
               -- Wait for memory ready signal to return to 0
               when s_verr1_2 =>
                  if (i_MEM_READY = '0') then
                     f_verr1_state <= s_verr1_2a;
                  else
                     f_verr1_state <= s_verr1_2;
                  end if;
               
               -- Wait for all three processors to attempt to read an instruction
               when s_verr1_2a =>
                  if (i_MEM_READ0 = '1') and (i_MEM_READ1 = '1') and (i_MEM_READ2 = '1') and (i_MEM_ADDRESS0 = i_MEM_ADDRESS1) and (i_MEM_ADDRESS0 = i_MEM_ADDRESS2) then
                     f_verr1_state <= s_verr1_3;
                     f_err1_timer <= (others => '0');
                  elsif (i_MEM_READ0 = '1') and (i_MEM_READ1 = '1') and (i_MEM_READ2 = '1') then
                     f_verr1_state <= s_verr1_0;
                     f_err1_timer <= (others => '0');
                     f_err1_count <= (others => '0');
                     f_done_all_wrong <= '0';
                  elsif (f_err1_timer > k_timeout) then
                     f_verr1_state <= s_verr1_0;
                     f_err1_timer <= (others => '0');
                     f_err1_count <= (others => '0');
                     f_done_all_wrong <= '0';
                  else
                     f_verr1_state <= s_verr1_2a;
                     f_err1_timer <= f_err1_timer + 1;
                  end if;
               
               -- Issue load commands to all three processors
               when s_verr1_3 =>
                  if (i_MEM_READ0 = '0') and (i_MEM_READ1 = '0') and (i_MEM_READ2 = '0') then
                     f_verr1_state <= s_verr1_4;
                     f_err1_timer <= (others => '0');
                  elsif (f_err1_timer > k_timeout) then
                     f_verr1_state <= s_verr1_0;
                     f_err1_timer <= (others => '0');
                     f_err1_count <= (others => '0');
                     f_done_all_wrong <= '0';
                  else
                     f_verr1_state <= s_verr1_3;
                     f_err1_timer <= f_err1_timer + 1;
                  end if;
               
               -- Processors attempting to load data
               when s_verr1_4 =>
                  if (i_MEM_READ0 = '1') and (i_MEM_READ1 = '1') and (i_MEM_READ2 = '1') and (i_MEM_ADDRESS0 = i_MEM_ADDRESS1) and (i_MEM_ADDRESS0 = i_MEM_ADDRESS2) then
                     f_verr1_state <= s_verr1_5;
                     f_err1_timer <= (others => '0');
                  elsif (i_MEM_READ0 = '1') and (i_MEM_READ1 = '1') and (i_MEM_READ2 = '1') then
                     f_verr1_state <= s_verr1_0;
                     f_err1_timer <= (others => '0');
                     f_err1_count <= (others => '0');
                     f_done_all_wrong <= '0';
                  elsif (f_err1_timer > k_timeout) then
                     f_verr1_state <= s_verr1_0;
                     f_err1_timer <= (others => '0');
                     f_err1_count <= (others => '0');
                     f_done_all_wrong <= '0';
                  else
                     f_verr1_state <= s_verr1_4;
                     f_err1_timer <= f_err1_timer + 1;
                  end if;
               
               -- Read data from memory
               when s_verr1_5 =>
                  if (i_MEM_READY = '1') then
                     f_verr1_state <= s_verr1_6;
                     f_err1_data <= i_MEM_OUT;
                  else
                     f_verr1_state <= s_verr1_5;
                  end if;
               
               -- Return data from memory to processors
               when s_verr1_6 =>
                  if (i_MEM_READ0 = '0') and (i_MEM_READ1 = '0') and (i_MEM_READ2 = '0') then
                     if (to_integer(f_err1_count) = 30) then
                        f_verr1_state <= s_verr1_6a;
                        f_err1_timer <= (others => '0');
                        f_err1_count <= (others => '0');
                     else
                        f_verr1_state <= s_verr1_2;
                        f_err1_timer <= (others => '0');
                        f_err1_count <= f_err1_count + 1;
                     end if;
                  elsif (f_err1_timer > k_timeout) then
                     f_verr1_state <= s_verr1_0;
                     f_err1_timer <= (others => '0');
                     f_err1_count <= (others => '0');
                     f_done_all_wrong <= '0';
                  else
                     f_verr1_state <= s_verr1_6;
                     f_err1_timer <= f_err1_timer + 1;
                  end if;
               
               -- Wait for memory ready signal to return to 0
               when s_verr1_6a =>
                  if (i_MEM_READY = '0') then
                     f_verr1_state <= s_verr1_7;
                  else
                     f_verr1_state <= s_verr1_6a;
                  end if;
                  
               
               -- Load desired program location from memory
               when s_verr1_7 =>
                  if (i_MEM_READY = '1') then
                     f_verr1_state <= s_verr1_8;
                     f_err1_pc <= i_MEM_OUT;
                  else
                     f_verr1_state <= s_verr1_7;
                  end if;
                  
               
               -- Wait for memory ready signal to return to 0
               when s_verr1_8 =>
                  if (i_MEM_READY = '0') then
                     f_verr1_state <= s_verr1_8a;
                  else
                     f_verr1_state <= s_verr1_8;
                  end if;
               
               -- Wait for all processors to attempt to load an instruction
               when s_verr1_8a =>
                  if (i_MEM_READ0 = '1') and (i_MEM_READ1 = '1') and (i_MEM_READ2 = '1') and (i_MEM_ADDRESS0 = i_MEM_ADDRESS1) and (i_MEM_ADDRESS0 = i_MEM_ADDRESS2) then
                     f_verr1_state <= s_verr1_9;
                     f_err1_timer <= (others => '0');
                  elsif (i_MEM_READ0 = '1') and (i_MEM_READ1 = '1') and (i_MEM_READ2 = '1') then
                     f_verr1_state <= s_verr1_0;
                     f_err1_timer <= (others => '0');
                     f_err1_count <= (others => '0');
                     f_done_all_wrong <= '0';
                  elsif (f_err1_timer > k_timeout) then
                     f_verr1_state <= s_verr1_0;
                     f_err1_timer <= (others => '0');
                     f_err1_count <= (others => '0');
                     f_done_all_wrong <= '0';
                  else
                     f_verr1_state <= s_verr1_8a;
                     f_err1_timer <= f_err1_timer + 1;
                  end if;
               
               -- Issue branch commands to all processors
               when s_verr1_9 =>
                  if (i_MEM_READ0 = '0') and (i_MEM_READ1 = '0') and (i_MEM_READ2 = '0') then
                     f_verr1_state <= s_verr1_10;
                     f_err1_timer <= (others => '0');
                  elsif (f_err1_timer > k_timeout) then
                     f_verr1_state <= s_verr1_0;
                     f_err1_timer <= (others => '0');
                     f_err1_count <= (others => '0');
                     f_done_all_wrong <= '0';
                  else
                     f_verr1_state <= s_verr1_9;
                     f_err1_timer <= f_err1_timer + 1;
                  end if;
               
               -- Wait for vfsm to retake control.  If f_vfsm_state dows not equal s_vfsm_err1,
               -- then f_verr1_state will be set equal to s_verr1_0
               when s_verr1_10 =>
                  f_verr1_state <= s_verr1_10;
                  f_done_all_wrong <= '1';
               
               -- This should never happen
               when others =>
                  f_verr1_state <= s_verr1_0;
            end case;
         else
            f_verr1_state <= s_verr1_0;
            f_err1_count <= (others => '0');
            f_err1_timer <= (others => '0');
            f_done_all_wrong <= '0';
         end if;
      end if;
   end process err1;
   
   save: process(i_clk, i_reset, f_vfsm_state)
   begin
      if (i_reset = '1') then
         f_vsave_state <= s_vsave_0;
         f_done_save <= '0';
         f_save_count <= (others => '0');
         f_save_timer <= (others => '0');
         f_save_current_address <= (others => '0');
      elsif rising_edge(i_clk) then
         if f_vfsm_state = s_vfsm_save then
            case f_vsave_state is
               -- Wait for save point
               when s_vsave_0 =>
                  f_vsave_state <= s_vsave_1;
               
               -- Load save point from memory
               when s_vsave_1 =>
                  if (i_MEM_READY = '1') then
                     f_vsave_state <= s_vsave_2;
                     f_save_save_point32 <= i_MEM_OUT;
                  else
                     f_vsave_state <= s_vsave_1;
                  end if;
                  
               -- Wait for memory ready signal to return to 0
               when s_vsave_2 =>
                  if (i_MEM_READY = '0') then
                     f_vsave_state <= s_vsave_2a;
                  else
                     f_vsave_state <= s_vsave_2;
                  end if;
               
               -- Wait for all three processors to attempt to read an instruction
               when s_vsave_2a =>
                  if (i_MEM_READ0 = '1')  and (i_MEM_READ1 = '1') and (i_MEM_READ2 = '1') and (i_MEM_ADDRESS0 = i_MEM_ADDRESS1) and (i_MEM_ADDRESS1 = i_MEM_ADDRESS2) then
                     f_vsave_state <= s_vsave_3;
                     f_save_timer <= (others => '0');
                     f_save_current_address <= i_MEM_ADDRESS0;
                  elsif (i_MEM_READ0 = '1')  and (i_MEM_READ1 = '1') and (i_MEM_READ2 = '1') then
                     f_vsave_state <= s_vsave_err1;
                     f_save_count <= (others => '0');
                     f_save_timer <= (others => '0');
                  elsif (f_save_timer > k_timeout) then
                     f_vsave_state <= s_vsave_err1;
                     f_save_count <= (others => '0');
                     f_save_timer <= (others => '0');
                  else
                     f_vsave_state <= s_vsave_2a;
                     f_save_timer <= f_save_timer + 1;
                  end if;
               
               -- Issue store word commands to all three processors to store the current register to memory
               when s_vsave_3 =>
                  if (i_MEM_READ0 = '0')  and (i_MEM_READ1 = '0') and (i_MEM_READ2 = '0') then
                     f_vsave_state <= s_vsave_4;
                     f_save_timer <= (others => '0');
                  elsif (f_save_timer > k_timeout) then
                     f_vsave_state <= s_vsave_err1;
                     f_save_count <= (others => '0');
                     f_save_timer <= (others => '0');
                  else
                     f_vsave_state <= s_vsave_3;
                     f_save_timer <= f_save_timer + 1;
                  end if;
                  
               -- Wait for all three processors to attempt to store the current register to memory and determine if
               -- at least two of the three processors agree on the value of the current register
               when s_vsave_4 =>
                  if (i_MEM_WRITE0 = '1') and (i_MEM_WRITE1 = '1') and (i_MEM_WRITE2 = '1') then
                     if (i_MEM_IN0 = i_MEM_IN1) or (i_MEM_IN1 = i_MEM_IN2) or (i_MEM_IN0 = i_MEM_IN2) then
                        f_vsave_state <= s_vsave_5;
                     else
                        f_vsave_state <= s_vsave_err1;
                        f_save_count <= (others => '0');
                     end if;
                     f_save_timer <= (others => '0');
                  elsif (f_save_timer > k_timeout) then
                     f_vsave_state <= s_vsave_err1;
                     f_save_count <= (others => '0');
                     f_save_timer <= (others => '0');
                  else
                     f_vsave_state <= s_vsave_4;
                     f_save_timer <= f_save_timer + 1;
                  end if;
               
               -- Store the current register data to memory
               when s_vsave_5 =>
                  if (i_MEM_READY = '1') then
                     f_vsave_state <= s_vsave_6;
                  else
                     f_vsave_state <= s_vsave_5;
                  end if;
               
               -- Wait for MIPS processors write signals to return to 0
               when s_vsave_6 =>
                  if (i_MEM_WRITE0 = '0') and (i_MEM_WRITE1 = '0') and (i_MEM_WRITE2 = '0') then
                     if (to_integer(f_save_count) = 30) then
                        f_vsave_state <= s_vsave_6a;
                        f_save_timer <= (others => '0');
                        f_save_count <= (others => '0');
                     else
                        f_vsave_state <= s_vsave_2;
                        f_save_timer <= (others => '0');
                        f_save_count <= f_save_count + 1;
                     end if;
                  elsif (f_save_timer > k_timeout) then
                     f_vsave_state <= s_vsave_err1;
                     f_save_timer <= (others => '0');
                     f_save_count <= (others => '0');
                  else
                     f_vsave_state <= s_vsave_6;
                     f_save_timer <= f_save_timer + 1;
                  end if;
                  
               -- Wait for memory ready signal to return to 0
               when s_vsave_6a =>   
                  if (i_MEM_READY = '0') then
                     f_vsave_state <= s_vsave_7;
                  else
                     f_vsave_state <= s_vsave_6a;
                  end if;
                  
               -- Write the updated PC address to memory
               when s_vsave_7 =>
                  if (i_MEM_READY = '1') then
                     f_vsave_state <= s_vsave_8;
                  else
                     f_vsave_state <= s_vsave_7;
                  end if;
                  
               -- Wait for memory i_MEM_READY to return to 0
               when s_vsave_8 =>
                  if (i_MEM_READY = '0') then
                     f_vsave_state <= s_vsave_9;
                  else
                     f_vsave_state <= s_vsave_8;
                  end if;
               
               -- Update the location of the save point
               when s_vsave_9 =>
                  if (i_MEM_READY = '1') then
                     f_vsave_state <= s_vsave_10;
                  else
                     f_vsave_state <= s_vsave_9;
                  end if;
               
               -- Wait for memory ready signal to return to 0
               when s_vsave_10 =>
                  if (i_MEM_READY = '0') then
                     f_vsave_state <= s_vsave_10a;
                  else
                     f_vsave_state <= s_vsave_10;
                  end if;
            
               -- Wait for all three processors to attempt to read an instruction
               when s_vsave_10a =>
                  if (i_MEM_READ0 = '1')  and (i_MEM_READ1 = '1') and (i_MEM_READ2 = '1') and (i_MEM_ADDRESS0 = i_MEM_ADDRESS1) and (i_MEM_ADDRESS1 = i_MEM_ADDRESS2) then
                     f_vsave_state <= s_vsave_11;
                     f_save_current_address <= i_MEM_ADDRESS0;
                     f_save_timer <= (others => '0');
                  elsif (i_MEM_READ0 = '1')  and (i_MEM_READ1 = '1') and (i_MEM_READ2 = '1') then
                     f_vsave_state <= s_vsave_err1;
                     f_save_count <= (others => '0');
                     f_save_timer <= (others => '0');
                  elsif (f_save_timer > k_timeout) then
                     f_vsave_state <= s_vsave_err1;
                     f_save_count <= (others => '0');
                     f_save_timer <= (others => '0');
                  else
                     f_vsave_state <= s_vsave_10a;
                     f_save_timer <= f_save_timer + 1;
                  end if;
                  
               -- Issue branch commands to all three processors to return to the previous processing location
               when s_vsave_11 =>
                  if (i_MEM_READ0 = '0')  and (i_MEM_READ1 = '0') and (i_MEM_READ2 = '0') then
                     f_vsave_state <= s_vsave_12;
                     f_save_timer <= (others => '0');
                  elsif (f_save_timer > k_timeout) then
                     f_vsave_state <= s_vsave_err1;
                     f_save_count <= (others => '0');
                     f_save_timer <= (others => '0');
                  else
                     f_vsave_state <= s_vsave_11;
                     f_save_timer <= f_save_timer + 1;
                  end if;
               
               --   Wait for FSM to resume control
               when s_vsave_12 =>
                  f_vsave_state <= s_vsave_12;
                  f_done_save <= '1';
               
               when others =>
               
            end case;
         else
            f_vsave_state <= s_vsave_0;
            f_save_count <= (others => '0');
            f_save_timer <= (others => '0');
            f_done_save <= '0';
         end if;
      end if;
   end process save;
   
   voter_output_fsm: process(i_clk, i_reset, f_vfsm_state, f_verr0_state, f_verr1_state, f_vsave_state)
   begin
      if (i_reset = '1') then
         f_MEM_READ <= '0';
         ff_MEM_READ <= '0';
         fff_MEM_READ <= '0';
         f_MEM_WRITE <= '0';
         ff_MEM_WRITE <= '0';
         fff_MEM_WRITE <= '0';
         f_MEM_IN <= (others => '0');
         f_MEM_ADDRESS <= (others => '0');
         f_MEM_OUT0 <= (others => '0');
         f_MEM_OUT1 <= (others => '0');
         f_MEM_OUT2 <= (others => '0');
         f_MEM_READY0 <= '0';
         f_MEM_READY1 <= '0';
         f_MEM_READY2 <= '0';
         ff_MEM_READY0 <= '0';
         ff_MEM_READY1 <= '0';
         ff_MEM_READY2 <= '0';
         f_RESET0 <= '0';
         f_RESET1 <= '0';
         f_RESET2 <= '0';
         f_Err_Override <= '0';
      elsif rising_edge(i_clk) then
         ff_MEM_READ <= f_MEM_READ;
         fff_MEM_READ <= ff_MEM_READ;
         ff_MEM_WRITE <= f_MEM_WRITE;
         fff_MEM_WRITE <= ff_MEM_WRITE;
         ff_MEM_READY0 <= f_MEM_READY0;
         ff_MEM_READY1 <= f_MEM_READY1;
         ff_MEM_READY2 <= f_MEM_READY2;
         case f_vfsm_state is
         -- Determine when all three processors are attempting to read or write.
            when s_vfsm_0 =>
               -- Do nothing as this is the idle state, but ensure all outputs are suppressed
               f_MEM_READ <= '0';
               f_MEM_WRITE <= '0';
               f_MEM_IN <= (others => '0');
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_READY0 <= '0';
               f_MEM_READY1 <= '0';
               f_MEM_READY2 <= '0';
               f_RESET0 <= '0';
               f_RESET1 <= '0';
               f_RESET2 <= '0';
               f_Err_Override <= '0';
               
            -- Determine whether this is a read or write operation or if an error has occured with one or more processors
            when s_vfsm_1 =>
               -- Do nothing while the vote is determined
               
            -- Request data from memory by sending address and awaiting response from memory.
            when s_vfsm_2 =>
               f_MEM_READ <= i_MEM_READ0;
               f_MEM_ADDRESS <= i_MEM_ADDRESS0;
               
            -- Pass the instruction to all three processors
            when s_vfsm_3 =>
               f_MEM_READ <= '0';
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_OUT0 <= f_data;
               f_MEM_OUT1 <= f_data;
               f_MEM_OUT2 <= f_data;
               f_MEM_READY0 <= '1';
               f_MEM_READY1 <= '1';
               f_MEM_READY2 <= '1';
               
            when s_vfsm_3a =>
               f_MEM_READ <= '0';
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_OUT0 <= f_data;
               f_MEM_OUT1 <= f_data;
               f_MEM_OUT2 <= f_data;
               f_MEM_READY0 <= '0';
               f_MEM_READY1 <= '0';
               f_MEM_READY2 <= '0';
                  
            -- This is a load word operation.  Wait for all three processors to request data from memory
            when s_vfsm_4 =>
               f_MEM_READY0 <= '0';
               f_MEM_READY1 <= '0';
               f_MEM_READY2 <= '0';
               
            -- Check to make sure all three processors agree.  If not, at least one processor is in error.
            when s_vfsm_5 =>
               -- Do nothing while the vote is determined
               
            -- Inform correct processors that write operation completed successfully before continuing to ERR0
            when s_vfsm_5a =>
               if (f_wrong0 = '1') then
                  f_MEM_READY1 <= '1';
                  f_MEM_READY2 <= '1';
               elsif (f_wrong1 = '1') then
                  f_MEM_READY0 <= '1';
                  f_MEM_READY2 <= '1';
               elsif (f_wrong2 = '1') then
                  f_MEM_READY0 <= '1';
                  f_MEM_READY1 <= '1';
               end if;
               
            -- Request data from memory by sending address and awaiting response from memory.
            when s_vfsm_6 =>
               f_MEM_READ <= i_MEM_READ0;
               f_MEM_ADDRESS <= i_MEM_ADDRESS0;
               
            -- Pass data back to all three processors
            when s_vfsm_7 =>
               f_MEM_READ <= '0';
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_OUT0 <= f_data;
               f_MEM_OUT1 <= f_data;
               f_MEM_OUT2 <= f_data;
               f_MEM_READY0 <= '1';
               f_MEM_READY1 <= '1';
               f_MEM_READY2 <= '1';
               
            when s_vfsm_7a =>
               f_MEM_READ <= '0';
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_OUT0 <= f_data;
               f_MEM_OUT1 <= f_data;
               f_MEM_OUT2 <= f_data;
               f_MEM_READY0 <= '0';
               f_MEM_READY1 <= '0';
               f_MEM_READY2 <= '0';
               
            -- This is a store word operation.  Wait for at least two of three processors to send data to memory
            when s_vfsm_8 =>
               f_MEM_READY0 <= '0';
               f_MEM_READY1 <= '0';
               f_MEM_READY2 <= '0';
            
            -- Check to make sure all three processors agree.  If not, at least one processor is in error.
            when s_vfsm_9 =>
               -- Do nothing but wait for vote outcome
               
            -- Inform correct processors that write operation completed successfully before continuing to ERR0
            when s_vfsm_9a =>
               if (f_wrong0 = '1') then
                  f_MEM_READY1 <= '1';
                  f_MEM_READY2 <= '1';
               elsif (f_wrong1 = '1') then
                  f_MEM_READY0 <= '1';
                  f_MEM_READY2 <= '1';
               elsif (f_wrong2 = '1') then
                  f_MEM_READY0 <= '1';
                  f_MEM_READY1 <= '1';
               end if;
               
            -- Write data to memory by sending address and data and awaiting response from memory.
            when s_vfsm_10 =>
               f_MEM_WRITE <= i_MEM_WRITE0;
               f_MEM_ADDRESS <= i_MEM_ADDRESS0;
               f_MEM_IN <= i_MEM_IN0;
            
            -- Pass MEM_READY signal back to all processors
            when s_vfsm_11 =>
               f_MEM_WRITE <= '0';
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_READY0 <= '1';
               f_MEM_READY1 <= '1';
               f_MEM_READY2 <= '1';
               
            when s_vfsm_12 =>
               f_MEM_WRITE <= '0';
               f_MEM_ADDRESS <= (others => '0');
               f_MEM_READY0 <= '0';
               f_MEM_READY1 <= '0';
               f_MEM_READY2 <= '0';
            
            -- Enter this state when one of three processors are wrong
            when s_vfsm_err0 =>
               f_Err_Override <= '1';
               case f_verr0_state is
                  -- Waiting for an error to occur in one of the processors
                  when s_verr0_0 =>
                     f_MEM_READY0 <= '0';
                     f_MEM_READY1 <= '0';
                     f_MEM_READY2 <= '0';
                     -- Do nothing
                  
                  -- Reset the processor that is in error
                  when s_verr0_1 =>
                     -- If processor 0 is wrong
                     if f_wrong0 = '1' then
                        f_RESET0 <= '1';
                     -- If processor 1 is wrong
                     elsif f_wrong1 = '1' then
                        f_RESET1 <= '1';
                     -- If processor 2 is wrong
                     else
                        f_RESET2 <= '1';
                     end if;
                     f_MEM_READY0 <= '0';
                     f_MEM_READY1 <= '0';
                     f_MEM_READY2 <= '0';
                  
                  --| Copy data from correct processors to incorrect processor one register at a time
                  -- Wait for correct processors to attempt to retrieve an instruction from memory`
                  when s_verr0_2 =>
                     -- If processor 0 is wrong
                     if f_wrong0 = '1' then
                        f_RESET0 <= '0';
                     -- If processor 1 is wrong
                     elsif f_wrong1 = '1' then
                        f_RESET1 <= '0';
                     -- If processor 2 is wrong
                     else
                        f_RESET2 <= '0';
                     end if;
                     f_MEM_READY0 <= '0';
                     f_MEM_READY1 <= '0';
                     f_MEM_READY2 <= '0';
                  
                  -- Issue store word commands to the correct processors
                  when s_verr0_3 =>
                     -- If processor 0 is wrong
                     if f_wrong0 = '1' then
                        f_MEM_OUT1 <= "10101100000" & std_logic_vector(f_err0_count+1) & "0000000000000000";
                        f_MEM_OUT2 <= "10101100000" & std_logic_vector(f_err0_count+1) & "0000000000000000";
                        f_MEM_READY1 <= '1';
                        f_MEM_READY2 <= '1';
                     -- If processor 1 is wrong
                     elsif f_wrong1 = '1' then
                        f_MEM_OUT0 <= "10101100000" & std_logic_vector(f_err0_count+1) & "0000000000000000";
                        f_MEM_OUT2 <= "10101100000" & std_logic_vector(f_err0_count+1) & "0000000000000000";
                        f_MEM_READY0 <= '1';
                        f_MEM_READY2 <= '1';
                     -- If processor 2 is wrong
                     else
                        f_MEM_OUT0 <= "10101100000" & std_logic_vector(f_err0_count+1) & "0000000000000000";
                        f_MEM_OUT1 <= "10101100000" & std_logic_vector(f_err0_count+1) & "0000000000000000";
                        f_MEM_READY0 <= '1';
                        f_MEM_READY1 <= '1';
                     end if;
                  
                  -- Wait for correct processors to issue store word requests
                  when s_verr0_4 =>
                     -- If processor 0 is wrong
                     if f_wrong0 = '1' then
                        f_MEM_READY1 <= '0';
                        f_MEM_READY2 <= '0';
                     -- If processor 1 is wrong
                     elsif f_wrong1 = '1' then
                        f_MEM_READY0 <= '0';
                        f_MEM_READY2 <= '0';
                     -- If processor 2 is wrong
                     else
                        f_MEM_READY0 <= '0';
                        f_MEM_READY1 <= '0';
                     end if;
                  
                  -- Check that data from the correct processors is a match
                  when s_verr0_5 =>
                     -- If processor 0 is wrong
                     if f_wrong0 = '1' then
                        f_MEM_READY1 <= '1';
                        f_MEM_READY2 <= '1';
                     -- If processor 1 is wrong
                     elsif f_wrong1 = '1' then
                        f_MEM_READY0 <= '1';
                        f_MEM_READY2 <= '1';
                     -- If processor 2 is wrong
                     else
                        f_MEM_READY0 <= '1';
                        f_MEM_READY1 <= '1';
                     end if;
                     
                  -- Wait for incorrect processor to attempt to retrieve an instruction from memory
                  when s_verr0_6 =>
                     -- If processor 0 is wrong
                     if f_wrong0 = '1' then
                        f_MEM_READY1 <= '0';
                        f_MEM_READY2 <= '0';
                     -- If processor 1 is wrong
                     elsif f_wrong1 = '1' then
                        f_MEM_READY0 <= '0';
                        f_MEM_READY2 <= '0';
                     -- If processor 2 is wrong
                     else
                        f_MEM_READY0 <= '0';
                        f_MEM_READY1 <= '0';
                     end if;
                  
                  -- Issue load word command to the incorrect processor
                  when s_verr0_7 =>
                     -- If processor 0 is wrong
                     if f_wrong0 = '1' then
                        f_MEM_OUT0 <= "10001100000" & std_logic_vector(f_err0_count+1) & "0000000000000000";
                        f_MEM_READY0 <= '1';
                     -- If processor 1 is wrong
                     elsif f_wrong1 = '1' then
                        f_MEM_OUT1 <= "10001100000" & std_logic_vector(f_err0_count+1) & "0000000000000000";
                        f_MEM_READY1 <= '1';
                     -- If processor 2 is wrong
                     else
                        f_MEM_OUT2 <= "10001100000" & std_logic_vector(f_err0_count+1) & "0000000000000000";
                        f_MEM_READY2 <= '1';
                     end if;
                  
                  -- Wait for incorrect processor to attempt to load the requested data from memory
                  when s_verr0_8 =>
                     -- If processor 0 is wrong
                     if f_wrong0 = '1' then
                        f_MEM_READY0 <= '0';
                     -- If processor 1 is wrong
                     elsif f_wrong1 = '1' then
                        f_MEM_READY1 <= '0';
                     -- If processor 2 is wrong
                     else
                        f_MEM_READY2 <= '0';
                     end if;
                     
                  -- Return desired data to the incorrect processor
                  when s_verr0_9 =>
                     -- If processor 0 is wrong
                     if f_wrong0 = '1' then
                        f_MEM_OUT0 <= f_err0_data;
                        f_MEM_READY0 <= '1';
                     -- If processor 1 is wrong
                     elsif f_wrong1 ='1' then
                        f_MEM_OUT1 <= f_err0_data;
                        f_MEM_READY1 <= '1';
                     -- If processor 2 is wrong
                     else
                        f_MEM_OUT2 <= f_err0_data;
                        f_MEM_READY2 <= '1';
                     end if;
                     
                  --| Return processor's program counters to the point at which the error was encountered
                  --Wait for correct processors to request next instruction
                  when s_verr0_10 =>
                     -- If processor 0 is wrong
                     if f_wrong0 = '1' then
                        f_MEM_READY0 <= '0';
                     -- If processor 1 is wrong
                     elsif f_wrong1 ='1' then
                        f_MEM_READY1 <= '0';
                     -- If processor 2 is wrong
                     else
                        f_MEM_READY2 <= '0';
                     end if;
                     
                  -- Issue branch command to correct processors to return to the instruction call
                  -- that caused the error.  Wait for processors to acknowledge command
                  when s_verr0_11 =>
                     -- If processor 0 is wrong
                     if f_wrong0 = '1' then
                        f_MEM_OUT1 <= "0001000000000000" & w_correct_branch_distance16;
                        f_MEM_OUT2 <= "0001000000000000" & w_correct_branch_distance16;
                        f_MEM_READY1 <= '1';
                        f_MEM_READY2 <= '1';
                     -- If processor 1 is wrong
                     elsif f_wrong1 = '1' then
                        f_MEM_OUT0 <= "0001000000000000" & w_correct_branch_distance16;
                        f_MEM_OUT2 <= "0001000000000000" & w_correct_branch_distance16;
                        f_MEM_READY0 <= '1';
                        f_MEM_READY2 <= '1';
                     --   If processor 2 is wrong
                     else
                        f_MEM_OUT0 <= "0001000000000000" & w_correct_branch_distance16;
                        f_MEM_OUT1 <= "0001000000000000" & w_correct_branch_distance16;
                        f_MEM_READY0 <= '1';
                        f_MEM_READY1 <= '1';
                     end if;
                     
                  --Wait for incorrect processor to request next instruction
                  when s_verr0_12 =>
                     -- If processor 0 is wrong
                     if f_wrong0 = '1' then
                        f_MEM_READY1 <= '0';
                        f_MEM_READY2 <= '0';
                     -- If processor 1 is wrong
                     elsif f_wrong1 = '1' then
                        f_MEM_READY0 <= '0';
                        f_MEM_READY2 <= '0';
                     -- If processor 2 is wrong
                     else
                        f_MEM_READY0 <= '0';
                        f_MEM_READY1 <= '0';
                     end if;
                     
                  -- Issue branch command to incorrect processor to return to the instruction call
                  -- that caused the error.  Wait for processor to acknowledge command
                  when s_verr0_13 =>
                     -- If processor 0 is wrong
                     if f_wrong0 = '1' then
                        f_MEM_OUT0 <= "0001000000000000" & w_incorrect_branch_distance16;
                        f_MEM_READY0 <= '1';
                     -- If processor 1 is wrong
                     elsif f_wrong1 = '1' then
                        f_MEM_OUT1 <= "0001000000000000" & w_incorrect_branch_distance16;
                        f_MEM_READY1 <= '1';
                     -- If processor 2 is wrong
                     else
                        f_MEM_OUT2 <= "0001000000000000" & w_incorrect_branch_distance16;
                        f_MEM_READY2 <= '1';
                     end if;
                     
                  -- Wait for vfsm to retake control.  If f_vfsm_state dows not equal s_vfsm_err0,
                  -- then f_verr0_state will be set equal to s_verr0_0
                  when s_verr0_14 =>
                     -- If processor 0 is wrong
                     if f_wrong0 = '1' then
                        f_MEM_READY0 <= '0';
                     -- If processor 1 is wrong
                     elsif f_wrong1 = '1' then
                        f_MEM_READY1 <= '0';
                     -- If processor 2 is wrong
                     else
                        f_MEM_READY2 <= '0';
                     end if;
                     
                  -- This should never happen
                  when others =>
               end case;
            -- Enter this state when all three processors are wrong
            when s_vfsm_err1 =>
               f_Err_Override <= '1';
               case f_verr1_state is
                  -- Wait for an error to occur
                  when s_verr1_0 =>
                     f_MEM_READY0 <= '0';
                     f_MEM_READY1 <= '0';
                     f_MEM_READY2 <= '0';
                     
                  
                  -- Reset all three processors and wait for save location to load from memory
                  when s_verr1_1 =>
                     f_RESET0 <= '1';
                     f_RESET1 <= '1';
                     f_RESET2 <= '1';
                     f_MEM_ADDRESS <= std_logic_vector(unsigned(k_mem_location) + unsigned(k_256_32));--("0000000000000000000000000" & std_logic_vector(f_err1_count) & "00");
                     f_MEM_READ <= '1';
                     f_MEM_READY0 <= '0';
                     f_MEM_READY1 <= '0';
                     f_MEM_READY2 <= '0';
                     
                  -- Wait for memory ready signal to return to 0
                  when s_verr1_2 =>
                     f_RESET0 <= '0';
                     f_RESET1 <= '0';
                     f_RESET2 <= '0';
                     f_MEM_READY0 <= '0';
                     f_MEM_READY1 <= '0';
                     f_MEM_READY2 <= '0';
                     f_MEM_ADDRESS <= (others => '0');
                     f_MEM_READ <= '0';
                  
                  -- Wait for all three processors to attempt to read an instruction
                  when s_verr1_2a =>
                     f_RESET0 <= '0';
                     f_RESET1 <= '0';
                     f_RESET2 <= '0';
                     f_MEM_READY0 <= '0';
                     f_MEM_READY1 <= '0';
                     f_MEM_READY2 <= '0';
                     f_MEM_ADDRESS <= (others => '0');
                     f_MEM_READ <= '0';
                  
                  -- Issue load commands to all three processors
                  when s_verr1_3 =>
                     if (f_err1_save_point32(0) = '0') then
                        f_MEM_OUT0 <= "10001100000" & std_logic_vector(f_err1_count+1) & std_logic_vector(unsigned(k_mem_location(15 downto 0)) + unsigned("000000000" & std_logic_vector(f_err1_count) & "00"));
                        f_MEM_OUT1 <= "10001100000" & std_logic_vector(f_err1_count+1) & std_logic_vector(unsigned(k_mem_location(15 downto 0)) + unsigned("000000000" & std_logic_vector(f_err1_count) & "00"));
                        f_MEM_OUT2 <= "10001100000" & std_logic_vector(f_err1_count+1) & std_logic_vector(unsigned(k_mem_location(15 downto 0)) + unsigned("000000000" & std_logic_vector(f_err1_count) & "00"));
                     else
                        f_MEM_OUT0 <= "10001100000" & std_logic_vector(f_err1_count+1) & std_logic_vector(unsigned(k_mem_location(15 downto 0)) + unsigned(k_128_16) + unsigned("000000000" & std_logic_vector(f_err1_count) & "00"));
                        f_MEM_OUT1 <= "10001100000" & std_logic_vector(f_err1_count+1) & std_logic_vector(unsigned(k_mem_location(15 downto 0)) + unsigned(k_128_16) + unsigned("000000000" & std_logic_vector(f_err1_count) & "00"));
                        f_MEM_OUT2 <= "10001100000" & std_logic_vector(f_err1_count+1) & std_logic_vector(unsigned(k_mem_location(15 downto 0)) + unsigned(k_128_16) + unsigned("000000000" & std_logic_vector(f_err1_count) & "00"));
                     end if;
                     f_MEM_READY0 <= '1';
                     f_MEM_READY1 <= '1';
                     f_MEM_READY2 <= '1';
                  
                  -- Processors attempting to load data
                  when s_verr1_4 =>
                     f_MEM_READY0 <= '0';
                     f_MEM_READY1 <= '0';
                     f_MEM_READY2 <= '0';
                  
                  -- Read data from memory
                  when s_verr1_5 =>
                     f_MEM_ADDRESS <= i_MEM_ADDRESS0;
                     f_MEM_READ <= '1';
                  
                  -- Return data from memory to processors
                  when s_verr1_6 =>
                     f_MEM_ADDRESS <= (others => '0');
                     f_MEM_READ <= '0';
                     f_MEM_OUT0 <= f_err1_data;
                     f_MEM_OUT1 <= f_err1_data;
                     f_MEM_OUT2 <= f_err1_data;
                     f_MEM_READY0 <= '1';
                     f_MEM_READY1 <= '1';
                     f_MEM_READY2 <= '1';
                     
                  -- Wait for memory ready signal to return to 0
                  when s_verr1_6a =>
                     f_MEM_ADDRESS <= (others => '0');
                     f_MEM_READ <= '0';
                     f_MEM_OUT0 <= f_err1_data;
                     f_MEM_OUT1 <= f_err1_data;
                     f_MEM_OUT2 <= f_err1_data;
                     f_MEM_READY0 <= '0';
                     f_MEM_READY1 <= '0';
                     f_MEM_READY2 <= '0';
                  
                  -- Load desired program location from memory
                  when s_verr1_7 =>
                     f_MEM_READY0 <= '0';
                     f_MEM_READY1 <= '0';
                     f_MEM_READY2 <= '0';
                     if (f_err1_save_point32(0) = '0') then
                        f_MEM_ADDRESS <= std_logic_vector(unsigned(k_mem_location) + unsigned(k_124_32));
                     else
                        f_MEM_ADDRESS <= std_logic_vector(unsigned(k_mem_location) + unsigned(k_252_32));
                     end if;
                     f_MEM_READ <= '1';
                  
                  -- Wait for all processors to attempt to load an instruction
                  when s_verr1_8 =>
                     f_MEM_ADDRESS <= (others => '0');
                     f_MEM_READ <= '0';
                  
                  -- Wait for memory ready signal to return to 0
                  when s_verr1_8a =>
                     f_MEM_ADDRESS <= (others => '0');
                     f_MEM_READ <= '0';
                  
                  -- Issue branch commands to all processors
                  when s_verr1_9 =>
                     f_MEM_OUT0 <= "0001000000000000" & w_err1_branch_distance16;
                     f_MEM_OUT1 <= "0001000000000000" & w_err1_branch_distance16;
                     f_MEM_OUT2 <= "0001000000000000" & w_err1_branch_distance16;
                     f_MEM_READY0 <= '1';
                     f_MEM_READY1 <= '1';
                     f_MEM_READY2 <= '1';
                  
                  -- Wait for vfsm to retake control.  If f_vfsm_state dows not equal s_vfsm_err1,
                  -- then f_verr1_state will be set equal to s_verr1_0
                  when s_verr1_10 =>
                     f_MEM_READY0 <= '0';
                     f_MEM_READY1 <= '0';
                     f_MEM_READY2 <= '0';
                     
                  -- This should never happen
                  when others =>
                     
               end case;
               
            -- Enter this state when it is time to create a save point from which a recovery may take place
            when s_vfsm_save =>
               f_Err_Override <= '1';
               case f_vsave_state is
                  -- Wait for save point
                  when s_vsave_0 =>
                     f_MEM_READY0 <= '0';
                     f_MEM_READY1 <= '0';
                     f_MEM_READY2 <= '0';
                  
                  -- Load save point from memory
                  when s_vsave_1 =>
                     f_MEM_ADDRESS <= std_logic_vector(unsigned(k_mem_location) + unsigned(k_256_32));
                     f_MEM_READ <= '1';
                     
                  -- Wait for memory ready signal to return to 0
                  when s_vsave_2 =>
                     f_MEM_ADDRESS <= (others => '0');
                     f_MEM_READ <= '0';
                     f_MEM_READY0 <= '0';
                     f_MEM_READY1 <= '0';
                     f_MEM_READY2 <= '0';
                     
                  -- Wait for all three processors to attempt to read an instruction
                  when s_vsave_2a =>
                     f_MEM_ADDRESS <= (others => '0');
                     f_MEM_READ <= '0';
                     f_MEM_READY0 <= '0';
                     f_MEM_READY1 <= '0';
                     f_MEM_READY2 <= '0';
                     
                  -- Issue store word commands to all three processors to store the current register to memory
                  when s_vsave_3 =>
                     if f_save_save_point32(0) = '1' then
                        f_MEM_OUT0 <= "10101100000" & std_logic_vector(f_save_count+1) & std_logic_vector(unsigned(k_mem_location(15 downto 0)) + unsigned("000000000" & std_logic_vector(f_save_count) & "00"));
                        f_MEM_OUT1 <= "10101100000" & std_logic_vector(f_save_count+1) & std_logic_vector(unsigned(k_mem_location(15 downto 0)) + unsigned("000000000" & std_logic_vector(f_save_count) & "00"));
                        f_MEM_OUT2 <= "10101100000" & std_logic_vector(f_save_count+1) & std_logic_vector(unsigned(k_mem_location(15 downto 0)) + unsigned("000000000" & std_logic_vector(f_save_count) & "00"));
                     else
                        f_MEM_OUT0 <= "10101100000" & std_logic_vector(f_save_count+1) & std_logic_vector(unsigned(k_mem_location(15 downto 0)) + unsigned(k_128_16) + unsigned("000000000" & std_logic_vector(f_save_count) & "00"));
                        f_MEM_OUT1 <= "10101100000" & std_logic_vector(f_save_count+1) & std_logic_vector(unsigned(k_mem_location(15 downto 0)) + unsigned(k_128_16) + unsigned("000000000" & std_logic_vector(f_save_count) & "00"));
                        f_MEM_OUT2 <= "10101100000" & std_logic_vector(f_save_count+1) & std_logic_vector(unsigned(k_mem_location(15 downto 0)) + unsigned(k_128_16) + unsigned("000000000" & std_logic_vector(f_save_count) & "00"));
                     end if;
                     f_MEM_READY0 <= '1';
                     f_MEM_READY1 <= '1';
                     f_MEM_READY2 <= '1';
                     
                     
                  -- Wait for all three processors to attempt to store the current register to memory and determine if
                  -- at least two of the three processors agree on the value of the current register
                  when s_vsave_4 =>
                     f_MEM_READY0 <= '0';
                     f_MEM_READY1 <= '0';
                     f_MEM_READY2 <= '0';
                  
                  -- Store the current register data to memory
                  when s_vsave_5 =>
                     if (i_MEM_IN0 = i_MEM_IN1) then
                        f_MEM_IN <= i_MEM_IN0;
                     elsif (i_MEM_IN1 = i_MEM_IN2) then
                        f_MEM_IN <= i_MEM_IN1;
                     elsif (i_MEM_IN0 = i_MEM_IN2) then
                        f_MEM_IN <= i_MEM_IN0;
                     end if;
                     if f_save_save_point32(0) = '1' then
                        f_MEM_ADDRESS <= "0000000000000000" & std_logic_vector(unsigned(k_mem_location(15 downto 0)) + unsigned("000000000" & std_logic_vector(f_save_count) & "00"));
                     else
                        f_MEM_ADDRESS <= "0000000000000000" & std_logic_vector(unsigned(k_mem_location(15 downto 0)) + unsigned(k_128_16) + unsigned("000000000" & std_logic_vector(f_save_count) & "00"));
                     end if;
                     f_MEM_WRITE <= '1';
                  
                  -- Wait for all three processors to return the memory write signals to 0
                  when s_vsave_6 =>
                     f_MEM_IN <= (others => '0');
                     f_MEM_ADDRESS <= (others => '0');
                     f_MEM_WRITE <= '0';
                     f_MEM_READY0 <= '1';
                     f_MEM_READY1 <= '1';
                     f_MEM_READY2 <= '1';
                     
                  -- Wait for memory i_MEM_READY to return to 0
                  when s_vsave_6a =>
                     f_MEM_IN <= (others => '0');
                     f_MEM_ADDRESS <= (others => '0');
                     f_MEM_WRITE <= '0';
                     f_MEM_READY0 <= '0';
                     f_MEM_READY1 <= '0';
                     f_MEM_READY2 <= '0';
                  
                  -- Write the updated PC address to memory
                  when s_vsave_7 =>
                     f_MEM_IN <= f_save_address;
                     if f_save_save_point32(0) = '1' then
                        f_MEM_ADDRESS <= std_logic_vector(unsigned(k_mem_location) + unsigned(k_124_32));
                     else
                        f_MEM_ADDRESS <= std_logic_vector(unsigned(k_mem_location) + unsigned(k_252_32));
                     end if;
                     f_MEM_WRITE <= '1';
                     f_MEM_READY0 <= '0';
                     f_MEM_READY1 <= '0';
                     f_MEM_READY2 <= '0';
                     
                  -- Wait for memory i_MEM_READY to return to 0
                  when s_vsave_8 =>
                     f_MEM_IN <= (others => '0');
                     f_MEM_ADDRESS <= (others => '0');
                     f_MEM_WRITE <= '0';
                  
                  -- Update the save point
                  when s_vsave_9 =>
                     if f_save_save_point32(0) = '1' then
                        f_MEM_IN <= (others => '0');
                     else
                        f_MEM_IN <= "11111111111111111111111111111111";
                     end if;
                     f_MEM_ADDRESS <= std_logic_vector(unsigned(k_mem_location) + unsigned(k_256_32));
                     f_MEM_WRITE <= '1';
                     
                  -- Wait for memory ready signal to return to 0
                  when s_vsave_10 =>
                     f_MEM_IN <= (others => '0');
                     f_MEM_ADDRESS <= (others => '0');
                     f_MEM_WRITE <= '0';
                  
                  -- Wait for all three processors to attempt to read an instruction
                  when s_vsave_10a =>
                     f_MEM_IN <= (others => '0');
                     f_MEM_ADDRESS <= (others => '0');
                     f_MEM_WRITE <= '0';
                     
                  -- Issue branch commands to all three processors to return to the previous processing location
                  when s_vsave_11 =>
                     f_MEM_OUT0 <= "0001000000000000" & w_save_branch_distance16;
                     f_MEM_OUT1 <= "0001000000000000" & w_save_branch_distance16;
                     f_MEM_OUT2 <= "0001000000000000" & w_save_branch_distance16;
                     f_MEM_READY0 <= '1';
                     f_MEM_READY1 <= '1';
                     f_MEM_READY2 <= '1';
                  
                  --   Wait for FSM to resume control
                  when s_vsave_12 =>
                     f_MEM_READY0 <= '0';
                     f_MEM_READY1 <= '0';
                     f_MEM_READY2 <= '0';
                  
                  when others =>
                  
               end case;
               
            -- This should never happen
            when others =>
         end case;
      end if;
   end process voter_output_fsm;
   
end a_TMR_Voter_Test28_delay;
