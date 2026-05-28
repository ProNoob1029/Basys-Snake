----------------------------------------------------------------------------------
-- Module Name: snake_game - Behavioral
-- Description: Implements movement of the snake body on a 20x12 grid using
--              a 128-element shift register, LFSR pseudo-random food generator,
--              eating collision checking, self-collision crash detection,
--              and game over logic.
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
        len_out : out integer range 1 to 128;
        apple_x_out : out integer range 0 to 19;
        apple_y_out : out integer range 0 to 11;
        game_over_out : out std_logic
    );
end snake_game;

architecture Behavioral of snake_game is
    -- Game speed controller (5 Hz tick from 100 MHz clock)
    signal tick_counter : unsigned(24 downto 0) := (others => '0');
    signal game_tick : std_logic := '0';
    
    -- Snake body array register (starts at center of playable area: x=10, y=6)
    signal snake_body : snake_body_t := (
        0 => (x => 10, y => 6),
        1 => (x => 9, y => 6),
        2 => (x => 8, y => 6),
        others => (x => 0, y => 0)
    );
    signal snake_len  : integer range 1 to 128 := 3;
    
    -- Direction state
    type direction_t is (DIR_UP, DIR_DOWN, DIR_LEFT, DIR_RIGHT);
    signal current_dir : direction_t := DIR_RIGHT;
    signal next_dir    : direction_t := DIR_RIGHT;
    
    -- LFSR for random number generation (seeded with non-zero value ACE1)
    signal lfsr : std_logic_vector(15 downto 0) := X"ACE1";
    
    -- Food positions
    signal apple_x : integer range 0 to 19 := 5;
    signal apple_y : integer range 0 to 11 := 5;
    signal spawn_food : std_logic := '0';
    
    -- Game state
    signal game_over : std_logic := '0';
    
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
    
    -- Main synchronous process for LFSR, game tick movement, and food spawning
    process(clk, reset)
        variable feedback : std_logic;
        variable next_head_x : integer range 0 to 19;
        variable next_head_y : integer range 0 to 11;
        variable cand_x : integer range 0 to 19;
        variable cand_y : integer range 0 to 11;
        variable on_snake : boolean;
        variable crash : boolean;
    begin
        if reset = '1' then
            snake_body(0) <= (x => 10, y => 6);
            snake_body(1) <= (x => 9, y => 6);
            snake_body(2) <= (x => 8, y => 6);
            for i in 3 to 127 loop
                snake_body(i) <= (x => 0, y => 0);
            end loop;
            snake_len <= 3;
            current_dir <= DIR_RIGHT;
            lfsr <= X"ACE1";
            apple_x <= 5;
            apple_y <= 5;
            spawn_food <= '0';
            game_over <= '0';
            
        elsif rising_edge(clk) then
            -- 1. LFSR shifting
            feedback := lfsr(15) xor lfsr(14) xor lfsr(12) xor lfsr(3);
            lfsr <= lfsr(14 downto 0) & feedback;
            
            -- 2. Food spawner logic (only active when not game over)
            if spawn_food = '1' and game_over = '0' then
                cand_x := (to_integer(unsigned(lfsr)) mod 18) + 1; -- columns 1 to 18
                cand_y := (to_integer(unsigned(lfsr(11 downto 4))) mod 10) + 1; -- rows 1 to 10
                
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
                    spawn_food <= '0';
                end if;
            end if;
            
            -- 3. Snake movement on game tick (only active when not game over)
            if game_tick = '1' and game_over = '0' then
                -- Calculate next head position (wrapping within playable boundaries 1..18, 1..10)
                case next_dir is
                    when DIR_UP =>
                        if snake_body(0).y = 1 then next_head_y := 10; else next_head_y := snake_body(0).y - 1; end if;
                        next_head_x := snake_body(0).x;
                    when DIR_DOWN =>
                        if snake_body(0).y = 10 then next_head_y := 1; else next_head_y := snake_body(0).y + 1; end if;
                        next_head_x := snake_body(0).x;
                    when DIR_LEFT =>
                        if snake_body(0).x = 1 then next_head_x := 18; else next_head_x := snake_body(0).x - 1; end if;
                        next_head_y := snake_body(0).y;
                    when DIR_RIGHT =>
                        if snake_body(0).x = 18 then next_head_x := 1; else next_head_x := snake_body(0).x + 1; end if;
                        next_head_y := snake_body(0).y;
                end case;
                
                -- Check for self-collision crash
                crash := false;
                for i in 1 to 127 loop
                    if i < snake_len then
                        if snake_body(i).x = next_head_x and snake_body(i).y = next_head_y then
                            crash := true;
                        end if;
                    end if;
                end loop;
                
                if crash then
                    game_over <= '1';
                else
                    current_dir <= next_dir;
                    
                    -- Shift body
                    for i in 127 downto 1 loop
                        snake_body(i) <= snake_body(i-1);
                    end loop;
                    
                    -- Set the new head
                    snake_body(0) <= (x => next_head_x, y => next_head_y);
                    
                    -- Collision check with apple
                    if next_head_x = apple_x and next_head_y = apple_y then
                        if snake_len < 128 then
                            snake_len <= snake_len + 1;
                        end if;
                        spawn_food <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- Outputs
    body_out <= snake_body;
    len_out <= snake_len;
    apple_x_out <= apple_x;
    apple_y_out <= apple_y;
    game_over_out <= game_over;
    
end Behavioral;
