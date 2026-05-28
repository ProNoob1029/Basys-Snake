----------------------------------------------------------------------------------
-- Module Name: top_level - Behavioral
-- Description: Top-level module that instantiates the snake game controller
--              and VGA controller, wiring the snake body, length, and apple signals.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.matrix_pkg.all;

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
        
        body_in : in snake_body_t;
        len_in : in integer range 1 to 128;
        apple_x : in integer range 0 to 39;
        apple_y : in integer range 0 to 24
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
        
        body_out : out snake_body_t;
        len_out : out integer range 1 to 128;
        apple_x_out : out integer range 0 to 39;
        apple_y_out : out integer range 0 to 24
    );
end component;

signal snake_body_sig : snake_body_t;
signal snake_len_sig  : integer range 1 to 128;
signal apple_x_sig    : integer range 0 to 39;
signal apple_y_sig    : integer range 0 to 24;

begin

snake_controller : snake_game port map (
    clk => clk,
    reset => reset,
    btnU => btnU,
    btnD => btnD,
    btnL => btnL,
    btnR => btnR,
    btnC => btnC,
    body_out => snake_body_sig,
    len_out => snake_len_sig,
    apple_x_out => apple_x_sig,
    apple_y_out => apple_y_sig
);

vga_controller : VGA port map (
    vga_r => vga_r,
    vga_g => vga_g,
    vga_b => vga_b,
    vga_hs => vga_hs,
    vga_vs => vga_vs,
    clk => clk,
    reset => reset,
    body_in => snake_body_sig,
    len_in => snake_len_sig,
    apple_x => apple_x_sig,
    apple_y => apple_y_sig
);

end Behavioral;
