----------------------------------------------------------------------------------
-- Module Name: VGA - Behavioral
-- Description: Handles VGA sync generation, scans the snake coordinate array
--              combinationally, and renders a fully connected Google Snake board.
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
        len_in : in integer range 1 to 128
    );
end VGA;

architecture Behavioral of VGA is

signal pix_clock : std_logic;
signal clk_2 : std_logic;

signal h_cnt : unsigned(9 downto 0);
signal v_cnt : unsigned(9 downto 0);

signal col_idx : integer range 0 to 63;
signal row_idx : integer range 0 to 31;

-- Combinational signals to determine if current grid cell is part of snake
signal sig_is_snake  : std_logic;
signal sig_is_head   : std_logic;
signal sig_conn_up   : std_logic;
signal sig_conn_down : std_logic;
signal sig_conn_left : std_logic;
signal sig_conn_right: std_logic;

begin

col_idx <= to_integer(unsigned(h_cnt(9 downto 4))); 
row_idx <= to_integer(unsigned(v_cnt(8 downto 4)));

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
                    if prev.x = curr.x and (prev.y = curr.y - 1 or (curr.y = 1 and prev.y = 23)) then
                        conn_up := '1';
                    elsif prev.x = curr.x and (prev.y = curr.y + 1 or (curr.y = 23 and prev.y = 1)) then
                        conn_down := '1';
                    elsif prev.y = curr.y and (prev.x = curr.x - 1 or (curr.x = 1 and prev.x = 38)) then
                        conn_left := '1';
                    elsif prev.y = curr.y and (prev.x = curr.x + 1 or (curr.x = 38 and prev.x = 1)) then
                        conn_right := '1';
                    end if;
                end if;
                
                -- Check connection to segment behind (i+1)
                if i < len_in - 1 then
                    nxt := body_in(i+1);
                    if nxt.x = curr.x and (nxt.y = curr.y - 1 or (curr.y = 1 and nxt.y = 23)) then
                        conn_up := '1';
                    elsif nxt.x = curr.x and (nxt.y = curr.y + 1 or (curr.y = 23 and nxt.y = 1)) then
                        conn_down := '1';
                    elsif nxt.y = curr.y and (nxt.x = curr.x - 1 or (curr.x = 1 and nxt.x = 38)) then
                        conn_left := '1';
                    elsif nxt.y = curr.y and (nxt.x = curr.x + 1 or (curr.x = 38 and nxt.x = 1)) then
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
        
        if (h_cnt < 640 and v_cnt < 400) then
            if (row_idx = 0 or row_idx = 24 or col_idx = 0 or col_idx = 39) then
                -- Dark green border (Google Snake style border)
                vga_r <= X"1";
                vga_g <= X"6";
                vga_b <= X"1";
            elsif (sig_is_snake = '1' and (
                    -- Center 12x12
                    (h_cnt(3 downto 0) >= 2 and h_cnt(3 downto 0) <= 13 and 
                     v_cnt(3 downto 0) >= 2 and v_cnt(3 downto 0) <= 13) or
                    -- UP connection (extends to top padding)
                    (sig_conn_up = '1' and v_cnt(3 downto 0) < 2 and 
                     h_cnt(3 downto 0) >= 2 and h_cnt(3 downto 0) <= 13) or
                    -- DOWN connection (extends to bottom padding)
                    (sig_conn_down = '1' and v_cnt(3 downto 0) > 13 and 
                     h_cnt(3 downto 0) >= 2 and h_cnt(3 downto 0) <= 13) or
                    -- LEFT connection (extends to left padding)
                    (sig_conn_left = '1' and h_cnt(3 downto 0) < 2 and 
                     v_cnt(3 downto 0) >= 2 and v_cnt(3 downto 0) <= 13) or
                    -- RIGHT connection (extends to right padding)
                    (sig_conn_right = '1' and h_cnt(3 downto 0) > 13 and 
                     v_cnt(3 downto 0) >= 2 and v_cnt(3 downto 0) <= 13)
                   )) then
                -- Draw the snake segment
                if (sig_is_head = '1') then
                    -- Head: Bright Blue
                    vga_r <= X"4";
                    vga_g <= X"7";
                    vga_b <= X"F";
                else
                    -- Body: Nice Solid Blue
                    vga_r <= X"2";
                    vga_g <= X"5";
                    vga_b <= X"D";
                end if;
            else
                -- Google Snake light green checkers board
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
