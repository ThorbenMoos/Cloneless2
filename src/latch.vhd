library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity latch is
    Port ( LAT_E : in STD_LOGIC;
           LAT_SETN : in STD_LOGIC;
           LAT_RN : in STD_LOGIC;
           LAT_D : in STD_LOGIC;
           LAT_Q : out STD_LOGIC);
end latch;

architecture Behavioral of latch is

begin

    latchp: process(LAT_E, LAT_SETN, LAT_RN, LAT_D)
    begin
        if (LAT_RN = '0' AND LAT_SETN = '0') then
            LAT_Q <= '1';
        elsif (LAT_RN = '0') then
            LAT_Q <= '0';
        elsif (LAT_SETN = '0') then
            LAT_Q <= '1';
        elsif (LAT_E = '1') then
            LAT_Q <= LAT_D;
        end if;
    end process;

end Behavioral;