library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arith_unit is
    generic (
        data_width : natural := 16
    );
    port (
        clk         : in  std_logic;
        data_fr1    : in  std_logic_vector(data_width-1 downto 0);
        we_data_fr1 : in  std_logic;
        data_fr2    : in  std_logic_vector(data_width-1 downto 0);
        we_data_fr2 : in  std_logic;
        add_res     : out std_logic_vector(data_width-1 downto 0);
        mul_res     : out std_logic_vector(data_width-1 downto 0)
    );
end arith_unit;

architecture Behavioral of arith_unit is
    -- signals to perform numeric_std operations
    -- these signals store the values of std_logic inputs
    signal a_sgn, b_sgn : signed (data_width-1 downto 0);
    signal s_aux        : signed (data_width downto 0);
    signal m_aux        : signed (data_width*2-1 downto 0);

    -- constants for saturation (default for 16 b)
    constant POS_SAT : signed (data_width-1 downto 0) := to_signed(32767, data_width-1);
    constant NEG_SAT : signed (data_width-1 downto 0) := to_signed(-32768, data_width-1);
begin
    -- SEQUENTIAL PART
    -- input operands processing with FF
    operands_ff : process (clk, we_data_fr1, we_data_fr2)
        begin
            if rising_edge(clk) then
                if we_data_fr1 = '1' then
                    a_sgn <= to_signed(data_fr1);
                end if;
                if we_data_fr2 = '1' then
                    b_sgn <= to_signed(data_fr2);
                end if;
            end if;
        end process;

    out_results : process (clk)
        begin
            if rising_edge(clk) then
                -- sum overflow and processing
                if s_aux > POS_SAT then
                    add_res <= std_logic_vector(POS_SAT);
                elsif s_aux < NEG_SAT then
                    add_res <= std_logic_vector(NEG_SAT);        
                else 
                    add_res <= std_logic_vector(resize(m_aux,data_width));
                end if;

                -- product overflow and processing
                -- TODO: implement this
                mul_res <= std_logic_vector(m_res);
            end if;
        end process;

    -- COMBINATIONAL PART
    -- arithmetic operations
    s_aux <= a_sgn + b_sgn;
    m_aux <= a_sgn * b_sgn;

end Behavioral;