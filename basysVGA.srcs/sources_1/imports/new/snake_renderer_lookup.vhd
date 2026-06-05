----------------------------------------------------------------------------------
-- Module Name: snake_renderer_lookup - Behavioral
-- Description: Performs combinational searches over the snake segments for the
--              current coordinate row_idx/col_idx, outputting rendering state flags.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.matrix_pkg.all;

entity snake_renderer_lookup is
    Port (
        col_idx       : in  integer range 0 to 31;
        row_idx       : in  integer range 0 to 15;
        body_in       : in  snake_body_t;
        len_in        : in  integer range 1 to 128;
        
        is_snake_out  : out std_logic;
        is_head_out   : out std_logic;
        conn_up_out   : out std_logic;
        conn_down_out : out std_logic;
        conn_left_out : out std_logic;
        conn_right_out: out std_logic
    );
end snake_renderer_lookup;

architecture Behavioral of snake_renderer_lookup is
begin

    process(col_idx, row_idx, body_in, len_in)
        variable is_snake : std_logic;
        variable is_head  : std_logic;
        variable conn_up, conn_down, conn_left, conn_right : std_logic;
        variable curr, prev, nxt : coord_t;
    begin
        is_snake := '0';
        is_head := '0';
        conn_up := '0';
        conn_down := '0';
        conn_left := '0';
        conn_right := '0';
        
        for i in 0 to 127 loop
            if i < len_in then
                curr := body_in(i);
                if curr.x = col_idx and curr.y = row_idx then
                    is_snake := '1';
                    if i = 0 then
                        is_head := '1';
                    end if;
                    
                    -- Check connection to segment in front (i-1)
                    if i > 0 then
                        prev := body_in(i-1);
                        if prev.x = curr.x and (prev.y = curr.y - 1 or (curr.y = 1 and prev.y = 10)) then
                            conn_up := '1';
                        elsif prev.x = curr.x and (prev.y = curr.y + 1 or (curr.y = 10 and prev.y = 1)) then
                            conn_down := '1';
                        elsif prev.y = curr.y and (prev.x = curr.x - 1 or (curr.x = 1 and prev.x = 18)) then
                            conn_left := '1';
                        elsif prev.y = curr.y and (prev.x = curr.x + 1 or (curr.x = 18 and prev.x = 1)) then
                            conn_right := '1';
                        end if;
                    end if;
                    
                    -- Check connection to segment behind (i+1)
                    if i < len_in - 1 then
                        nxt := body_in(i+1);
                        if nxt.x = curr.x and (nxt.y = curr.y - 1 or (curr.y = 1 and nxt.y = 10)) then
                            conn_up := '1';
                        elsif nxt.x = curr.x and (nxt.y = curr.y + 1 or (curr.y = 10 and nxt.y = 1)) then
                            conn_down := '1';
                        elsif nxt.y = curr.y and (nxt.x = curr.x - 1 or (curr.x = 1 and nxt.x = 18)) then
                            conn_left := '1';
                        elsif nxt.y = curr.y and (nxt.x = curr.x + 1 or (curr.x = 18 and nxt.x = 1)) then
                            conn_right := '1';
                        end if;
                    end if;
                end if;
            end if;
        end loop;
        
        is_snake_out  <= is_snake;
        is_head_out   <= is_head;
        conn_up_out   <= conn_up;
        conn_down_out <= conn_down;
        conn_left_out <= conn_left;
        conn_right_out <= conn_right;
    end process;

end Behavioral;
