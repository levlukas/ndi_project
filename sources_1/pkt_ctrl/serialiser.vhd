----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.10.2025 14:08:49
-- Design Name: 
-- Module Name: serialiser - Behavioral
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

entity serialiser is
    Generic (
        data_width : natural
    );
    
    Port ( data : in STD_LOGIC_VECTOR (data_width-1 downto 0);
           load_en : in STD_LOGIC;  -- store the N-bit data
           shift_en : in STD_LOGIC; -- shift the stored values out
           rst : in STD_LOGIC;
           clk : in STD_LOGIC;
           stream : out STD_LOGIC);
end serialiser;

architecture Behavioral of serialiser is

    -- signal
    signal internal_regs : STD_LOGIC_VECTOR (data_width-1 downto 0);

begin

-- sekvencni cast
process (clk) begin   
    
    if rising_edge(clk) then
        if rst = '1' then
            internal_regs <= (others => '0');
            stream <= '0';
        else
            if load_en = '1' then
                internal_regs <= data;
            end if;
            if shift_en = '1' then
                stream <= internal_regs(0);                                      -- 1: LSB to MSB
                internal_regs <= '0' & internal_regs(data_width-1 downto 1);     -- 1: LSB to MSB
                -- stream <= internal_regs(data_width-1);                        -- 2: MSB to LSB
                -- internal_regs <= internal_regs(data_width-2 downto 0) & '0';  -- 2: MSB to LSB
            else
                stream <= '0';
            end if;
        end if;
    end if;

end process;

end Behavioral;
