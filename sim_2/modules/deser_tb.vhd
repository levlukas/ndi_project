----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.10.2025 14:31:13
-- Design Name: 
-- Module Name: ser_tb - Behavioral
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

entity deser_tb is
    -- entity is empty, testbench has no inputs nor outputs
end deser_tb;

architecture testbench of deser_tb is

----------------------------------------------------------------------------------
-- tb constants
constant c_CLK_PER : time := 10 ns;
constant data_width : natural := 5;


-- DUT input & output signals
signal clk, rst, shift_en, stream : std_logic;
signal data : std_logic_vector (data_width-1 downto 0);


begin
----------------------------------------------------------------------------------
-- instance of component
i_dut : entity work.deserialiser(Behavioral)
    generic map (
        data_width => data_width
    )    
    port map (
        clk => clk,
        shift_en => shift_en,
        rst => rst,
        data => data,
        stream => stream
    );

----------------------------------------------------------------------------------
-- clock generator, process is running all the time - when end of process is reached,
-- it is started again from the begining (effectively infinite loop)
p_clk_gen : process 
    begin
        clk <= '0';
        wait for c_CLK_PER/2;
        clk <= '1';
        wait for c_CLK_PER/2;  
    end process;

----------------------------------------------------------------------------------
-- stimuli process, all control signals are set here, timing of input waves is
-- defined with one of "wait" statements (wait for, wait until, wait on)
p_stimuli : process
    begin
        -- 0. initial values of control signals
        stream <= '0';
        shift_en <= '0';
        rst <= '1'; -- reset the circuit for initialization
        wait for 2*c_CLK_PER;
        rst<='0';        
         
        wait until rising_edge(clk);
        
        -- 1st value set 11001
        shift_en <= '1';
        wait for c_CLK_PER;
        stream <= '1';
        wait for c_CLK_PER;
        stream <= '1';
        wait for c_CLK_PER;
        stream <= '0';
        wait for c_CLK_PER;
        stream <= '0';
        wait for c_CLK_PER;
        stream <= '1';
        wait for c_CLK_PER;
        shift_en <= '0';
        stream <= '0';
        
        -- wait
        wait for 2*c_CLK_PER;
        wait until rising_edge(clk);
        
        -- test shift en
        shift_en <= '1';
        wait for 8*c_CLK_PER;
        shift_en <= '0';
        wait until rising_edge(clk); 
        
        -- test reset
        rst <= '0';
        wait for 2*c_CLK_PER;
        
        
        wait;        
       
    end process;
end testbench;