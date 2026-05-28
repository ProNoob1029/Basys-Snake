----------------------------------------------------------------------------------
-- Module Name: snake_game - Behavioral
-- Description: Implements movement of the snake body using a 128-element
--              coordinate shift register. Outputs snake_body_t array and length.
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
        
        body_out : out snake_body_t;
        len_out : out integer range 1 to 128
    );
end snake_game;

architecture Behavioral of snake_game is
    -- Game speed controller (5 Hz tick from 100 MHz clock)
    signal tick_counter : unsigned(24 downto 0) := (others => '0');
    signal game_tick : std_logic := '0';
    
    -- Snake body array register
    signal snake_body : snake_body_t;
    signal snake_len  : integer range 1 to 128 := 3;
    
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
    
    -- Update snake positions on game tick
    process(clk, reset)
    begin
        if reset = '1' then
            snake_body(0) <= (x => 20, y => 12);
            snake_body(1) <= (x => 19, y => 12);
            snake_body(2) <= (x => 18, y => 12);
            for i in 3 to 127 loop
                snake_body(i) <= (x => 0, y => 0);
            end loop;
            snake_len <= 3;
            current_dir <= DIR_RIGHT;
        elsif rising_edge(clk) then
            if game_tick = '1' then
                current_dir <= next_dir;
                
                -- Shift body
                for i in 127 downto 1 loop
                    snake_body(i) <= snake_body(i-1);
                end loop;
                
                -- Move head and wrap
                case next_dir is
                    when DIR_UP =>
                        if snake_body(0).y = 1 then
                            snake_body(0).y <= 23;
                        else
                            snake_body(0).y <= snake_body(0).y - 1;
                        end if;
                    when DIR_DOWN =>
                        if snake_body(0).y = 23 then
                            snake_body(0).y <= 1;
                        else
                            snake_body(0).y <= snake_body(0).y + 1;
                        end if;
                    when DIR_LEFT =>
                        if snake_body(0).x = 1 then
                            snake_body(0).x <= 38;
                        else
                            snake_body(0).x <= snake_body(0).x - 1;
                        end if;
                    when DIR_RIGHT =>
                        if snake_body(0).x = 38 then
                            snake_body(0).x <= 1;
                        else
                            snake_body(0).x <= snake_body(0).x + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;
    
    -- Output assignment
    body_out <= snake_body;
    len_out <= snake_len;
    
end Behavioral;
