----------------------------------------------------------------------------------
-- Module Name: snake_game - Behavioral
-- Description: Core snake game logic. Manages coordinate registers (body, length)
--              and updates positions on game ticks based on external collisions.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.matrix_pkg.all;

entity snake_game is
    Port (
        clk             : in  std_logic;
        reset           : in  std_logic;
        game_tick       : in  std_logic;
        next_dir        : in  direction_t;
        self_collision  : in  std_logic;
        apple_collision : in  std_logic;
        
        body_out        : out snake_body_t;
        len_out         : out integer range 1 to 128;
        current_dir_out : out direction_t;
        spawn_food_out  : out std_logic;
        game_over_out   : out std_logic;
        
        next_head_x_out : out integer range 0 to 19;
        next_head_y_out : out integer range 0 to 11
    );
end snake_game;

architecture Behavioral of snake_game is
    -- Snake body array register (starts at center of playable area: x=10, y=6)
    signal snake_body : snake_body_t := (
        0 => (x => 10, y => 6),
        1 => (x => 9, y => 6),
        2 => (x => 8, y => 6),
        others => (x => 0, y => 0)
    );
    signal snake_len  : integer range 1 to 128 := 3;
    
    signal current_dir : direction_t := DIR_RIGHT;
    signal game_over   : std_logic := '0';
    signal spawn_food  : std_logic := '0';
    
    -- Intermediate signals for next head calculation
    signal next_head_x_sig : integer range 0 to 19;
    signal next_head_y_sig : integer range 0 to 11;
begin

    -- Combinational process to compute the candidate next head position
    process(next_dir, snake_body)
    begin
        case next_dir is
            when DIR_UP =>
                if snake_body(0).y = 1 then
                    next_head_y_sig <= 10;
                else
                    next_head_y_sig <= snake_body(0).y - 1;
                end if;
                next_head_x_sig <= snake_body(0).x;
            when DIR_DOWN =>
                if snake_body(0).y = 10 then
                    next_head_y_sig <= 1;
                else
                    next_head_y_sig <= snake_body(0).y + 1;
                end if;
                next_head_x_sig <= snake_body(0).x;
            when DIR_LEFT =>
                if snake_body(0).x = 1 then
                    next_head_x_sig <= 18;
                else
                    next_head_x_sig <= snake_body(0).x - 1;
                end if;
                next_head_y_sig <= snake_body(0).y;
            when DIR_RIGHT =>
                if snake_body(0).x = 18 then
                    next_head_x_sig <= 1;
                else
                    next_head_x_sig <= snake_body(0).x + 1;
                end if;
                next_head_y_sig <= snake_body(0).y;
        end case;
    end process;

    next_head_x_out <= next_head_x_sig;
    next_head_y_out <= next_head_y_sig;

    -- Synchronous update process
    process(clk, reset)
    begin
        if reset = '1' then
            snake_body(0) <= (x => 10, y => 6);
            snake_body(1) <= (x => 9, y => 6);
            snake_body(2) <= (x => 8, y => 6);
            for i in 3 to 127 loop
                snake_body(i) <= (x => 0, y => 0);
            end loop;
            snake_len   <= 3;
            current_dir <= DIR_RIGHT;
            game_over   <= '0';
            spawn_food  <= '0';
        elsif rising_edge(clk) then
            -- Default pulse states
            spawn_food <= '0';
            
            if game_tick = '1' and game_over = '0' then
                if self_collision = '1' then
                    game_over <= '1';
                else
                    current_dir <= next_dir;
                    
                    -- Shift body segments
                    for i in 127 downto 1 loop
                        snake_body(i) <= snake_body(i-1);
                    end loop;
                    
                    -- Update head
                    snake_body(0) <= (x => next_head_x_sig, y => next_head_y_sig);
                    
                    -- Apple collision check (growth and food trigger)
                    if apple_collision = '1' then
                        if snake_len < 128 then
                            snake_len <= snake_len + 1;
                        end if;
                        spawn_food <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Output wire connections
    body_out <= snake_body;
    len_out  <= snake_len;
    current_dir_out <= current_dir;
    spawn_food_out  <= spawn_food;
    game_over_out   <= game_over;

end Behavioral;
