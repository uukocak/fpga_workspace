library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  entity tb_lcd is
  end  tb_lcd;

architecture tb of tb_lcd is

  component lcd_controller
  port (
    clk        : in  std_logic;
    reset_n    : in  std_logic;
    lcd_enable : in  std_logic;
    lcd_bus    : in  std_logic_vector(9 downto 0);
    busy       : out std_logic := '1';
    e          : out std_logic;
    lcd_data   : out std_logic_vector(3 downto 0)
  );
  end component lcd_controller;

  signal clk        : std_logic;
  signal reset_n    : std_logic;
  signal lcd_enable : std_logic;
  signal lcd_bus    : std_logic_vector(9 downto 0);
  signal busy       : std_logic := '1';
  signal e          : std_logic;
  signal lcd_data   : std_logic_vector(3 downto 0);--data signals for lcd;

  constant clk_period : time := 20 ns;
  signal ENDSIM : std_logic := '0';


begin

  lcd_controller_i : lcd_controller
  port map (
    clk        => clk,
    reset_n    => reset_n,
    lcd_enable => lcd_enable,
    lcd_bus    => lcd_bus,
    busy       => busy,
    e          => e,
    lcd_data   => lcd_data
  );


  clock : process
  begin
    clk <= '1';
    wait for clk_period/2;
    clk <= '0';
    wait for clk_period/2;
    if(ENDSIM = '1') then
      wait;
    end if;
  end process;

stimululululululululu : process
begin
  reset_n <= '1';
  wait for clk_period ;
  reset_n <= '0';
  wait until busy = '0';
  lcd_bus <= "1100101101";
  lcd_enable <= '1';
  wait for 2 * clk_period;
  lcd_enable <= '0';
  wait until busy = '0';
  lcd_bus <= "1111101111";
  lcd_enable <= '1';
  wait for 2 * clk_period;
  lcd_enable <= '0';
  wait for  4000 * clk_period;
  ENDSIM <= '1';
  wait;

end process;

end architecture;
