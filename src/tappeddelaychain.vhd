library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tappeddelaychain is
    Port ( ro1_out : in STD_LOGIC;
           ro2_out : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           stage : out STD_LOGIC_VECTOR (2 downto 0));
end tappeddelaychain;

architecture Behavioral of tappeddelaychain is
    
    component buff is
        Port ( I : in STD_LOGIC;
               Z : out STD_LOGIC);
    end component;
    
    component FF_arst is
        Port ( clk : in STD_LOGIC;
               rst : in STD_LOGIC;
               en : in STD_LOGIC;
               inpt : in STD_LOGIC;
               outpt : out STD_LOGIC);
    end component;
    
    signal stage_reg : STD_LOGIC_VECTOR (4 downto 0);
    
    attribute keep : STRING;
    attribute keep of stage_reg : signal is "true";

begin

    -- buf instances for delay
    stage_reg(0) <= ro1_out;
    genb: for i in 0 to 3 generate
        buff_inst : buff Port Map (stage_reg(i), stage_reg(i+1));
    end generate;
   
    -- fcde instances for sampling
    genf: for i in 0 to 2 generate
        ff_inst: FF_arst Port Map (ro2_out, rst, en, stage_reg(i+1), stage(i));
    end generate;

end Behavioral;