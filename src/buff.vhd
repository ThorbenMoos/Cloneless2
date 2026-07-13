library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity buff is
    Port ( I : in STD_LOGIC;
           Z : out STD_LOGIC);
end buff;

architecture Behavioral of buff is

    signal inter : STD_LOGIC;
    
begin

    inter <= NOT I;
    Z <= NOT inter;

end Behavioral;
