--------------------------------------------------------------------------------
--
--   FileName:         lcd_controller.vhd
--   Dependencies:     none
--   Design Software:  Quartus II 32-bit Version 11.1 Build 173 SJ Full Version
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 6/2/2006 Scott Larson
--     Initial Public Release
--    Version 2.0 6/13/2012 Scott Larson
--
--   CLOCK FREQUENCY: to change system clock frequency, change Line 65
--
--   LCD INITIALIZATION SETTINGS: to change, comment/uncomment lines:
--
--   Function Set
--      2-line mode, display on             Line 93    lcd_data <= "00111100";
--      1-line mode, display on             Line 94    lcd_data <= "00110100";
--      1-line mode, display off            Line 95    lcd_data <= "00110000";
--      2-line mode, display off            Line 96    lcd_data <= "00111000";
--   Display ON/OFF
--      display on, cursor off, blink off   Line 104   lcd_data <= "00001100";
--      display on, cursor off, blink on    Line 105   lcd_data <= "00001101";
--      display on, cursor on, blink off    Line 106   lcd_data <= "00001110";
--      display on, cursor on, blink on     Line 107   lcd_data <= "00001111";
--      display off, cursor off, blink off  Line 108   lcd_data <= "00001000";
--      display off, cursor off, blink on   Line 109   lcd_data <= "00001001";
--      display off, cursor on, blink off   Line 110   lcd_data <= "00001010";
--      display off, cursor on, blink on    Line 111   lcd_data <= "00001011";
--   Entry Mode Set
--      increment mode, entire shift off    Line 127   lcd_data <= "00000110";
--      increment mode, entire shift on     Line 128   lcd_data <= "00000111";
--      decrement mode, entire shift off    Line 129   lcd_data <= "00000100";
--      decrement mode, entire shift on     Line 130   lcd_data <= "00000101";
--
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
