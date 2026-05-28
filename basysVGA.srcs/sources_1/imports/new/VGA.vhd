----------------------------------------------------------------------------------
-- Module Name: VGA - Behavioral
-- Description: Handles VGA sync generation, scans the snake coordinate array
--              combinationally on a 20x12 grid of 32x32 pixel cells, and
--              renders borders, snake segments with margins, and apples.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.matrix_pkg.all;
use IEEE.NUMERIC_STD.ALL;

entity VGA is
    Port ( 
        vga_r : out std_logic_vector(3 downto 0);
        vga_g : out std_logic_vector(3 downto 0);
        vga_b : out std_logic_vector(3 downto 0);
        vga_hs : out std_logic;
        vga_vs : out std_logic;
        
        clk : in std_logic;
        reset : in std_logic;
        
        body_in : in snake_body_t;
        len_in : in integer range 1 to 128;
        apple_x : in integer range 0 to 19;
        apple_y : in integer range 0 to 11;
        game_over_in : in std_logic
    );
end VGA;

architecture Behavioral of VGA is

signal pix_clock : std_logic;
signal clk_2 : std_logic;

signal h_cnt : unsigned(9 downto 0);
signal v_cnt : unsigned(9 downto 0);

signal col_idx : integer range 0 to 31;
signal row_idx : integer range 0 to 15;

-- Combinational signals to determine if current grid cell is part of snake
signal sig_is_snake  : std_logic;
signal sig_is_head   : std_logic;
signal sig_conn_up   : std_logic;
signal sig_conn_down : std_logic;
signal sig_conn_left : std_logic;
signal sig_conn_right: std_logic;

begin

-- Index division by 32 (h_cnt / 32 and v_cnt / 32)
col_idx <= to_integer(unsigned(h_cnt(9 downto 5))); 
row_idx <= to_integer(unsigned(v_cnt(8 downto 5)));

clk_div_2: process(clk, reset)
begin
    if (reset = '1') then 
        clk_2 <= '0';
    elsif rising_edge(clk) then 
        clk_2 <= not clk_2;
    end if; 
end process;

pix_clk_gen: process(clk_2, reset)
begin 
    if (reset = '1') then 
        pix_clock <= '0';
    elsif rising_edge(clk_2) then
        pix_clock <= not pix_clock;
    end if;
end process;

vga_hs <= '0' when h_cnt >= 656 and h_cnt < 752 else '1';
vga_vs <= '1' when v_cnt = 412 or v_cnt = 413 else '0';

-- Combinational process to check if the current row_idx and col_idx match a snake segment
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
    
    sig_is_snake  <= is_snake;
    sig_is_head   <= is_head;
    sig_conn_up   <= conn_up;
    sig_conn_down <= conn_down;
    sig_conn_left <= conn_left;
    sig_conn_right <= conn_right;
end process;

control: process(pix_clock, reset) 
begin
    if (reset = '1') then
        h_cnt <= to_unsigned(0, h_cnt'length);
        v_cnt <= to_unsigned(0, v_cnt'length); 
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
            elsif (sig_is_snake = '1' and (
                    -- Center 24x24 inside 32x32 cell
                    (h_cnt(4 downto 0) >= 4 and h_cnt(4 downto 0) <= 27 and 
                     v_cnt(4 downto 0) >= 4 and v_cnt(4 downto 0) <= 27) or
                    -- UP connection (extends to top 4-pixel padding)
                    (sig_conn_up = '1' and v_cnt(4 downto 0) < 4 and 
                     h_cnt(4 downto 0) >= 4 and h_cnt(4 downto 0) <= 27) or
                    -- DOWN connection (extends to bottom 4-pixel padding)
                    (sig_conn_down = '1' and v_cnt(4 downto 0) > 27 and 
                     h_cnt(4 downto 0) >= 4 and h_cnt(4 downto 0) <= 27) or
                    -- LEFT connection (extends to left 4-pixel padding)
                    (sig_conn_left = '1' and h_cnt(4 downto 0) < 4 and 
                     v_cnt(4 downto 0) >= 4 and v_cnt(4 downto 0) <= 27) or
                    -- RIGHT connection (extends to right 4-pixel padding)
                    (sig_conn_right = '1' and h_cnt(4 downto 0) > 27 and 
                     v_cnt(4 downto 0) >= 4 and v_cnt(4 downto 0) <= 27)
                   )) then
                -- Draw the snake segment
                if (sig_is_head = '1') then
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
        
        if (h_cnt < 800) then
            h_cnt <= h_cnt + 1;
        else 
            h_cnt <= to_unsigned(0, h_cnt'length);
            if (v_cnt < 449) then 
                v_cnt <= v_cnt + 1;
            else 
                v_cnt <= to_unsigned(0, v_cnt'length);
            end if;
        end if;
    end if;
end process;

end Behavioral;
