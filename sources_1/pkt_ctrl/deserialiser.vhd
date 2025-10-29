----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/01/2025 05:12:48 PM
-- Design Name: 
-- Module Name: deserialiser - Behavioral
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
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity deserialiser is
    Generic (
        data_width : natural := 7
    );
    
    Port ( stream, shift_en, rst, clk : in STD_LOGIC;
           data : out STD_LOGIC_VECTOR (data_width-1 downto 0)
           );
end deserialiser;

architecture Behavioral of deserialiser is

    -- signal definition
    signal internal_regs : std_logic_vector (data_width - 1 downto 0);    

begin

-- sequence part
process (clk) begin
    -- at rising edge
    if rising_edge(clk) then
    
        if rst = '1' then
            internal_regs <= (others => '0');
            data <= (others => '0');
        else
            if shift_en = '1' then
                internal_regs <= internal_regs(data_width-2 downto 0) & stream;  -- LSB to MSB
                --internal_regs <= stream & internal_regs(data_width-1 downto 1);  -- MSB to LSB   
            end if;
            data <= internal_regs;
        end if;
        
    end if;
end process;    

end Behavioral;
