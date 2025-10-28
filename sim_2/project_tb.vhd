library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity project_tb is
    -- entity is empty, testbench has no inputs nor outputs
end project_tb;

architecture testbench of project_tb is

----------SIGNALS---------
-- tb constants
constant c_CLK_PER    : time := 10 ns;
constant c_SCLK_PER   : time := 50 ns; 
constant data_width   : natural := 8;

-- TB control signals
signal run_clk_gen : std_logic; 

-- DUT input & output signals
signal CS_b : std_logic;
signal MOSI, MISO : std_logic;
signal data_in, data_out : std_logic_vector(data_width-1 downto 0);
signal load_data : std_logic;
signal clk, SCLK : std_logic;

---------DATA TYPES---------
-- SPI IF as records
type t_SPI_MOSI is record
    SCLK : std_logic;
    CS_b : std_logic;
    MOSI : std_logic;
end record;

type t_SPI_MISO is record
    MISO : std_logic;
end record;

---------FUNCTIONS & PROCEDURES---------
procedure wait_clk (n_clks : natural) is
begin
    for i in 1 to n_clks loop
        wait until rising_edge(clk);
    end loop;
end procedure wait_clk;

-- BFM SPI MASTER
procedure send_frame(constant data_in  : in  integer;
                     variable data_out : out integer;
                     
                     signal spi_mosi   : out t_SPI_MOSI;
                     signal spi_miso   : in  t_SPI_MISO) is
variable data2send, data_rcv : std_logic_vector(data_width-1 downto 0);
begin
    data2send := std_logic_vector(to_signed(data_in, data_width));
    spi_mosi.cs_b <= '0';
    for idx in 0 to data_width-1 loop
        wait for c_SCLK_per/2;
        spi_mosi.sclk <= '0';
        -- Master sets output signal on SCLK falling edge
        spi_mosi.mosi <= data2send(idx);
        wait for c_SCLK_per/2;
        spi_mosi.sclk <= '1';
        -- Master samples input data on SCLK rising edge
        data_rcv(idx) := spi_miso.miso;
    end loop;
    wait for c_SCLK_per/2;
    spi_mosi.cs_b <= '1';
    data_out := to_integer(signed(data_rcv));
end procedure;

-- TESTCASE
procedure tc_1 (signal spi_mosi : out t_SPI_MOSI;
                signal spi_miso : in  t_SPI_MISO) is
    variable fr_1, fr_2 : integer;  -- frame parsable variable
    begin
        -- send first packet and report (no calc. output expected)
        send_frame(1000, fr_1, spi_mosi, spi_miso);
        wait_clk(2);
        send_frame(10000, fr_2, spi_mosi, spi_miso);
        wait_clk(2);
        report "FR1 : " & integer'image(fr_1) & 
               "FR2 : " & integer'image(fr_2);

        -- send second packet and report (calc output from previous pkt)
        send_frame(0, fr_1, spi_mosi, spi_miso);
        wait for c_SCLK_per*2;
        send_frame(0, fr_2, spi_mosi, spi_miso);
        wait for c_SCLK_per*2;
        report "FR1 : " & integer'image(fr_1) & 
               "FR2 : " & integer'image(fr_2);

        -- TODO: enable this
        -- check for 1st pkt calc. output
        -- if fr_1 /= 11000 then
        --     report "chyba souctu" severity error;
        -- end if; 
    end procedure;

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
    -- test for clk gen by BFM
    p_clk_bfm : process
        begin
            if run_clk_gen = '1' then
                clk <= '0';
                wait for c_CLK_PER/2;
                clk <= '1';
                wait for c_CLK_PER/2;  
            else
                wait until run_clk_gen = '1';
            end if;
        end process;

    -- clock generator, process is running all the time - when end of process is reached,
    -- it is started again from the begining (effectively infinite loop)
    p_clk_gen : process 
        begin
            clk <= '0';
            wait for c_CLK_PER/2;
            clk <= '1';
            wait for c_CLK_PER/2;  
        end process;
    
    -- generator for the SCLK
    p_sclk_gen : process 
        begin
            SCLK <= '0';
            wait for c_SCLK_PER/2;
            SCLK <= '1';
            wait for c_SCLK_PER/2;
        end process;    
    
    -- main stimulus
    p_stimuli : process
        constant MOSI_data : std_logic_vector(data_width-1 downto 0) := "11101011";
        begin
            -- Initialization
            run_clk_gen <= '1';
            CS_b <= '1';
            MOSI <= '0';
            load_data <= '0';
            data_in <= "10011011";  -- data to be shifted out on MISO
            wait_clk(5);
    
            -- Load data into serializer before transfer
            load_data <= '1';
            wait_clk(5);
            load_data <= '0';
            wait until rising_edge(clk);
    
            -- Begin SPI transaction
            CS_b <= '0';
            wait_clk(5);
    
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
            wait_clk(5);

            -- terminate simulation
            run_clk_gen <= '1';
            wait;
        end process;
    
    
end testbench;