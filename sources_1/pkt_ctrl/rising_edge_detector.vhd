----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.09.2025 14:18:40
-- Design Name: 
-- Module Name: cv1_1 - Behavioral
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

entity rising_edge_detector is
    Port ( clk : in STD_LOGIC;
           sig_in : in STD_LOGIC;
           sig_out : out STD_LOGIC);
end rising_edge_detector;

architecture Behavioral of rising_edge_detector is

    -- signal declaration
    signal d_out : STD_LOGIC;
    signal xor_out : STD_LOGIC;

begin

-- kombinacni cast
xor_out <= (sig_in xor d_out);
sig_out <= (xor_out and sig_in);

-- sekvencni
process (clk) begin
    if rising_edge(clk) then
        d_out <= sig_in;
    end if;
end process;    

end Behavioral;
