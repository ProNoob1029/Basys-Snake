----------------------------------------------------------------------------------
-- Module Name: vga_sync_generator - Behavioral
-- Description: Generates horizontal/vertical sync signals (HS/VS) and active pixel
--              counters (h_cnt/v_cnt) from the 25MHz pixel clock.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_sync_generator is
    Port (
        clk_25mhz : in  std_logic;
        reset     : in  std_logic;
        h_cnt_out : out unsigned(9 downto 0);
        v_cnt_out : out unsigned(9 downto 0);
        vga_hs    : out std_logic;
        vga_vs    : out std_logic
    );
end vga_sync_generator;

architecture Behavioral of vga_sync_generator is
    signal h_cnt : unsigned(9 downto 0) := (others => '0');
    signal v_cnt : unsigned(9 downto 0) := (others => '0');
begin

    vga_hs <= '0' when h_cnt >= 656 and h_cnt < 752 else '1';
    vga_vs <= '1' when v_cnt = 412 or v_cnt = 413 else '0';

    process(clk_25mhz, reset)
    begin
        if (reset = '1') then
            h_cnt <= (others => '0');
            v_cnt <= (others => '0');
        elsif rising_edge(clk_25mhz) then
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
    
    h_cnt_out <= h_cnt;
    v_cnt_out <= v_cnt;

end Behavioral;
