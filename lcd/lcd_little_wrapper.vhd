library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity lcd_little_wrapper is
    port (
    clk      : in  std_logic;  --system clock
    reset_n  : in  std_logic;  --active low reinitializes lcd
    rw       : out std_logic;  --read/write
    rs       : out std_logic;  --setup/data
    e        : out std_logic;  --enable for lcd
    lcd_data : out std_logic_vector(3 downto 0)--data signals for lcd
    );
end lcd_little_wrapper;

architecture behavioral of lcd_little_wrapper is

    component lcd_controller
    	port (
    		clk        : in  std_logic;
    		reset_n    : in  std_logic;
    		lcd_enable : in  std_logic;
    		lcd_bus    : in  std_logic_vector(9 downto 0);
    		busy       : out std_logic := '1';
    		e          : out std_logic;
    		rw         : out std_logic;
    		rs         : out std_logic;
    		lcd_data   : out std_logic_vector(3 downto 0));
    end component;

    type state_t is (idle_st, reset_st, write_st);
    type vector_array_t is array (0 to 15) of std_logic_vector(9 downto 0);

    signal lcd_enable    : std_logic;
    signal i_lcd_bus     : std_logic_vector(9 downto 0);
    signal i_busy        : std_logic;
    signal current_state : state_t := reset_st;
    signal my_word       : vector_array_t := ("1001001000",--h
                                              "1001000101",--e
                                              "1001001100",--l
                                              "1001001100",--l
                                              "1001001111",--o
                                              "1000100000",--
                                              "1001010111",--w
                                              "1001001111",--o
                                              "1001010010",--r
                                              "1001001100",--l
                                              "1001000100",--d
                                              "1000100000",--
                                              "1001000101",--e
                                              "1001010011",--s
                                              "1001000101",--e
                                              "1001001110");--n

begin

    lcd_controller_i : lcd_controller
    	port map (
    		clk        => clk,
    		reset_n    => reset_n,
    		lcd_enable => lcd_enable,
    		lcd_bus    => i_lcd_bus,
    		busy       => i_busy,
    		e          => e,
    		rw         => rw,
    		rs         => rs,
    		lcd_data   => lcd_data);


state_pro : process(current_state,clk,reset_n)
    variable clk_count : integer := 0;
    variable word_index : integer := 0;
begin

if(clk'event and clk = '1') then

    if( reset_n = '1') then
        current_state <= reset_st;
        word_index := 0;
        clk_count := 0;
    else

        case( current_state ) is

            when reset_st =>
                if( clk_count < 5000000 ) then -- 500 ms wait
                    clk_count := clk_count + 1;
                else
                    clk_count := 0;
                    current_state <= idle_st;
                end if;

            when idle_st =>
                if( i_busy = '0' and word_index < 16 )then
                    clk_count := 0;
                    current_state <= write_st;
                else
                    lcd_enable <= '0';
                    current_state <= idle_st;
                end if;

            when write_st =>
                if( clk_count < 2) then
                    i_lcd_bus <= my_word(word_index);
                    lcd_enable <= '1';
                    clk_count := clk_count + 1;
                    current_state <= write_st;
                else
                    lcd_enable <= '0';
                    word_index := word_index + 1;
                    clk_count := 0;
                    current_state <= idle_st;
                end if;

            when others =>
                current_state <= idle_st ;

        end case;

    end if;

end if;

end process;


end architecture;
