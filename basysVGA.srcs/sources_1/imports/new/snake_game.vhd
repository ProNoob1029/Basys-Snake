----------------------------------------------------------------------------------
-- Module Name: snake_game - Behavioral
-- Description: Implements movement of the snake head on a 25x40 grid.
--              Includes a 5Hz game clock divider, direction buffers,
--              position tracking with wrap-around, and grid generation.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.matrix_pkg.all;

entity snake_game is
    Port (
        clk : in std_logic;
        reset : in std_logic;
        btnU : in std_logic;
        btnD : in std_logic;
        btnL : in std_logic;
        btnR : in std_logic;
        btnC : in std_logic;
        
        grid_out : out matrix_25x40
    );
end snake_game;

architecture Behavioral of snake_game is
    -- Game speed controller (5 Hz tick from 100 MHz clock)
    signal tick_counter : unsigned(24 downto 0) := (others => '0');
    signal game_tick : std_logic := '0';
    
    -- Snake head coordinates (starts at center of playable area)
    signal head_x : integer range 0 to 39 := 20;
    signal head_y : integer range 0 to 24 := 12;
    
    -- Direction state
    type direction_t is (DIR_UP, DIR_DOWN, DIR_LEFT, DIR_RIGHT);
    signal current_dir : direction_t := DIR_RIGHT;
    signal next_dir    : direction_t := DIR_RIGHT;
    
begin

    -- Clock divider for 5Hz game tick (100 MHz clock / 20,000,000)
    process(clk, reset)
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
    
    -- Register button presses to buffer next direction
    -- Avoid 180-degree immediate turns (e.g. going directly down when moving up)
    process(clk, reset)
    begin
        if reset = '1' then
            next_dir <= DIR_RIGHT;
        elsif rising_edge(clk) then
            if btnU = '1' and current_dir /= DIR_DOWN then
                next_dir <= DIR_UP;
            elsif btnD = '1' and current_dir /= DIR_UP then
                next_dir <= DIR_DOWN;
            elsif btnL = '1' and current_dir /= DIR_RIGHT then
                next_dir <= DIR_LEFT;
            elsif btnR = '1' and current_dir /= DIR_LEFT then
                next_dir <= DIR_RIGHT;
            end if;
        end if;
    end process;
    
    -- Update snake head position on game tick
    process(clk, reset)
    begin
        if reset = '1' then
            head_x <= 20;
            head_y <= 12;
            current_dir <= DIR_RIGHT;
        elsif rising_edge(clk) then
            if game_tick = '1' then
                current_dir <= next_dir;
                
                -- Move snake head and wrap within playable area (cols 1 to 38, rows 1 to 23)
                case next_dir is
                    when DIR_UP =>
                        if head_y = 1 then
                            head_y <= 23;
                        else
                            head_y <= head_y - 1;
                        end if;
                    when DIR_DOWN =>
                        if head_y = 23 then
                            head_y <= 1;
                        else
                            head_y <= head_y + 1;
                        end if;
                    when DIR_LEFT =>
                        if head_x = 1 then
                            head_x <= 38;
                        else
                            head_x <= head_x - 1;
                        end if;
                    when DIR_RIGHT =>
                        if head_x = 38 then
                            head_x <= 1;
                        else
                            head_x <= head_x + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;
    
    -- Generate the grid matrix output
    process(head_x, head_y)
        variable temp_grid : matrix_25x40;
    begin
        -- Fill grid with zeros
        for y in 0 to 24 loop
            temp_grid(y) := (others => '0');
        end loop;
        
        -- Place the snake head
        if head_y >= 0 and head_y <= 24 and head_x >= 0 and head_x <= 39 then
            temp_grid(head_y)(head_x) := '1';
        end if;
        
        grid_out <= temp_grid;
    end process;

end Behavioral;
