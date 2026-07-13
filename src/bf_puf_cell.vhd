library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bf_puf_cell is
    Generic (cycles1 : INTEGER := 5;
             cycles2 : INTEGER := 500);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           raw_bit : out STD_LOGIC;
           done : out STD_LOGIC);
end bf_puf_cell;

architecture Behavioral of bf_puf_cell is

    component butterfly is
        Port ( bf_en_n : in STD_LOGIC;
               bf_out : out STD_LOGIC);
    end component;

    signal bf_en_n, bf_out : STD_LOGIC;
    
    attribute keep : STRING;
    attribute keep of bf_en_n, bf_out : signal is "true";

begin

    -- instantiate butterfly
    bf_inst: butterfly Port Map (bf_en_n, bf_out);
    
	-- fsm process
    fsm: process(clk)
        variable cnt1 : INTEGER range 0 to cycles1;
        variable cnt2 : INTEGER range 0 to cycles2;
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                bf_en_n                 <= '1';
                raw_bit                 <= '0';
                done                    <= '0';
                cnt1                    := 0;
                cnt2                    := 0;
            else
                if (en = '1') then
                    bf_en_n             <= '0';
                    if (cnt1 < cycles1) then
                        cnt1            := cnt1 + 1;
                    else
                        bf_en_n         <= '1';
                        if (cnt2 < cycles2) then
                            cnt2        := cnt2 + 1;
                        else
                            raw_bit     <= bf_out;
                            done        <= '1';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
