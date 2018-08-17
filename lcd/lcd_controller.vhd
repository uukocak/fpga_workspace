--------------------------------------------------------------------------------
--  This file is a derivation of the implementation found at
--	https://eewiki.net/download/attachments/4096079/lcd_controller.vhd?version=3&modificationDate=1339620193283&api=v2
--
-- This version works in 4bit mode for 16x2 LCD's .
--
-- Sitronix ST7066U  Dot Matrix LCD Controller/Driver referenced
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

entity lcd_controller is
  port(
    clk        : in    std_logic;  --system clock
    reset_n    : in    std_logic;  --active low reinitializes lcd
    lcd_enable : in    std_logic;  --latches data into lcd controller
    lcd_bus    : in    std_logic_vector(9 downto 0);  --data and control signals
    busy       : out   std_logic := '1';  --lcd controller busy/idle feedback
    rw, rs, e  : out   std_logic;  --read/write, setup/data, and enable for lcd
    lcd_data   : out   std_logic_vector(3 downto 0)--data signals for lcd
    );
end entity;


ARCHITECTURE controller OF lcd_controller IS
  TYPE CONTROL IS(power_up, initialize, ready, send,send_byte);
  SIGNAL    state      : CONTROL;
  CONSTANT  freq       : INTEGER := 50; --system clock frequency in MHz
BEGIN
  PROCESS(clk)
    VARIABLE clk_count : INTEGER := 0; --event counter for timing
    VARIABLE send_byte_counter : INTEGER := 0;
    VARIABLE send_byte_buffer : STD_LOGIC_VECTOR(7 downto 0);
    VARIABLE send_byte_prev_state : CONTROL;
  BEGIN
  IF(clk'EVENT and clk = '1') THEN

      CASE state IS

        --wait 50 ms to ensure Vdd has risen and required LCD wait is met
        WHEN power_up =>
          busy <= '1';
          IF(clk_count < (50000 * freq)) THEN    --wait 50 ms
            clk_count := clk_count + 1;
            state <= power_up;
          ELSE                                   --power-up complete
            clk_count := 0;
            rs <= '0';
            rw <= '0';
            lcd_data <= "0011";
            state <= initialize;
          END IF;

        --cycle through initialization sequence
        WHEN initialize =>
          busy <= '1';
          clk_count := clk_count + 1;
          IF(clk_count = (10 * freq)) THEN       --function set
            send_byte_buffer := "00111100";
            send_byte_prev_state := initialize;
            state <= send_byte;
          ELSIF(clk_count = (60 * freq)) THEN    --wait 50 us
            send_byte_buffer := "00001111";
            send_byte_prev_state := initialize;
            state <= send_byte;
          ELSIF(clk_count = (130 * freq)) THEN    --display on/off control
            send_byte_buffer := "00000001";
            send_byte_prev_state := initialize;
            state <= send_byte;
          ELSIF(clk_count = (2130 * freq)) THEN  --wait 2 ms
            send_byte_buffer := "00000110";
            send_byte_prev_state := initialize;
            state <= send_byte;
          ELSIF (clk_count > (2130 * freq)) THEN  --initialization complete
            clk_count := 0;
            busy <= '0';
            state <= ready;
          ELSE
            state <= initialize;
          END IF;

        --wait for the enable signal and then latch in the instruction
        WHEN ready =>
          IF(lcd_enable = '1') THEN
            busy <= '1';
            rs <= lcd_bus(9);
            rw <= lcd_bus(8);
            send_byte_buffer := lcd_bus(7 DOWNTO 0);
            clk_count := 0;
            state <= send;
          ELSE
            busy <= '0';
            rs <= '0';
            rw <= '0';
            send_byte_buffer := "00000000";
            clk_count := 0;
            state <= ready;
          END IF;

        --send instruction to lcd
        WHEN send =>
        clk_count := clk_count + 1;
        IF(clk_count = (50 * freq)) THEN  --do not exit for 50us
           busy <= '1';
           send_byte_prev_state := send;
           state <= send_byte;
        ELSIF clk_count > (50 * freq) THEN
          clk_count := 0;
          state <= ready;
        ELSE
          busy <= '1';
        END IF;

        WHEN send_byte =>

          IF(send_byte_counter < (2 * freq)) THEN       --function set
            lcd_data <= send_byte_buffer(7 downto 4);   -- MSB
            e <= '0';
            state <= send_byte;
          ELSIF(send_byte_counter < (12 * freq)) THEN
            lcd_data <= send_byte_buffer(7 downto 4);
            e <= '1';
            state <= send_byte;
          ELSIF(send_byte_counter < (14 * freq)) THEN
            lcd_data <= send_byte_buffer(7 downto 4);
            e <= '0';
            state <= send_byte;
          ELSIF(send_byte_counter < (16 * freq)) THEN
            lcd_data <= send_byte_buffer(3 downto 0);
            e <= '0';
            state <= send_byte;
          ELSIF(send_byte_counter < (26 * freq)) THEN
            lcd_data <= send_byte_buffer(3 downto 0);
            e <= '1';
            state <= send_byte;
          ELSIF(send_byte_counter < (28 * freq)) THEN
            lcd_data <= send_byte_buffer(3 downto 0);
            e <= '0';
            state <= send_byte;
          ELSIF(send_byte_counter > (28 * freq)) THEN
            lcd_data <= "0000";
            e <= '0';
            state <= send_byte_prev_state;
            send_byte_counter := 0;
          END IF;
          send_byte_counter := send_byte_counter + 1;

      END CASE;

      --reset
      IF(reset_n = '1') THEN
          state <= power_up;
      END IF;

    END IF;
  END PROCESS;
END controller;
