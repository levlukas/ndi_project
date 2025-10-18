library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pkt_ctrl_tb is
    -- entity is empty, testbench has no inputs nor outputs
end pkt_ctrl_tb;

architecture testbench of pkt_ctrl_tb is
    
    -- tb constants
    constant c_CLK_PER    : time := 10 ns;
    constant data_width   : natural := 8;
    
    -- DUT input signals
    signal clk          : std_logic := '0';
    signal fr_start     : std_logic := '0';
    signal fr_end       : std_logic := '0';
    signal fr_err       : std_logic := '0';
    signal data_out     : std_logic_vector(data_width - 1 downto 0) := (others => '0');
    signal add_res      : std_logic_vector(data_width - 1 downto 0) := X"AA";  -- Test value for sum
    signal mul_res      : std_logic_vector(data_width - 1 downto 0) := X"55";  -- Test value for product
    
    -- DUT output signals
    signal data_in      : std_logic_vector(data_width - 1 downto 0);
    signal wr_data      : std_logic;
    signal data_fr1     : std_logic_vector(data_width - 1 downto 0);
    signal data_fr2     : std_logic_vector(data_width - 1 downto 0);
    signal we_data_fr1  : std_logic;
    signal we_data_fr2  : std_logic;

    begin
        -- instance of DUT
        i_dut : entity work.pkt_ctrl(Behavioral)
            generic map (
                data_width => data_width,
                timeout_cycles => 100  -- timeout placeholder (not tested, but needs valid value)
            )    
            port map (
                clk => clk,
                fr_start => fr_start,
                fr_end => fr_end,
                fr_err => fr_err,
                data_out => data_out,
                add_res => add_res,
                mul_res => mul_res,
                data_in => data_in,
                wr_data => wr_data,
                data_fr1 => data_fr1,
                data_fr2 => data_fr2,
                we_data_fr1 => we_data_fr1,
                we_data_fr2 => we_data_fr2
            );

        -- clock generator
        p_clk_gen : process 
        begin
            clk <= '0';
            wait for c_CLK_PER/2;
            clk <= '1';
            wait for c_CLK_PER/2;  
        end process;

        -- Main stimulus process
        p_stim : process
            -- procedure for waiting x cycles
            procedure wait_cycles(signal clk : in std_logic; constant cycles : natural) is
                begin
                    for i in 1 to cycles loop
                        wait until rising_edge(clk);
                    end loop;
                end procedure;

            begin
                -- initial wait
                wait_cycles(clk, 5);

                ----------------------------
                -- TEST 1: first transaction
                ----------------------------
                -- Frame 1:
                data_out <= X"11";  -- MISO -> SPI IF (vector)
                wait_cycles(clk, 1);
                fr_start <= '1'; wait_cycles(clk, 1);
                fr_start <= '0'; wait_cycles(clk, 3);
                fr_end <= '1'; wait_cycles(clk, 1);
                fr_end <= '0'; wait_cycles(clk, 1);

                -- Frame 2:
                data_out <= X"22";  -- MISO -> SPI IF (vector)
                wait_cycles(clk, 1);
                fr_start <= '1'; wait_cycles(clk, 1);
                fr_start <= '0'; wait_cycles(clk, 3);
                fr_end <= '1'; wait_cycles(clk, 1);
                fr_end <= '0'; wait_cycles(clk, 1);


                -----------------------------
                -- TEST 2: second transaction
                -----------------------------
                -- example data computed by AU from the 1st trans.
                add_res <= X"AA";
                mul_res <= X"55";

                -- Frame 1:
                data_out <= X"33";  -- MISO -> SPI IF (vector)
                wait_cycles(clk, 1);
                fr_start <= '1'; wait_cycles(clk, 1);
                fr_start <= '0'; wait_cycles(clk, 3);
                fr_end <= '1'; wait_cycles(clk, 1);
                fr_end <= '0'; wait_cycles(clk, 1);

                -- Frame 2:
                data_out <= X"44";  -- MISO -> SPI IF (vector)
                wait_cycles(clk, 1);
                fr_start <= '1'; wait_cycles(clk, 1);
                fr_start <= '0'; wait_cycles(clk, 3);
                fr_end <= '1'; wait_cycles(clk, 1);
                fr_end <= '0'; wait_cycles(clk, 1);

                ----------------------------
                -- TEST 3: third transaction
                ----------------------------
                -- example data computed by AU from the 1st trans.
                add_res <= X"BB";
                mul_res <= X"66";

                -- Frame 1:
                data_out <= X"55";  -- MISO -> SPI IF (vector)
                wait_cycles(clk, 1);
                fr_start <= '1'; wait_cycles(clk, 1);
                fr_start <= '0'; wait_cycles(clk, 3);
                fr_end <= '1'; wait_cycles(clk, 1);
                fr_end <= '0'; wait_cycles(clk, 1);

                -- Frame 2:
                data_out <= X"66";  -- MISO -> SPI IF (vector)
                wait_cycles(clk, 1);
                fr_start <= '1'; wait_cycles(clk, 1);
                fr_start <= '0'; wait_cycles(clk, 3);
                fr_end <= '1'; wait_cycles(clk, 1);
                fr_end <= '0'; wait_cycles(clk, 1);

                -----------------------------
                -- TEST 4: fourth transaction
                -----------------------------
                -- example data computed by AU from the 1st trans.
                add_res <= X"CC";
                mul_res <= X"77";

                -- Frame 1 with error
                data_out <= X"77";
                fr_start <= '1'; wait for c_CLK_PER;
                fr_start <= '0'; wait for 2 * c_CLK_PER;
                fr_err <= '1'; wait for c_CLK_PER;  -- Error!
                fr_err <= '0'; wait for 3 * c_CLK_PER;
                
                -- Retry frame 1 (successful)
                data_out <= X"88";
                fr_start <= '1'; wait for c_CLK_PER;
                fr_start <= '0'; wait for 3 * c_CLK_PER;
                fr_end <= '1'; wait for c_CLK_PER;
                fr_end <= '0'; wait for 2 * c_CLK_PER;
                
                -- Frame 2
                data_out <= X"99";
                fr_start <= '1'; wait for c_CLK_PER;
                fr_start <= '0'; wait for 3 * c_CLK_PER;
                fr_end <= '1'; wait for c_CLK_PER;
                fr_end <= '0'; wait for 5 * c_CLK_PER;
                
                wait;
            end process;

    end testbench;