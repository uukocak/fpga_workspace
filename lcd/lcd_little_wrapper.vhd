library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity lcd_little_wrapper is
  port (
  clk        : in    std_logic;  --system clock
  reset_n    : in    std_logic;  --active low reinitializes lcd
  rw, rs, e  : out   std_logic;  --read/write, setup/data, and enable for lcd
  lcd_data   : out   std_logic_vector(3 downto 0)--data signals for lcd
  );
end lcd_little_wrapper;

architecture behavioral of lcd_little_wrapper is

  component lcd_controller
  port (
    clk        : in  std_logic;
    reset_n    : in  std_logic;
    lcd_enable : in  std_logic;
    lcd_bus    : in  std_logic_vector(9 downto 0);
    busy       : out std_logic;
    e          : out std_logic;
    lcd_data   : out std_logic_vector(3 downto 0)
  );
  end component lcd_controller;


  type state_t is (idle_st, reset_st, write_st);

  signal lcd_enable    : std_logic;
  signal lcd_bus       : std_logic_vector(9 downto 0);
  signal busy          : std_logic;
  signal current_state : state_t;

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

state_pro : process(sensitivity_list)
begin


end process;


end architecture;
