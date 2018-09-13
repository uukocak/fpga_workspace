library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity  uart_rx_module is
  generic(
    baud_rate  : integer := 9600;
    clk_freq   : integer := 100 );
  port (
    clk         : in std_logic;
    chip_enable : in std_logic;
    rx_line     : in std_logic;
    rx_byte     : out std_logic_vector(7 downto 0);
    rx_done     : out std_logic);
end entity;

architecture arch of  uart_rx_module is

  type t_fsm is (idle,receive,done);
  signal state : t_fsm := idle;
  constant clock_per_bit : integer := (clk_freq * 1000000) / baud_rate ;

begin

  identifier : process(clk,chip_enable)
  variable rx_package : std_logic_vector(9 downto 0);
  variable clock_counter : integer range 0 to clock_per_bit := 0;
  variable package_index : integer range 0 to 15 := 0;
  begin

    if(chip_enable = '1') then
      if(clk'event and clk = '1') then

        case state is
          when idle =>
            rx_done <= '0';
            if rx_line = '0' then
              state <= receive;
              clock_counter := 0;
            else
              state <= idle;
            end if;

          when receive=>
            if ( clock_counter = clock_per_bit/2) then
              rx_package(package_index) := rx_line;
              clock_counter := clock_counter + 1;
            elsif ( clock_counter < clock_per_bit ) then
              clock_counter := clock_counter + 1;
            elsif (clock_counter = clock_per_bit) then
              package_index := package_index + 1;
              clock_counter := 0;
              if(package_index = 9) then
                state <= done;
                package_index := 0;
              else
                state <= receive;
              end if;
            end if;

          when done =>
            rx_done <= '1';
            rx_byte <= rx_package(8 downto 1);
            state <= idle;

          when others =>
            state <= idle;

          end case;
      end if;
    end if;
  end process;

end architecture;
