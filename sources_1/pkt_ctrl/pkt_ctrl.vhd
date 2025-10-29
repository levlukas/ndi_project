-- TODO:
--   1. REQ_AAU_I_023 - TIMER
--   2. REQ_AAU_G_005 - SAFE IMPLEMENTATION

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;  

entity pkt_ctrl is
    Generic (
        data_width : natural;
        -- TODO: add correct clock handling (see requirements)
        timeout_cycles : natural := 10000000  -- 100 ms with 100Mhz clock
    );
    Port ( clk : in std_logic;
           fr_start : in STD_LOGIC;  -- SPI IF: `fr_start`
           fr_end : in STD_LOGIC;    -- SPI IF: `fr_end`
           fr_err : in STD_LOGIC;    -- SPI IF: `fr_err`
           data_out : in STD_LOGIC_VECTOR(data_width - 1 downto 0);  -- SPI IF: `data_out`
           add_res : in STD_LOGIC_VECTOR(data_width - 1 downto 0);   -- AU
           mul_res : in STD_LOGIC_VECTOR(data_width - 1 downto 0);   -- AU
           data_in : out STD_LOGIC_VECTOR(data_width - 1 downto 0);  -- SPI IF: `data_in`
           wr_data : out STD_LOGIC;       -- SPI IF: `load_data`
           data_fr1 : out STD_LOGIC_VECTOR(data_width - 1 downto 0); -- AU
           data_fr2 : out STD_LOGIC_VECTOR(data_width - 1 downto 0); -- AU
           we_data_fr1 : out STD_LOGIC;   -- AU
           we_data_fr2 : out STD_LOGIC);  -- AU
end pkt_ctrl;

architecture Behavioral of pkt_ctrl is
    
    -- FSM and states definitions
    type state_type is (s0_wait1, s1_receiv1, s2_wait2, s3_receiv2);
    signal next_state, present_state : state_type;
    
    -- Signal declaration
    -- flag to indicate if AU has valid results (after first complete transaction)
    signal first_cycle_complete : std_logic := '0';
    
begin
    -- SEQUENTIAL PART
    -- state update
    process (clk)
        begin
            if rising_edge(clk) then
                present_state <= next_state;
            end if;
        end process;
        
    -- TODO: nadbytecne, jestli je prijat sum nebo mul urcuje stav automatu
    -- process (clk) 
    --     begin
    --         if rising_edge(clk) then
    --             if present_state = s3_receiv2 and fr_end = '1' and fr_err = '0' then
    --                 -- First stransaction done, sum retrieved
    --                 first_cycle_complete <= '1';
    --             elsif (present_state = s1_receiv1 or present_state = s3_receiv2) and fr_err = '1' then
    --                 -- Error resets the state
    --                 first_cycle_complete <= '0';
    --             end if;
    --         end if;
    --     end process;

    -- COMBINATIONAL PART
    -- the logic behind state changing for each state
    process (present_state, fr_start, fr_end, fr_err, add_res, mul_res)
        begin
            -- "Default" option
            -- if no "special event", then stay at current state
            next_state <= present_state;
            wr_data <= '0';  -- set default to avoid latch
            we_data_fr1 <= '0';  -- set default to avoid latch
            we_data_fr2 <= '0';  -- set default to avoid latch
            
            -- Switch from s0 to s1
            -- if fr_start
            case present_state is 
                when s0_wait1 =>
                    -- waiting for first frame
                    we_data_fr1 <= '0';
                    we_data_fr2 <= '0';
                    wr_data <= '1';
                    data_in <= add_res;  -- previous au result
                    
                    if fr_start = '1' then
                        next_state <= s1_receiv1;
                    end if;
                    
                when s1_receiv1 =>
                    -- receiving first packet in both streams
                    we_data_fr1 <= '1';
                    we_data_fr2 <= '0';
                    wr_data <= '0';

                    if fr_err = '1' then
                        next_state <= s0_wait1;
                    elsif fr_end = '1' then
                        next_state <= s2_wait2;
                    end if;
                    
                when s2_wait2 =>
                    -- wait for both sterams to get data
                    -- the data from AU are expected to contain multiplication
                    we_data_fr1 <= '0';
                    we_data_fr2 <= '0';
                    wr_data <= '1';
                    data_in <= mul_res;
                    
                    if fr_start = '1' then
                        next_state <= s3_receiv2;
                    end if;
                    -- TODO: add timeout logic here (RQE_AAU_I_023)

                when s3_receiv2 =>
                    -- receiving data in both streams
                    -- the data from AU should now contain multiplication
                    we_data_fr1 <= '0';
                    we_data_fr2 <= '1';
                    wr_data <= '0'; 

                    if fr_err = '1' then
                        next_state <= s2_wait2;
                    elsif fr_end = '1' then
                        next_state <= s0_wait1;
                    end if;
                     
            end case;
                
        end process;
        
        -- Handling of the `data_out` signal
        data_fr1 <= data_out;
        data_fr2 <= data_out;

end Behavioral;
