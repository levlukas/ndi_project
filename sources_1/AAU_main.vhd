library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

-- MAIN ENTITY
entity aau is
    generic (
        data_width   : natural;
        max_chunk_no : natural
    );
    port (
        clk         : in  std_logic;
        CS_b        : in  std_logic;
        SCLK        : in  std_logic;
        MOSI        : in  std_logic;
        MISO        : out std_logic;
        data_fr1    : out STD_LOGIC_VECTOR(data_width - 1 downto 0); 
        data_fr2    : out STD_LOGIC_VECTOR(data_width - 1 downto 0); 
        add_res     : in  STD_LOGIC_VECTOR(data_width - 1 downto 0);
        mul_res     : in  STD_LOGIC_VECTOR(data_width - 1 downto 0);
        we_data_fr1 : out std_logic;
        we_data_fr2 : out std_logic
    );
end aau;

architecture Behavioral of aau is
    -- SIGNALS
    -- frame control
    signal fr_start, fr_end, fr_err : std_logic;

    -- mosi, miso control
    signal data_out, data_in : std_logic_vector(data_width - 1 downto 0);
    signal load_data : std_logic;
begin
    -- SPI IF
    spi_if : entity work.spi_if(Behavioral)
        generic map (
            data_width => data_width,
            max_chunk_no => max_chunk_no
        )
        port map (
            CS_b => CS_b,
            SCLK => SCLK,
            MOSI => MOSI,
            MISO => MISO,
            data_out => data_out,
            data_in  => data_in,
            load_data => load_data,
            clk => clk,
            fr_start => fr_start,
            fr_end   => fr_end,
            fr_err   => fr_err
        );

    -- PACKET CONTROL
    pkt_ctrl : entity work.pkt_ctrl(Behavioral)
        generic map (
            data_width => data_width
        )
        port map(
            clk         => clk,
            fr_start    => fr_start,
            fr_end      => fr_end,
            fr_err      => fr_err,
            data_out    => data_out,
            add_res     => add_res,
            mul_res     => mul_res,
            data_in     => data_in,
            wr_data     => load_data,
            data_fr1    => data_fr1,
            data_fr2    => data_fr2,
            we_data_fr1 => we_data_fr1,
            we_data_fr2 => we_data_fr2
        );
end Behavioral;


