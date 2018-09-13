library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity spi_ams is
    Port (
    CLK  : in  std_logic;
    LADC : out std_logic;
    SYNC : out std_logic;
    SCLK : out std_logic;
    DIN  : out std_logic
   -- out_test : out std_logic_vector(15 downto 0)
    );
end spi_ams;

architecture Behavioral of spi_ams is

    type state_t is (initialize, send_pack32, iterate_wave);
    type vector_array_t is array(0 to 359) of std_logic_vector(15 downto 0);

    signal state : state_t := initialize;
    signal package32 : std_logic_vector(31 downto 0);
    constant wave_array :  vector_array_t  :=  ( "0011001100110011",
    "0011010000011000",
    "0011010011111100",
    "0011010111100001",
    "0011011011000101",
    "0011011110101001",
    "0011100010001101",
    "0011100101110000",
    "0011101001010011",
    "0011101100110101",
    "0011110000010111",
    "0011110011111000",
    "0011110111011000",
    "0011111010110111",
    "0011111110010110",
    "0100000001110011",
    "0100000101010000",
    "0100001000101011",
    "0100001100000101",
    "0100001111011110",
    "0100010010110110",
    "0100010110001100",
    "0100011001100001",
    "0100011100110100",
    "0100100000000110",
    "0100100011010110",
    "0100100110100101",
    "0100101001110001",
    "0100101100111100",
    "0100110000000101",
    "0100110011001100",
    "0100110110010010",
    "0100111001010101",
    "0100111100010110",
    "0100111111010100",
    "0101000010010001",
    "0101000101001011",
    "0101001000000011",
    "0101001010111000",
    "0101001101101100",
    "0101010000011100",
    "0101010011001010",
    "0101010101110101",
    "0101011000011110",
    "0101011011000100",
    "0101011101100111",
    "0101100000000111",
    "0101100010100101",
    "0101100100111111",
    "0101100111010111",
    "0101101001101100",
    "0101101011111101",
    "0101101110001011",
    "0101110000010111",
    "0101110010011111",
    "0101110100100100",
    "0101110110100101",
    "0101111000100011",
    "0101111010011110",
    "0101111100010110",
    "0101111110001010",
    "0101111111111011",
    "0110000001101000",
    "0110000011010001",
    "0110000100110111",
    "0110000110011010",
    "0110000111111001",
    "0110001001010100",
    "0110001010101100",
    "0110001011111111",
    "0110001101010000",
    "0110001110011100",
    "0110001111100100",
    "0110010000101001",
    "0110010001101010",
    "0110010010100111",
    "0110010011100001",
    "0110010100010110",
    "0110010101001000",
    "0110010101110101",
    "0110010110011111",
    "0110010111000101",
    "0110010111100110",
    "0110011000000100",
    "0110011000011110",
    "0110011000110100",
    "0110011001000110",
    "0110011001010100",
    "0110011001011110",
    "0110011001100100",
    "0110011001100110",
    "0110011001100100",
    "0110011001011110",
    "0110011001010100",
    "0110011001000110",
    "0110011000110100",
    "0110011000011110",
    "0110011000000100",
    "0110010111100110",
    "0110010111000101",
    "0110010110011111",
    "0110010101110101",
    "0110010101001000",
    "0110010100010110",
    "0110010011100001",
    "0110010010100111",
    "0110010001101010",
    "0110010000101001",
    "0110001111100100",
    "0110001110011100",
    "0110001101010000",
    "0110001011111111",
    "0110001010101100",
    "0110001001010100",
    "0110000111111001",
    "0110000110011010",
    "0110000100110111",
    "0110000011010001",
    "0110000001101000",
    "0101111111111011",
    "0101111110001010",
    "0101111100010110",
    "0101111010011110",
    "0101111000100011",
    "0101110110100101",
    "0101110100100100",
    "0101110010011111",
    "0101110000010111",
    "0101101110001011",
    "0101101011111101",
    "0101101001101100",
    "0101100111010111",
    "0101100100111111",
    "0101100010100101",
    "0101100000000111",
    "0101011101100111",
    "0101011011000100",
    "0101011000011110",
    "0101010101110101",
    "0101010011001010",
    "0101010000011100",
    "0101001101101100",
    "0101001010111000",
    "0101001000000011",
    "0101000101001011",
    "0101000010010001",
    "0100111111010100",
    "0100111100010110",
    "0100111001010101",
    "0100110110010010",
    "0100110011001101",
    "0100110000000101",
    "0100101100111100",
    "0100101001110001",
    "0100100110100101",
    "0100100011010110",
    "0100100000000110",
    "0100011100110100",
    "0100011001100001",
    "0100010110001100",
    "0100010010110110",
    "0100001111011110",
    "0100001100000101",
    "0100001000101011",
    "0100000101010000",
    "0100000001110011",
    "0011111110010110",
    "0011111010110111",
    "0011110111011000",
    "0011110011111000",
    "0011110000010111",
    "0011101100110101",
    "0011101001010011",
    "0011100101110000",
    "0011100010001101",
    "0011011110101001",
    "0011011011000101",
    "0011010111100001",
    "0011010011111100",
    "0011010000011000",
    "0011001100110011",
    "0011001001001110",
    "0011000101101010",
    "0011000010000101",
    "0010111110100001",
    "0010111010111101",
    "0010110111011001",
    "0010110011110110",
    "0010110000010011",
    "0010101100110001",
    "0010101001001111",
    "0010100101101110",
    "0010100010001110",
    "0010011110101111",
    "0010011011010000",
    "0010010111110011",
    "0010010100010110",
    "0010010000111011",
    "0010001101100001",
    "0010001010001000",
    "0010000110110000",
    "0010000011011010",
    "0010000000000101",
    "0001111100110010",
    "0001111001100000",
    "0001110110010000",
    "0001110011000001",
    "0001101111110101",
    "0001101100101010",
    "0001101001100001",
    "0001100110011010",
    "0001100011010100",
    "0001100000010001",
    "0001011101010000",
    "0001011010010010",
    "0001010111010101",
    "0001010100011011",
    "0001010001100011",
    "0001001110101110",
    "0001001011111010",
    "0001001001001010",
    "0001000110011100",
    "0001000011110001",
    "0001000001001000",
    "0000111110100010",
    "0000111011111111",
    "0000111001011111",
    "0000110111000001",
    "0000110100100111",
    "0000110010001111",
    "0000101111111010",
    "0000101101101001",
    "0000101011011011",
    "0000101001001111",
    "0000100111000111",
    "0000100101000010",
    "0000100011000001",
    "0000100001000011",
    "0000011111001000",
    "0000011101010000",
    "0000011011011100",
    "0000011001101011",
    "0000010111111110",
    "0000010110010101",
    "0000010100101111",
    "0000010011001100",
    "0000010001101101",
    "0000010000010010",
    "0000001110111010",
    "0000001101100111",
    "0000001100010110",
    "0000001011001010",
    "0000001010000010",
    "0000001000111101",
    "0000000111111100",
    "0000000110111111",
    "0000000110000101",
    "0000000101010000",
    "0000000100011110",
    "0000000011110001",
    "0000000011000111",
    "0000000010100001",
    "0000000010000000",
    "0000000001100010",
    "0000000001001000",
    "0000000000110010",
    "0000000000100000",
    "0000000000010010",
    "0000000000001000",
    "0000000000000010",
    "0000000000000000",
    "0000000000000010",
    "0000000000001000",
    "0000000000010010",
    "0000000000100000",
    "0000000000110010",
    "0000000001001000",
    "0000000001100010",
    "0000000010000000",
    "0000000010100001",
    "0000000011000111",
    "0000000011110001",
    "0000000100011110",
    "0000000101010000",
    "0000000110000101",
    "0000000110111111",
    "0000000111111100",
    "0000001000111101",
    "0000001010000010",
    "0000001011001010",
    "0000001100010110",
    "0000001101100111",
    "0000001110111010",
    "0000010000010010",
    "0000010001101101",
    "0000010011001100",
    "0000010100101111",
    "0000010110010101",
    "0000010111111110",
    "0000011001101011",
    "0000011011011100",
    "0000011101010000",
    "0000011111001000",
    "0000100001000011",
    "0000100011000001",
    "0000100101000010",
    "0000100111000111",
    "0000101001001111",
    "0000101011011011",
    "0000101101101001",
    "0000101111111010",
    "0000110010001111",
    "0000110100100111",
    "0000110111000001",
    "0000111001011111",
    "0000111011111111",
    "0000111110100010",
    "0001000001001000",
    "0001000011110001",
    "0001000110011100",
    "0001001001001010",
    "0001001011111010",
    "0001001110101110",
    "0001010001100011",
    "0001010100011011",
    "0001010111010101",
    "0001011010010010",
    "0001011101010000",
    "0001100000010001",
    "0001100011010100",
    "0001100110011001",
    "0001101001100001",
    "0001101100101010",
    "0001101111110101",
    "0001110011000001",
    "0001110110010000",
    "0001111001100000",
    "0001111100110010",
    "0010000000000101",
    "0010000011011010",
    "0010000110110000",
    "0010001010001000",
    "0010001101100001",
    "0010010000111011",
    "0010010100010110",
    "0010010111110011",
    "0010011011010000",
    "0010011110101111",
    "0010100010001110",
    "0010100101101110",
    "0010101001001111",
    "0010101100110001",
    "0010110000010011",
    "0010110011110110",
    "0010110111011001",
    "0010111010111101",
    "0010111110100001",
    "0011000010000101",
    "0011000101101010",
    "0011001001001110"
);

    constant command : std_logic_vector(3 downto 0) := "0010";
    constant ch_addr : std_logic_vector(3 downto 0) := "0011";
    constant period  : integer := 200; --nanoseconds

begin

    SCLK <= CLK;
    LADC <= '0';

    FSM : process(state,CLK)
        variable clk_counter : integer range 0 to 100000/period := 0;
        variable array_index : integer range 0 to 511 := 0;
        variable freq_coef   : integer range 0 to 15 := 1;
    begin

        if ( CLK'event AND CLK = '1' ) then

            case(state) is

                when initialize =>
                    SYNC      <='1';
                    clk_counter := 0;
                    array_index := 0;
                    freq_coef   := 1;
                    state <= iterate_wave;

                when iterate_wave =>

                    if (clk_counter < 100000/period) then --Wait for 2us
                        state <= iterate_wave;
                        clk_counter := clk_counter + 1;
                    else
                        if(array_index > 359) then
                            array_index := array_index-360;
                            --package32 <= "0000" & command & ch_addr & wave_array(array_index) & "0000";
                        --else
                        --    array_index := array_index;
                        end if;
                            package32 <= "0000" & command & ch_addr & wave_array(array_index) & "0000";
                        --out_test <= wave_array(array_index); --test
                        array_index := array_index + freq_coef;
                        state <= send_pack32;
                        clk_counter := 0;
                    end if;


                when send_pack32 =>
                    if ( clk_counter < 32 ) then
                        SYNC <= '0';
                        DIN    <= package32(31-clk_counter);
                        state  <= send_pack32;
                        clk_counter := clk_counter + 1;
                    else
                        SYNC <= '1';
                        DIN    <= '0';
                        state  <= iterate_wave;
                        clk_counter := 0;
                    end if;


                when others =>

            end case;

        end if;


    end process;


end Behavioral;
