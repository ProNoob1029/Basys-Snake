----------------------------------------------------------------------------------
-- Module Name: collision_detector - Behavioral
-- Description: Performs combinational loops to detect self-collision and apple-collision.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.matrix_pkg.all;

entity collision_detector is
    Port (
        next_head_x    : in  integer range 0 to 19;
        next_head_y    : in  integer range 0 to 11;
        snake_body     : in  snake_body_t;
        snake_len      : in  integer range 1 to 128;
        apple_x        : in  integer range 0 to 19;
        apple_y        : in  integer range 0 to 11;
        
        self_collision : out std_logic;
        apple_collision: out std_logic
    );
end collision_detector;

architecture Behavioral of collision_detector is
begin

    process(next_head_x, next_head_y, snake_body, snake_len, apple_x, apple_y)
        variable self_hit : std_logic;
    begin
        self_hit := '0';
        for i in 1 to 127 loop
            if i < snake_len then
                if snake_body(i).x = next_head_x and snake_body(i).y = next_head_y then
                    self_hit := '1';
                end if;
            end if;
        end loop;
        
        self_collision <= self_hit;
        
        if next_head_x = apple_x and next_head_y = apple_y then
            apple_collision <= '1';
        else
            apple_collision <= '0';
        end if;
    end process;

end Behavioral;
