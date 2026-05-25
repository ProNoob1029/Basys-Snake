----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.04.2026 14:40:50
-- Design Name: 
-- Module Name: VGA - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.matrix_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity VGA is
    Port ( 
        vga_r : out std_logic_vector(3 downto 0);
        vga_g : out std_logic_vector(3 downto 0);
        vga_b : out std_logic_vector(3 downto 0);
        vga_hs : out std_logic;
        vga_vs : out std_logic;
        
        clk : in std_logic;
        reset : in std_logic;
        
        input : in matrix_25x40
        
       -- clk_out : out std_logic;
       -- hcnt : out unsigned(10 downto 0);
       -- vcnt : out unsigned(10 downto 0)
    );
end VGA;

architecture Behavioral of VGA is

signal pix_clock : std_logic;
signal clk_2 : std_logic;

signal h_cnt : unsigned(9 downto 0);
signal v_cnt : unsigned(9 downto 0);

signal col_idx : integer range 0 to 63;
signal row_idx : integer range 0 to 31;

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
            elsif (input(row_idx)(col_idx) = '1' and 
                   h_cnt(3 downto 0) >= 2 and h_cnt(3 downto 0) <= 13 and 
                   v_cnt(3 downto 0) >= 2 and v_cnt(3 downto 0) <= 13) then
                -- Bright Blue Snake Head (slightly smaller than full square)
                vga_r <= X"4";
                vga_g <= X"7";
                vga_b <= X"F";
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
