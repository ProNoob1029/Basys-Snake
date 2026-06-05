----------------------------------------------------------------------------------
-- Module Name: top_level - Behavioral
-- Description: Top-level module that instantiates all 9 modules of the snake game
--              structurally, exposing a clean component hierarchy for Vivado schematics.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
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

    -- 1. Clock Divider Component
    component clk_divider is
        Port (
            clk       : in  std_logic;
            reset     : in  std_logic;
            clk_25mhz : out std_logic;
            game_tick : out std_logic
        );
    end component;

    -- 2. LFSR Random Generator Component
    component lfsr_generator is
        Port (
            clk      : in  std_logic;
            reset    : in  std_logic;
            lfsr_out : out std_logic_vector(15 downto 0)
        );
    end component;

    -- 3. Direction Controller Component
    component direction_controller is
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
    end component;

    -- 4. Core Snake Game Component
    component snake_game is
        Port (
            clk             : in  std_logic;
            reset           : in  std_logic;
            game_tick       : in  std_logic;
            next_dir        : in  direction_t;
            self_collision  : in  std_logic;
            apple_collision : in  std_logic;
            
            body_out        : out snake_body_t;
            len_out         : out integer range 1 to 128;
            current_dir_out : out direction_t;
            spawn_food_out  : out std_logic;
            game_over_out   : out std_logic;
            
            next_head_x_out : out integer range 0 to 19;
            next_head_y_out : out integer range 0 to 11
        );
    end component;

    -- 5. Collision Detector Component
    component collision_detector is
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
    end component;

    -- 6. Apple Generator Component
    component apple_generator is
        Port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            spawn_food   : in  std_logic;
            lfsr         : in  std_logic_vector(15 downto 0);
            snake_body   : in  snake_body_t;
            snake_len    : in  integer range 1 to 128;
            
            apple_x_out  : out integer range 0 to 19;
            apple_y_out  : out integer range 0 to 11;
            spawning_out : out std_logic
        );
    end component;

    -- 7. VGA Sync Generator Component
    component vga_sync_generator is
        Port (
            clk_25mhz : in  std_logic;
            reset     : in  std_logic;
            h_cnt_out : out unsigned(9 downto 0);
            v_cnt_out : out unsigned(9 downto 0);
            vga_hs    : out std_logic;
            vga_vs    : out std_logic
        );
    end component;

    -- 8. Snake Renderer Lookup Component
    component snake_renderer_lookup is
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
    end component;

    -- 9. VGA Color Renderer Component
    component VGA is
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
    end component;

    -- Interconnect signals
    signal clk_25mhz_sig       : std_logic;
    signal game_tick_sig       : std_logic;
    signal lfsr_sig            : std_logic_vector(15 downto 0);
    signal next_dir_sig        : direction_t;
    signal current_dir_sig     : direction_t;
    signal snake_body_sig      : snake_body_t;
    signal snake_len_sig       : integer range 1 to 128;
    signal apple_x_sig         : integer range 0 to 19;
    signal apple_y_sig         : integer range 0 to 11;
    signal next_head_x_sig     : integer range 0 to 19;
    signal next_head_y_sig     : integer range 0 to 11;
    signal self_collision_sig  : std_logic;
    signal apple_collision_sig : std_logic;
    signal spawn_food_sig      : std_logic;
    signal game_over_sig       : std_logic;
    signal h_cnt_sig           : unsigned(9 downto 0);
    signal v_cnt_sig           : unsigned(9 downto 0);
    signal col_idx_sig         : integer range 0 to 31;
    signal row_idx_sig         : integer range 0 to 15;
    
    signal is_snake_sig        : std_logic;
    signal is_head_sig         : std_logic;
    signal conn_up_sig         : std_logic;
    signal conn_down_sig       : std_logic;
    signal conn_left_sig       : std_logic;
    signal conn_right_sig      : std_logic;

begin

    -- Grid coordinate conversions (division by 32)
    col_idx_sig <= to_integer(unsigned(h_cnt_sig(9 downto 5))); 
    row_idx_sig <= to_integer(unsigned(v_cnt_sig(8 downto 5)));

    -- 1. Clock Divider Instance
    u_clk_divider : clk_divider
        port map (
            clk       => clk,
            reset     => reset,
            clk_25mhz => clk_25mhz_sig,
            game_tick => game_tick_sig
        );

    -- 2. LFSR Random Generator Instance
    u_lfsr_generator : lfsr_generator
        port map (
            clk      => clk,
            reset    => reset,
            lfsr_out => lfsr_sig
        );

    -- 3. Direction Controller Instance
    u_direction_controller : direction_controller
        port map (
            clk         => clk,
            reset       => reset,
            btnU        => btnU,
            btnD        => btnD,
            btnL        => btnL,
            btnR        => btnR,
            current_dir => current_dir_sig,
            next_dir    => next_dir_sig
        );

    -- 4. Core Snake Game Instance
    u_snake_game : snake_game
        port map (
            clk             => clk,
            reset           => reset,
            game_tick       => game_tick_sig,
            next_dir        => next_dir_sig,
            self_collision  => self_collision_sig,
            apple_collision => apple_collision_sig,
            body_out        => snake_body_sig,
            len_out         => snake_len_sig,
            current_dir_out => current_dir_sig,
            spawn_food_out  => spawn_food_sig,
            game_over_out   => game_over_sig,
            next_head_x_out => next_head_x_sig,
            next_head_y_out => next_head_y_sig
        );

    -- 5. Collision Detector Instance
    u_collision_detector : collision_detector
        port map (
            next_head_x     => next_head_x_sig,
            next_head_y     => next_head_y_sig,
            snake_body      => snake_body_sig,
            snake_len       => snake_len_sig,
            apple_x         => apple_x_sig,
            apple_y         => apple_y_sig,
            self_collision  => self_collision_sig,
            apple_collision => apple_collision_sig
        );

    -- 6. Apple Generator Instance
    u_apple_generator : apple_generator
        port map (
            clk          => clk,
            reset        => reset,
            spawn_food   => spawn_food_sig,
            lfsr         => lfsr_sig,
            snake_body   => snake_body_sig,
            snake_len    => snake_len_sig,
            apple_x_out  => apple_x_sig,
            apple_y_out  => apple_y_sig,
            spawning_out => open
        );

    -- 7. VGA Sync Generator Instance
    u_vga_sync_generator : vga_sync_generator
        port map (
            clk_25mhz => clk_25mhz_sig,
            reset     => reset,
            h_cnt_out => h_cnt_sig,
            v_cnt_out => v_cnt_sig,
            vga_hs    => vga_hs,
            vga_vs    => vga_vs
        );

    -- 8. Snake Renderer Lookup Instance
    u_snake_renderer_lookup : snake_renderer_lookup
        port map (
            col_idx       => col_idx_sig,
            row_idx       => row_idx_sig,
            body_in       => snake_body_sig,
            len_in        => snake_len_sig,
            is_snake_out  => is_snake_sig,
            is_head_out   => is_head_sig,
            conn_up_out   => conn_up_sig,
            conn_down_out => conn_down_sig,
            conn_left_out => conn_left_sig,
            conn_right_out=> conn_right_sig
        );

    -- 9. VGA Color Renderer Instance
    u_vga_renderer : VGA
        port map (
            vga_r        => vga_r,
            vga_g        => vga_g,
            vga_b        => vga_b,
            pix_clock    => clk_25mhz_sig,
            reset        => reset,
            h_cnt        => h_cnt_sig,
            v_cnt        => v_cnt_sig,
            col_idx      => col_idx_sig,
            row_idx      => row_idx_sig,
            apple_x      => apple_x_sig,
            apple_y      => apple_y_sig,
            is_snake     => is_snake_sig,
            is_head      => is_head_sig,
            conn_up      => conn_up_sig,
            conn_down    => conn_down_sig,
            conn_left    => conn_left_sig,
            conn_right   => conn_right_sig,
            game_over_in => game_over_sig
        );

end Behavioral;
