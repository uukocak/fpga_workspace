library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity  uart_tx_module is
  generic(
    baud_rate  : integer := 9600;
    clk_freq   : integer := 100 );
  port (
    tx_byte     : in std_logic_vector(7 downto 0);
    tx_start    : in std_logic;
    clk         : in std_logic;
    chip_enable : in std_logic;
    tx_line     : out std_logic;
    tx_done     : out std_logic);
end entity;

architecture arch of  uart_tx_module is

  signal clock_per_bit : integer := (clk_freq * 1000000) / baud_rate ;

begin

  identifier : process(clk,tx_start,chip_enable)
  variable tx_package : std_logic_vector(9 downto 0);
  variable clock_counter : integer := 0;
  variable package_index : integer := 0;
  begin

    if(chip_enable = '1') then
      if(clk'event and clk = '1') then

        if(clock_counter < clock_per_bit) then
          clock_counter := clock_counter + 1;
        elsif (clock_counter = clock_per_bit and package_index /= 10) then
          tx_line <= tx_package(package_index);
          package_index := package_index + 1;
          clock_counter := 0;
        end if;

        if( package_index = 10 ) then
          tx_done <= '1';
          tx_line <= '1';
        end if;

        if( tx_start = '1') then
          tx_package := ('1' & tx_byte & '0');
          tx_done <= '0';
          clock_counter := 0;
          package_index := 0;
        end if;
      end if;

    end if;
  end process;

end architecture;
