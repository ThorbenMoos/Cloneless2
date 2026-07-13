library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mps_ipm_controller is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           core_done : in STD_LOGIC;
           trng_puf_config : in STD_LOGIC_VECTOR (2 downto 0);
           seed : in STD_LOGIC_VECTOR (159 downto 0);
           const_key1 : in STD_LOGIC_VECTOR (247 downto 0);
           const_key2 : in STD_LOGIC_VECTOR (247 downto 0);
           trv_keys : out STD_LOGIC_VECTOR (159 downto 0);
           key : out STD_LOGIC_VECTOR (247 downto 0);
           ciphertext_register_parallel_enable : out STD_LOGIC;
           core_rst : out STD_LOGIC;
           done : out STD_LOGIC;
           trigger : out STD_LOGIC);
end mps_ipm_controller;

architecture Behavioral of mps_ipm_controller is

    component es_trng is
        Generic (bits : INTEGER := 128;
                 ro1length : INTEGER := 1;
                 ro2length : INTEGER := 3;
                 factor : INTEGER := 3);
        Port ( clk : in STD_LOGIC;
               rst : in STD_LOGIC;
               en : in STD_LOGIC;
               outpt : out STD_LOGIC_VECTOR (bits-1 downto 0);
               done : out STD_LOGIC);
    end component;

    component bf_puf is
        Generic (bits : INTEGER := 128;
                 parallel : INTEGER := 32;
                 cycles1 : INTEGER := 5;
                 cycles2 : INTEGER := 500;
                 factor : INTEGER := 3);
        Port ( clk : in STD_LOGIC;
               rst : in STD_LOGIC;
               en : in STD_LOGIC;
               outpt : out STD_LOGIC_VECTOR (bits-1 downto 0);
               done : out STD_LOGIC);
    end component;
    
    signal ipm_estrng_rst, ipm_estrng_en, ipm_estrng_done, ipm_estrng1_done, ipm_estrng2_done : STD_LOGIC;
    signal ipm_bfpuf_rst, ipm_bfpuf_en, ipm_bfpuf_done, ipm_bfpuf1_done, ipm_bfpuf2_done : STD_LOGIC;
    signal ipm_estrng1_outpt, ipm_estrng2_outpt : STD_LOGIC_VECTOR (79 downto 0);
    signal ipm_bfpuf1_outpt, ipm_bfpuf2_outpt : STD_LOGIC_VECTOR (15 downto 0);
    
    type states is (S_RESET, S_TRNG, S_PUF, S_COMPUTE, S_OUTPT, S_DONE);
    signal state : states;

begin

    ESTRNG1: es_trng Generic Map (80, 23, 47, 7) Port Map (clk, ipm_estrng_rst, ipm_estrng_en, ipm_estrng1_outpt, ipm_estrng1_done);
    ESTRNG2: es_trng Generic Map (80, 23, 47, 7) Port Map (clk, ipm_estrng_rst, ipm_estrng_en, ipm_estrng2_outpt, ipm_estrng2_done);
    ipm_estrng_done <= ipm_estrng1_done AND ipm_estrng2_done;
    
    BFPUF1: bf_puf Generic Map (16, 4, 5, 511, 7) Port Map (clk, ipm_bfpuf_rst, ipm_bfpuf_en, ipm_bfpuf1_outpt, ipm_bfpuf1_done);
    BFPUF2: bf_puf Generic Map (16, 4, 5, 511, 7) Port Map (clk, ipm_bfpuf_rst, ipm_bfpuf_en, ipm_bfpuf2_outpt, ipm_bfpuf2_done);
    ipm_bfpuf_done <= ipm_bfpuf1_done AND ipm_bfpuf2_done;

    -- State Machine
    FSM: process(clk)
        variable counter : integer range 0 to 7;
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                ipm_estrng_rst                          <= '0';
                ipm_estrng_en                           <= '0';
                ipm_bfpuf_rst                           <= '0';
                ipm_bfpuf_en                            <= '0';
                trv_keys                                <= (others => '0');
                key                                     <= (others => '0');
                ciphertext_register_parallel_enable     <= '0';
                core_rst                                <= '0';
                done                                    <= '0';
                trigger                                 <= '0';
                counter                                 := 0;
                STATE                                   <= S_RESET;
            else
                if (en = '1') then
                    case state is

                        when S_RESET =>         core_rst                                <= '1';
                                                ipm_estrng_rst                          <= '1';
                                                ipm_bfpuf_rst                           <= '1';
                                                counter                                 := counter + 1;
                                                if (counter = 7) then
                                                    counter                             := 0;
                                                    if (trng_puf_config = "000") then
                                                        trv_keys                        <= seed;
                                                        key                             <= const_key1;
                                                        state                           <= S_COMPUTE;
                                                    elsif (trng_puf_config = "001") then
                                                        trv_keys                        <= seed;
                                                        key                             <= const_key2;
                                                        state                           <= S_COMPUTE;
                                                    elsif (trng_puf_config(1) = '1') then
                                                        state                           <= S_TRNG;
                                                    elsif (trng_puf_config(2) = '1') then
                                                        trv_keys                        <= seed;
                                                        state                           <= S_PUF;
                                                    end if;
                                                end if;

                        when S_TRNG =>          ipm_estrng_rst                          <= '0';
                                                ipm_estrng_en                           <= '1';
                                                if (ipm_estrng_done = '1') then
                                                    ipm_estrng_en                       <= '0';
                                                    trv_keys                            <= ipm_estrng1_outpt & ipm_estrng2_outpt;
                                                    if (trng_puf_config(2) = '1') then
                                                        state                           <= S_PUF;
                                                    else
                                                        if (trng_puf_config(0) = '0') then
                                                            key                         <= const_key1;
                                                            state                       <= S_COMPUTE;
                                                        else
                                                            key                         <= const_key2;
                                                            state                       <= S_COMPUTE;
                                                        end if;
                                                    end if;
                                                end if;

                        when S_PUF =>           ipm_bfpuf_rst                           <= '0';
                                                ipm_bfpuf_en                            <= '1';
                                                if (ipm_bfpuf_done = '1') then
                                                    ipm_bfpuf_en                        <= '0';
                                                    if (trng_puf_config(0) = '0') then
                                                        key                             <=  const_key1(247 downto 221) & ipm_bfpuf1_outpt(15 downto 12) & const_key1(216 downto 190) & ipm_bfpuf1_outpt(11 downto 8) & const_key1(185 downto 159) & ipm_bfpuf1_outpt(7 downto 4) & const_key1(154 downto 128) & ipm_bfpuf1_outpt(3 downto 0) & const_key1(123 downto 97) & ipm_bfpuf2_outpt(15 downto 12) & const_key1(92 downto 66) & ipm_bfpuf2_outpt(11 downto 8) & const_key1(61 downto 35) & ipm_bfpuf2_outpt(7 downto 4) & const_key1(30 downto 4) & ipm_bfpuf2_outpt(3 downto 0);
                                                    else
                                                        key                             <=  const_key2(247 downto 221) & ipm_bfpuf1_outpt(15 downto 12) & const_key2(216 downto 190) & ipm_bfpuf1_outpt(11 downto 8) & const_key2(185 downto 159) & ipm_bfpuf1_outpt(7 downto 4) & const_key2(154 downto 128) & ipm_bfpuf1_outpt(3 downto 0) & const_key2(123 downto 97) & ipm_bfpuf2_outpt(15 downto 12) & const_key2(92 downto 66) & ipm_bfpuf2_outpt(11 downto 8) & const_key2(61 downto 35) & ipm_bfpuf2_outpt(7 downto 4) & const_key2(30 downto 4) & ipm_bfpuf2_outpt(3 downto 0);
                                                    end if;
                                                    state                               <= S_COMPUTE;
                                                end if;

                        when S_COMPUTE =>       core_rst                                <= '0';
                                                trigger                                 <= '1';
                                                if (core_done = '1') then
                                                    trigger                             <= '0';
                                                    state                               <= S_OUTPT;
                                                end if;

                        when S_OUTPT =>         ciphertext_register_parallel_enable     <= '1';
                                                counter                                 := counter + 1;
                                                if (counter = 3) then
                                                    counter                             := 0;
                                                    state                               <= S_DONE;
                                                end if;

                        when S_DONE =>          ciphertext_register_parallel_enable     <= '0';
                                                done                                    <= '1';

                    end case;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
