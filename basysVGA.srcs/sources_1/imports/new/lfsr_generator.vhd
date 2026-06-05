----------------------------------------------------------------------------------
-- Module Name: lfsr_generator - Behavioral
-- Description: 16-bit LFSR for pseudo-random value generation.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lfsr_generator is
    Port (
        clk      : in  std_logic;
        reset    : in  std_logic;
        lfsr_out : out std_logic_vector(15 downto 0)
    );
end lfsr_generator;

architecture Behavioral of lfsr_generator is
    signal lfsr : std_logic_vector(15 downto 0) := X"ACE1";
begin

    process(clk, reset)
        variable feedback : std_logic;
    begin
        if reset = '1' then
            lfsr <= X"ACE1";
        elsif rising_edge(clk) then
            -- Feedback polynomial: x^16 + x^15 + x^13 + x^4 + 1
            feedback := lfsr(15) xor lfsr(14) xor lfsr(12) xor lfsr(3);
            lfsr <= lfsr(14 downto 0) & feedback;
        end if;
    end process;

    lfsr_out <= lfsr;

end Behavioral;
