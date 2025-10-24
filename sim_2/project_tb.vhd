library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity project_tb is
    -- entity is empty, testbench has no inputs nor outputs
end project_tb;

architecture testbench of project_tb is

----------------------------------------------------------------------------------
-- tb constants
constant c_CLK_PER    : time := 10 ns;
constant c_SCLK_PER   : time := 50 ns; 
constant data_width   : natural := 8;


-- DUT input & output signals
signal CS_b : std_logic;
signal MOSI, MISO : std_logic;
signal data_in, data_out : std_logic_vector(data_width-1 downto 0);
signal load_data : std_logic;
signal clk, SCLK : std_logic;


begin
    ----------------------------------------------------------------------------------
    -- instance of component
    i_dut : entity work.spi_if(Behavioral)
        generic map (
            data_width => data_width,
            max_chunk_no => 16
        )    
        port map (
            clk => clk,
            MOSI => MOSI,
            MISO => MISO,
            SCLK => SCLK,
            CS_b => CS_b,
            data_out => data_out,
            data_in => data_in,
            load_data => load_data
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
    
    p_sclk_gen : process 
        begin
            SCLK <= '0';
            wait for c_SCLK_PER/2;
            SCLK <= '1';
            wait for c_SCLK_PER/2;
        end process;    
    
    p_stimuli : process
        constant MOSI_data : std_logic_vector(data_width-1 downto 0) := "11101011";
        begin
            -- Initialization
            CS_b <= '1';
            MOSI <= '0';
            load_data <= '0';
            data_in <= "10011011";  -- data to be shifted out on MISO
            for i in 0 to 5 loop  -- wait for 5 initial clk
                wait until rising_edge(clk);
            end loop;    
    
            -- Load data into serializer before transfer
            load_data <= '1';
            for i in 0 to 10 loop -- wait while data is loop
                wait until rising_edge(clk);
            end loop;
            load_data <= '0';
            wait until rising_edge(clk);
    
            -- Begin SPI transaction
            CS_b <= '0';
            for i in 0 to 5 loop
                wait until rising_edge(clk);
            end loop;
    
            -- send MOSI data and wait appropriate time
            for i in 0 to data_width-1 loop
                MOSI <= MOSI_data(i);
                wait until rising_edge(SCLK);
            end loop;
            MOSI <= '0';
            
            for i in 0 to data_width-1 loop
                wait until rising_edge(SCLK);
            end loop;
    
            -- End frame
            CS_b <= '1';
            for i in 0 to 5 loop
                wait until rising_edge(clk);
            end loop;
            wait;
        end process;
    
    
end testbench;