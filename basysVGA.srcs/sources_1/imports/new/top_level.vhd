----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.05.2026 16:29:18
-- Design Name: 
-- Module Name: top_level - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_level is
    Port ( vga_r : out STD_LOGIC_VECTOR (3 downto 0);
           vga_g : out STD_LOGIC_VECTOR (3 downto 0);
           vga_b : out STD_LOGIC_VECTOR (3 downto 0);
           vga_hs : out STD_LOGIC;
           vga_vs : out STD_LOGIC;
           clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           btnC : in STD_LOGIC;
           btnU : in STD_LOGIC;
           btnL : in STD_LOGIC;
           btnR : in STD_LOGIC;
           btnD : in STD_LOGIC);
end top_level;

architecture Behavioral of top_level is

component VGA is
    Port ( 
        vga_r : out std_logic_vector(3 downto 0);
        vga_g : out std_logic_vector(3 downto 0);
        vga_b : out std_logic_vector(3 downto 0);
        vga_hs : out std_logic;
        vga_vs : out std_logic;
        
        clk : in std_logic;
        reset : in std_logic;
        
        input : in matrix_25x40
    );
end component;

component snake_game is
    Port (
        clk : in std_logic;
        reset : in std_logic;
        btnU : in std_logic;
        btnD : in std_logic;
        btnL : in std_logic;
        btnR : in std_logic;
        btnC : in std_logic;
        
        grid_out : out matrix_25x40
    );
end component;

signal input : matrix_25x40;

begin

snake_controller : snake_game port map (
    clk => clk,
    reset => reset,
    btnU => btnU,
    btnD => btnD,
    btnL => btnL,
    btnR => btnR,
    btnC => btnC,
    grid_out => input
);

vga_controller : VGA port map (
    vga_r => vga_r,
    vga_g => vga_g,
    vga_b => vga_b,
    vga_hs => vga_hs,
    vga_vs => vga_vs,
    clk => clk,
    reset => reset,
    input => input
);

end Behavioral;
