library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

-- Main Entity
entity spi_if is
    Generic (
        data_width   : natural;
        max_chunk_no : natural
    );
    Port ( CS_b : in STD_LOGIC;
           SCLK : in STD_LOGIC;
           MOSI : in STD_LOGIC;
           MISO : out STD_LOGIC;
           data_out : out STD_LOGIC_VECTOR (data_width-1 downto 0);
           data_in : in STD_LOGIC_VECTOR (data_width-1 downto 0);
           load_data : in STD_LOGIC;
           clk : in std_logic;
           -- frame detection and check
           fr_start : out std_logic;
           fr_end   : out std_logic;
           fr_err   : out std_logic
           );
end spi_if;

architecture Behavioral of spi_if is

    -- Signal Declaration
    
    -- ser and deser signals
    signal stream, rst, shift_in_en, shift_out_en : STD_LOGIC;
    
    -- synchronizer signals for clk and SCLK, csb issues
    signal sclk_sync1, sclk_sync2 : std_logic;
    signal csb_sync1,  csb_sync2  : std_logic;
        
    -- edge detectors
    signal fe_det_csb_out : std_logic;
    signal fe_det_sclk_out : std_logic;
    signal re_det_csb_out : std_logic;
    signal re_det_sclk_out : std_logic;
    
    -- frame detection and check
    signal chunk_no : std_logic_vector(data_width-1 downto 0);  -- overshot length

begin

     -- Instances of Used Modules
     -- serialiser
     ser : entity work.serialiser(Behavioral)
        generic map (
            data_width => data_width
        )    
        port map (
            clk => clk,
            load_en => load_data,
            shift_en => shift_out_en,
            rst => rst,
            data => data_in,
            stream => MISO
        );
        
     -- deserialiser
     deser : entity work.deserialiser(Behavioral)
        generic map (
            data_width => data_width
        )    
        port map (
            clk => clk,
            shift_en => shift_in_en,
            rst => rst,
            data => data_out,
            stream => MOSI
        );
        
     -- FE det, CS_b
     fe_det_csb : entity work.falling_edge_detector(Behavioral)
        port map (
            sig_in => csb_sync2,
            clk => clk,
            sig_out => fe_det_csb_out
        );
     
     -- RE det, CS_b
     re_det_csb : entity work.rising_edge_detector(Behavioral)
        port map (
            sig_in => csb_sync2,
            clk => clk,
            sig_out => re_det_csb_out
        );
        
     -- FE det, SCLK
     fe_det_sclk : entity work.falling_edge_detector(Behavioral)
        port map (
            sig_in => sclk_sync2,
            clk => clk,
            sig_out => fe_det_sclk_out
        );   
    
     -- RE det, SCLK
     re_det_sclk : entity work.rising_edge_detector(Behavioral)
        port map (
            sig_in => sclk_sync2,
            clk => clk,
            sig_out => re_det_sclk_out
        );
        
        
     -- Combinational logic
     
     -- synchronization of asynchronous inputs (SCLK and CS_b)
     -- two signals for the case when SCLK changes close to clk
     sync : process(clk)
        begin
            if rising_edge(clk) then
                -- SCLK synchronization
                sclk_sync1 <= SCLK;
                sclk_sync2 <= sclk_sync1;
                
                -- CS_B synchronization
                csb_sync1 <= CS_b;
                csb_sync2 <= csb_sync1;
            end if;
        end process;
         
     -- MOSI/MISO logic
     -- - data slave_out (MISO) posila pri sestupne hrane SCLK,
     --   protoze pri nastupne hrane SCLK tato data master
     --   bude samplovat
     -- - data slave sampluje (MOSI) pri nastupne hrane SCLK,
     --   protoze pri sestupne hrane SCLK tato data master
     --   bude posilat
     mosi_miso : process (CS_b, re_det_sclk_out, fe_det_sclk_out)
        begin
            if CS_b = '0' then  -- conduct the communication only when CS_b is low
                if re_det_sclk_out = '1' then  -- if "rising_edge(SCLK)"
                    -- enable deser (which samples MOSI, outputs data_out)
                    shift_in_en <= '1';  
                else
                    shift_in_en <= '0';
                end if;
            
                if fe_det_sclk_out = '1' then  -- if "falling_edge(SCLK)"
                    -- enable ser (which samples data_in when load_data and outputs MISO)
                    shift_out_en <= '1';  
                else
                    shift_out_en <= '0';
                end if;
            end if;
        end process;
        
     -- Frame Detection and Check
     -- "REQ_AAU_I_022: "frame with wrong no of bits will be ignored"
     chunk_counter : process (CS_b, re_det_sclk_out)
        -- - Je potreba pomocí fr_err kontrolovat jen data z masteru,
        --   protoze data ze slavu jsou vytvarena v jinem bloku.
        --   Neni potreba jejich spravnost overit. Self-checking je velmi drahy
        begin
            if CS_b = '0' then
                if re_det_sclk_out = '1' then  -- only at rising edge, when MOSI is sampled
                    chunk_no <= std_logic_vector(unsigned(chunk_no) + 1);
                end if;
            else
                chunk_no <= (others => '0');
            end if;
        end process;
     frame_det : process (fe_det_csb_out, re_det_csb_out, chunk_no)
        begin
            -- start of frame detection
            if fe_det_csb_out = '1' then  
                fr_start <= '1';
            else
                fr_start <= '0';
            end if;
            -- end of frame detection
            if re_det_csb_out = '1' then  
                fr_end <= '1';
            else
                fr_end <= '0';
            end if;
            -- error frame detection
            if unsigned(chunk_no) > max_chunk_no then
                fr_err <= '1';
            else
                fr_err <= '0';
            end if;
        end process;
                
end Behavioral;
