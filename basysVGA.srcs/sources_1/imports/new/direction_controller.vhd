----------------------------------------------------------------------------------
-- Module Name: direction_controller - Behavioral
-- Description: Registers button presses to determine the next movement direction,
--              preventing illegal 180-degree immediate reversals.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.matrix_pkg.all;

entity direction_controller is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        btnU        : in  std_logic;
        btnD        : in  std_logic;
        btnL        : in  std_logic;
        btnR        : in  std_logic;
        current_dir : in  direction_t;
        next_dir    : out direction_t
    );
end direction_controller;

architecture Behavioral of direction_controller is
    signal dir_reg : direction_t := DIR_RIGHT;
begin

    process(clk, reset)
    begin
        if reset = '1' then
            dir_reg <= DIR_RIGHT;
        elsif rising_edge(clk) then
            if btnU = '1' and current_dir /= DIR_DOWN then
                dir_reg <= DIR_UP;
            elsif btnD = '1' and current_dir /= DIR_UP then
                dir_reg <= DIR_DOWN;
            elsif btnL = '1' and current_dir /= DIR_RIGHT then
                dir_reg <= DIR_LEFT;
            elsif btnR = '1' and current_dir /= DIR_LEFT then
                dir_reg <= DIR_RIGHT;
            end if;
        end if;
    end process;

    next_dir <= dir_reg;

end Behavioral;
