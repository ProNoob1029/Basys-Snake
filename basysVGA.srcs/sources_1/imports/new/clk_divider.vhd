----------------------------------------------------------------------------------
-- Module Name: clk_divider - Behavioral
-- Description: Divides 100MHz clock to generate 25MHz pixel clock and 5Hz game tick.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clk_divider is
    Port (
        clk       : in  std_logic;
        reset     : in  std_logic;
        clk_25mhz : out std_logic;
        game_tick : out std_logic
    );
end clk_divider;

architecture Behavioral of clk_divider is
    signal clk_2        : std_logic := '0';
    signal clk_25       : std_logic := '0';
    signal tick_counter : unsigned(24 downto 0) := (others => '0');
begin

    -- Divide 100MHz clock by 2 to get 50MHz
    clk_div_2: process(clk, reset)
    begin
        if (reset = '1') then 
            clk_2 <= '0';
        elsif rising_edge(clk) then 
            clk_2 <= not clk_2;
        end if; 
    end process;

    -- Divide 50MHz clock by 2 to get 25MHz (pixel clock)
    pix_clk_gen: process(clk_2, reset)
    begin 
        if (reset = '1') then 
            clk_25 <= '0';
        elsif rising_edge(clk_2) then
            clk_25 <= not clk_25;
        end if;
    end process;
    
    clk_25mhz <= clk_25;

    -- Game speed divider (100MHz clock / 20,000,000 to get a 5Hz pulse)
    game_tick_gen: process(clk, reset)
    begin
        if reset = '1' then
            tick_counter <= (others => '0');
            game_tick <= '0';
        elsif rising_edge(clk) then
            if tick_counter = 19999999 then
                tick_counter <= (others => '0');
                game_tick <= '1';
            else
                tick_counter <= tick_counter + 1;
                game_tick <= '0';
            end if;
        end if;
    end process;

end Behavioral;
