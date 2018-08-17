library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_uart_tx is
end entity;

architecture tb of tb_uart_tx is

  component uart_tx_module
  generic (
    baud_rate : integer := 9600;
    clk_freq  : integer := 1
  );
  port (
    tx_byte     : in  std_logic_vector(7 downto 0);
    tx_start    : in  std_logic;
    clk         : in  std_logic;
    chip_enable : in  std_logic;
    tx_line     : out std_logic;
    tx_done     : out std_logic
  );

  end component uart_tx_module;

  component uart_rx_module
  generic (
    baud_rate : integer := 9600;
    clk_freq  : integer := 100
  );
  port (
    clk         : in  std_logic;
    chip_enable : in  std_logic;
    rx_line     : in  std_logic;
    rx_byte     : out std_logic_vector(7 downto 0);
    rx_done     : out std_logic
  );
  end component uart_rx_module;


  signal tx_byte     : std_logic_vector(7 downto 0);
  signal tx_start    : std_logic;
  signal clk         : std_logic;
  signal chip_enable : std_logic;
  signal tx_line     : std_logic;
  signal tx_done     : std_logic;

  signal rx_line     : std_logic;
  signal rx_byte     : std_logic_vector(7 downto 0);
  signal rx_done     : std_logic;

  constant clk_period : time := 10 ns;

begin

  rx_line <= tx_line;

  uart_tx_module_i : uart_tx_module
  generic map (
    baud_rate => 9600,
    clk_freq  => 1
  )
  port map (
    tx_byte     => tx_byte,
    tx_start    => tx_start,
    clk         => clk,
    chip_enable => chip_enable,
    tx_line     => tx_line,
    tx_done     => tx_done
  );

  uart_rx_module_i : uart_rx_module
  generic map (
    baud_rate => 9600,
    clk_freq  => 1
  )
  port map (
    clk         => clk,
    chip_enable => chip_enable,
    rx_line     => rx_line,
    rx_byte     => rx_byte,
    rx_done     => rx_done
  );


  clock : process
  begin
    clk <= '1';
    wait for clk_period/2;
    clk <= '0';
    wait for clk_period/2;
  end process;


  stimulu : process
  begin
    tx_byte <= "00100101";
    wait for clk_period;
    chip_enable <= '1';
    wait for clk_period;
    tx_start <= '1';
    wait for clk_period;
    tx_start<='0';
    tx_byte <= "01110101";
    wait until tx_done = '1';
    wait for clk_period;
    wait for clk_period;
    tx_start <= '1';

    wait;

  end process;



end architecture;
