library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity butterfly is
    Port ( bf_en_n : in STD_LOGIC;
           bf_out : out STD_LOGIC);
end butterfly;

architecture Behavioral of butterfly is

    component latch is
        Port ( LAT_E : in STD_LOGIC;
               LAT_SETN : in STD_LOGIC;
               LAT_RN : in STD_LOGIC;
               LAT_D : in STD_LOGIC;
               LAT_Q : out STD_LOGIC);
    end component;
    
    signal lt1_out, lt2_out : STD_LOGIC;
    
    attribute keep : STRING;
    attribute keep of lt1_out, lt2_out : signal is "true";
    
begin

    latch1: latch Port Map ('1', '1', bf_en_n, lt2_out, lt1_out);
    latch2: latch Port Map ('1', bf_en_n, '1', lt1_out, lt2_out);
    bf_out <= lt1_out;

end Behavioral;
