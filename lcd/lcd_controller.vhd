--------------------------------------------------------------------------------
--  this file is a derivation of the implementation found at
--	https://eewiki.net/download/attachments/4096079/lcd_controller.vhd?version=3&modificationdate=1339620193283&api=v2
--
-- this version works in 4bit mode for 16x2 lcd's .
--
-- sitronix st7066u  dot matrix lcd controller/driver referenced
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lcd_controller is
    port(
        clk        : in    std_logic;  --system clock
        reset_n    : in    std_logic;  --active low reinitializes lcd
        lcd_enable : in    std_logic;  --latches data into lcd controller
        lcd_bus    : in    std_logic_vector(9 downto 0);  --data and control signals
        busy       : out   std_logic := '1';  --lcd controller busy/idle feedback
        e          : out   std_logic;  --read/write, setup/data, and enable for lcd
        rw         : out   std_logic;
        rs         : out   std_logic;
        lcd_data   : out   std_logic_vector(3 downto 0));
end entity;

architecture controller of lcd_controller is

    type state_t is(power_up, initialize, ready, send,send_byte);
    signal    state      : state_t;
    constant  freq       : integer := 10; --system clock frequency in mhz

begin

    process(clk)
        variable clk_count            : integer range 0 to 50040*freq := 0; --event counter for timing
        variable send_byte_counter    : integer range 0 to 25*freq := 0;
        variable send_byte_buffer     : std_logic_vector(7 downto 0);
        variable send_byte_prev_state : state_t;
    begin
        if(clk'event and clk = '1') then

            case state is
                --wait 50 ms to ensure vdd has risen and required lcd wait is met
                when power_up =>
                    busy <= '1';
                    if(clk_count < (50000 * freq)) then    -- wait for bootup
                        clk_count := clk_count + 1;
                        state <= power_up;
                    elsif(clk_count = 50000 * freq) then   -- send a nibble for 4bit op
                        rs    <= '0';
                        rw    <= '0';
                        clk_count := clk_count + 1;
                        send_byte_buffer := "00000011";
                        send_byte_counter := 12*freq;
                        send_byte_prev_state := power_up;
                        state <= send_byte;
                    elsif(clk_count < 50040 * freq) then  -- wait for 40 us
                        rs    <= '0';
                        rw    <= '0';
                        clk_count := clk_count + 1;
                        state <= power_up;
                    else                                   --power-up complete
                        rs    <= '0';
                        rw    <= '0';
                        clk_count := 0;
                        state <= initialize;
                    end if;

                --cycle through initialization sequence ( wait for 50 us in each)
                when initialize =>
                    busy <= '1';
                    clk_count := clk_count + 1;
                    if(clk_count = (10 * freq)) then       -- function set
                        send_byte_buffer := "00101000";
                        send_byte_prev_state := initialize;
                        state <= send_byte;
                    elsif(clk_count = (60 * freq)) then    -- function set
                        send_byte_buffer := "00101000";
                        send_byte_prev_state := initialize;
                        state <= send_byte;
                    elsif(clk_count = (130 * freq)) then    --display on/off state_t
                        send_byte_buffer := "00001111";
                        send_byte_prev_state := initialize;
                        state <= send_byte;
                    elsif(clk_count = (180 * freq)) then    --clear display
                        send_byte_buffer := "00000001";
                        send_byte_prev_state := initialize;
                        state <= send_byte;
                    elsif(clk_count = (2180 * freq)) then  --wait 2 ms, entry mode set
                        send_byte_buffer := "00000110";
                        send_byte_prev_state := initialize;
                        state <= send_byte;
                    elsif (clk_count > (2180 * freq)) then  --initialization complete
                        clk_count := 0;
                        busy <= '0';
                        state <= ready;
                    else
                        state <= initialize;
                    end if;

                --wait for the enable signal and then latch in the instruction
                when ready =>
                    if(lcd_enable = '1') then
                        busy  <= '1';
                        rs    <= lcd_bus(9);
                        rw    <= lcd_bus(8);
                        send_byte_buffer := lcd_bus(7 downto 0);
                        clk_count := 0;
                        state <= send;
                    else
                        busy  <= '0';
                        send_byte_buffer := "00000000";
                        clk_count := 0;
                        state <= ready;
                    end if;

                --send instruction to lcd
                when send =>
                    clk_count := clk_count + 1;
                    if(clk_count = (50 * freq)) then
                        busy  <= '1';
                        send_byte_prev_state := send;
                        state <= send_byte;
                    elsif clk_count > (50 * freq) then
                        clk_count := 0;
                        state <= ready;
                    else
                        busy <= '1';
                    end if;

                -- Send 8bit data as 2 nibbles (MSB first)
                when send_byte =>
                    if(send_byte_counter < (5 * freq)) then
                        lcd_data <= send_byte_buffer(7 downto 4);
                        e        <= '0';
                        state    <= send_byte;
                    elsif(send_byte_counter < (7 * freq)) then
                        lcd_data <= send_byte_buffer(7 downto 4);
                        e        <= '1';
                        state    <= send_byte;
                    elsif(send_byte_counter < (12 * freq)) then
                        lcd_data <= send_byte_buffer(7 downto 4);
                        e        <= '0';
                        state    <= send_byte;
                    elsif(send_byte_counter < (17 * freq)) then
                        lcd_data <= send_byte_buffer(3 downto 0);
                        e        <= '0';
                        state    <= send_byte;
                    elsif(send_byte_counter < (19 * freq)) then
                        lcd_data <= send_byte_buffer(3 downto 0);
                        e        <= '1';
                        state    <= send_byte;
                    elsif(send_byte_counter < (24 * freq)) then
                        lcd_data <= send_byte_buffer(3 downto 0);
                        e        <= '0';
                        state    <= send_byte;
                    elsif(send_byte_counter > (24 * freq)) then
                        lcd_data <= "0000";
                        e        <= '0';
                        state    <= send_byte_prev_state;
                        send_byte_counter := 0;
                    end if;
                        send_byte_counter := send_byte_counter + 1;

            end case;

            --reset
            if(reset_n = '1') then
              state <= power_up;
              clk_count := 0;
            end if;

        end if;
  end process;
end controller;
