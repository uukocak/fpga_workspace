library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity tb_wrapper is
end tb_wrapper ;

architecture tb of tb_wrapper is

  component lcd_little_wrapper
      port (
      clk      : in  std_logic;
      reset_n  : in  std_logic;
      rw       : out std_logic;
      rs       : out std_logic;
      e        : out std_logic;
      lcd_data : out std_logic_vector(3 downto 0)
      );
  end component;

  signal clk: std_logic;
  signal reset_n: std_logic;
  signal rw: std_logic;
  signal rs: std_logic;
  signal e: std_logic;
  signal lcd_data: std_logic_vector(3 downto 0) ;

  constant clock_period: time := 100 ns;
  signal stop_the_clock: boolean;

begin

  uut: lcd_little_wrapper port map ( clk      => clk,
                                     reset_n  => reset_n,
                                     rw       => rw,
                                     rs       => rs,
                                     e        => e,
                                     lcd_data => lcd_data );

  stimulus: process
  begin
    reset_n <= '0';
    -- Put initialisation code here
    wait for 1000 ms ;
    reset_n <= '1';
    wait for 100 ms ;
    reset_n <= '0';
    wait for 900 ms ;
    
    -- Put test bench stimulus code here

    stop_the_clock <= true;
    wait;
  end process;

  clocking: process
  begin
    while not stop_the_clock loop
      clk <= '0', '1' after clock_period / 2;
      wait for clock_period;
    end loop;
    wait;
  end process;

end;
