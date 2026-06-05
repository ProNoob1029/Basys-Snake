----------------------------------------------------------------------------------
-- Module Name: VGA - Behavioral
-- Description: Pixel rendering block. Decides final RGB values of each screen pixel
--              based on the snake rendering status lookup and border/apple ranges.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.matrix_pkg.all;
use IEEE.NUMERIC_STD.ALL;

entity VGA is
    Port ( 
        vga_r        : out std_logic_vector(3 downto 0);
        vga_g        : out std_logic_vector(3 downto 0);
        vga_b        : out std_logic_vector(3 downto 0);
        
        pix_clock    : in  std_logic;
        reset        : in  std_logic;
        h_cnt        : in  unsigned(9 downto 0);
        v_cnt        : in  unsigned(9 downto 0);
        col_idx      : in  integer range 0 to 31;
        row_idx      : in  integer range 0 to 15;
        
        apple_x      : in  integer range 0 to 19;
        apple_y      : in  integer range 0 to 11;
        
        is_snake     : in  std_logic;
        is_head      : in  std_logic;
        conn_up      : in  std_logic;
        conn_down    : in  std_logic;
        conn_left    : in  std_logic;
        conn_right   : in  std_logic;
        game_over_in : in  std_logic
    );
end VGA;

architecture Behavioral of VGA is
begin

    -- Control process running on pixel clock (synchronous RGB drive)
    control: process(pix_clock, reset) 
    begin
        if (reset = '1') then
            vga_r <= X"0";
            vga_g <= X"0";
            vga_b <= X"0";
        elsif rising_edge(pix_clock) then
            
            -- Active boundary: 640x384 (20 columns x 12 rows of size 32x32 pixels)
            if (h_cnt < 640 and v_cnt < 384) then
                if (row_idx = 0 or row_idx = 11 or col_idx = 0 or col_idx = 19) then
                    -- Dark green border (Google Snake style border)
                    vga_r <= X"1";
                    vga_g <= X"6";
                    vga_b <= X"1";
                elsif (row_idx = apple_y and col_idx = apple_x and
                       h_cnt(4 downto 0) >= 6 and h_cnt(4 downto 0) <= 25 and 
                       v_cnt(4 downto 0) >= 6 and v_cnt(4 downto 0) <= 25) then
                    -- Bright Red Apple (centered 20x20 square inside 32x32 cell)
                    vga_r <= X"F";
                    vga_g <= X"1";
                    vga_b <= X"1";
                elsif (is_snake = '1' and (
                        -- Center 24x24 inside 32x32 cell
                        (h_cnt(4 downto 0) >= 4 and h_cnt(4 downto 0) <= 27 and 
                         v_cnt(4 downto 0) >= 4 and v_cnt(4 downto 0) <= 27) or
                        -- UP connection (extends to top 4-pixel padding)
                        (conn_up = '1' and v_cnt(4 downto 0) < 4 and 
                         h_cnt(4 downto 0) >= 4 and h_cnt(4 downto 0) <= 27) or
                        -- DOWN connection (extends to bottom 4-pixel padding)
                        (conn_down = '1' and v_cnt(4 downto 0) > 27 and 
                         h_cnt(4 downto 0) >= 4 and h_cnt(4 downto 0) <= 27) or
                        -- LEFT connection (extends to left 4-pixel padding)
                        (conn_left = '1' and h_cnt(4 downto 0) < 4 and 
                         v_cnt(4 downto 0) >= 4 and v_cnt(4 downto 0) <= 27) or
                        -- RIGHT connection (extends to right 4-pixel padding)
                        (conn_right = '1' and h_cnt(4 downto 0) > 27 and 
                         v_cnt(4 downto 0) >= 4 and v_cnt(4 downto 0) <= 27)
                       )) then
                    -- Draw the snake segment
                    if (is_head = '1') then
                        if (game_over_in = '1') then
                            -- Crashed Head: Dark Red-Brown
                            vga_r <= X"B";
                            vga_g <= X"2";
                            vga_b <= X"2";
                        else
                            -- Head: Bright Blue
                            vga_r <= X"4";
                            vga_g <= X"7";
                            vga_b <= X"F";
                        end if;
                    else
                        if (game_over_in = '1') then
                            -- Crashed Body: Dark Maroon
                            vga_r <= X"7";
                            vga_g <= X"1";
                            vga_b <= X"1";
                        else
                            -- Body: Nice Solid Blue
                            vga_r <= X"2";
                            vga_g <= X"5";
                            vga_b <= X"D";
                        end if;
                    end if;
                else
                    -- Google Snake light green checkers board (32x32 checker tiles)
                    if ((row_idx + col_idx) mod 2 = 0) then
                        vga_r <= X"A";
                        vga_g <= X"D";
                        vga_b <= X"5";
                    else
                        vga_r <= X"9";
                        vga_g <= X"C";
                        vga_b <= X"4";
                    end if;
                end if;            
            else 
                vga_r <= X"0";
                vga_g <= X"0";
                vga_b <= X"0";
            end if;
        end if;
    end process;

end Behavioral;
