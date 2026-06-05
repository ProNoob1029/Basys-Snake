----------------------------------------------------------------------------------
-- Module Name: apple_generator - Behavioral
-- Description: Generates new apple coordinates using an LFSR seed when requested,
--              ensuring it does not overlap with any snake body segments.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.matrix_pkg.all;

entity apple_generator is
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        spawn_food   : in  std_logic;
        lfsr         : in  std_logic_vector(15 downto 0);
        snake_body   : in  snake_body_t;
        snake_len    : in  integer range 1 to 128;
        
        apple_x_out  : out integer range 0 to 19;
        apple_y_out  : out integer range 0 to 11;
        spawning_out : out std_logic
    );
end apple_generator;

architecture Behavioral of apple_generator is
    signal apple_x : integer range 0 to 19 := 5;
    signal apple_y : integer range 0 to 11 := 5;
    signal active_spawn : std_logic := '0';
begin

    process(clk, reset)
        variable cand_x : integer range 0 to 19;
        variable cand_y : integer range 0 to 11;
        variable on_snake : boolean;
    begin
        if reset = '1' then
            apple_x <= 5;
            apple_y <= 5;
            active_spawn <= '0';
        elsif rising_edge(clk) then
            if spawn_food = '1' then
                active_spawn <= '1';
            elsif active_spawn = '1' then
                -- Generate candidate coordinates: columns 1..18, rows 1..10
                cand_x := (to_integer(unsigned(lfsr)) mod 18) + 1;
                cand_y := (to_integer(unsigned(lfsr(11 downto 4))) mod 10) + 1;
                
                -- Check for overlap with the snake body
                on_snake := false;
                for i in 0 to 127 loop
                    if i < snake_len then
                        if snake_body(i).x = cand_x and snake_body(i).y = cand_y then
                            on_snake := true;
                        end if;
                    end if;
                end loop;
                
                if not on_snake then
                    apple_x <= cand_x;
                    apple_y <= cand_y;
                    active_spawn <= '0';
                end if;
            end if;
        end if;
    end process;
    
    apple_x_out <= apple_x;
    apple_y_out <= apple_y;
    spawning_out <= active_spawn;

end Behavioral;
