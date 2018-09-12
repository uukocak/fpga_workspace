library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller is
    Port (
    clk         : in  std_logic;
    rst         : in  std_logic;
    xadc_vp     : in  std_logic;
    xadc_vn     : in  std_logic;
    xadc_vauxp0 : in  std_logic;
    xadc_vauxn0 : in  std_logic;
    xadc_vauxp8 : in  std_logic;
    xadc_vauxn8 : in  std_logic;
    uart_out    : out std_logic;
    tx_byte_out : out std_logic_vector(7 downto 0)
    );
end controller;

architecture Behavioral of controller is

    COMPONENT xadc_wiz_0
      PORT (
        di_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        daddr_in : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
        den_in : IN STD_LOGIC;
        dwe_in : IN STD_LOGIC;
        drdy_out : OUT STD_LOGIC;
        do_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        dclk_in : IN STD_LOGIC;
        reset_in : IN STD_LOGIC;
        vp_in : IN STD_LOGIC;
        vn_in : IN STD_LOGIC;
        vauxp0 : IN STD_LOGIC;
        vauxn0 : IN STD_LOGIC;
        vauxp8 : IN STD_LOGIC;
        vauxn8 : IN STD_LOGIC;
        channel_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        eoc_out : OUT STD_LOGIC;
        alarm_out : OUT STD_LOGIC;
        eos_out : OUT STD_LOGIC;
        busy_out : OUT STD_LOGIC
      );
    END COMPONENT;

    component uart_tx_module
    	generic (
    		baud_rate : integer := 9600;
    		clk_freq  : integer := 100);
    	port (
    		tx_byte     : in  std_logic_vector(7 downto 0);
    		tx_start    : in  std_logic;
    		clk         : in  std_logic;
    		chip_enable : in  std_logic;
    		tx_line     : out std_logic;
    		tx_done     : out std_logic);
    end component;

    COMPONENT ila_0
    PORT (
        clk : IN STD_LOGIC;
        probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe5 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe6 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
    END COMPONENT;

    signal xadc_addr        : std_logic_vector(6 downto 0);
    signal xadc_en          : std_logic;
    signal xadc_ready       : std_logic;
    signal xadc_data        : std_logic_vector(15 downto 0);
    signal xadc_eos         : std_logic;

    signal tx_byte  : std_logic_vector(7 downto 0);
    signal tx_start : std_logic;
    signal tx_en    : std_logic := '1';
    signal tx_line  : std_logic;
    signal tx_done  : std_logic;

    --type state_t is (idle, read_temp, read_voltage, read_vpn, read_vauxpn0, read_vauxpn8, pre_send, send);
    type state_t is (idle,read_vpn, pre_send, send);

    signal state : state_t := idle;

    signal i_xadc_eos   : std_logic_vector(0 downto 0);
    signal i_xadc_en    : std_logic_vector(0 downto 0);
    signal i_xadc_ready : std_logic_vector(0 downto 0);
    signal i_rst        : std_logic_vector(0 downto 0);
    signal i_tx_start   : std_logic_vector(0 downto 0);

begin

    i_xadc_eos(0)   <= xadc_eos;
    i_xadc_en(0)    <= xadc_en;
    i_xadc_ready(0) <= xadc_ready;
    i_rst(0)        <= rst;
    i_tx_start(0)   <= tx_start;

    uart_out <= tx_line;

    x_adc_module_i : xadc_wiz_0
    port map (
        di_in       => (others => '0'),
        daddr_in    => xadc_addr,
        den_in      => xadc_en,
        dwe_in      => '0',
        drdy_out    => xadc_ready,
        do_out      => xadc_data,
        dclk_in     => clk,
        reset_in    => rst,
        vp_in       => xadc_vp,
        vn_in       => xadc_vn,
        vauxp0      => xadc_vauxp0,
        vauxn0      => xadc_vauxn0,
        vauxp8      => xadc_vauxp8,
        vauxn8      => xadc_vauxn8,
        channel_out => open,
        eoc_out     => open,
        alarm_out   => open,
        eos_out     => xadc_eos,
        busy_out    => open);




        ila : ila_0
        PORT MAP (
            clk => clk,
            probe0 => i_xadc_eos,
            probe1 => i_xadc_en,
            probe2 => i_xadc_ready,
            probe3 => i_rst,
            probe4 => i_tx_start,
            probe5 => tx_byte,
            probe6 => xadc_data
        );

    uart_tx_module_i : uart_tx_module
    generic map (
        baud_rate => 115200,
        clk_freq  => 100)
    port map (
        tx_byte     => tx_byte,
        tx_start    => tx_start,
        clk         => clk,
        chip_enable => tx_en,
        tx_line     => tx_line,
        tx_done     => tx_done);

    fsm : process(rst, clk, state)
    variable counter,counter_2 : integer := 0;
    variable temp_buffer       : std_logic_vector(15 downto 0);
    variable voltage_buffer    : std_logic_vector(15 downto 0);
    variable vpn_buffer        : std_logic_vector(15 downto 0);
    variable vauxpn0_buffer    : std_logic_vector(15 downto 0);
    variable vauxpn8_buffer    : std_logic_vector(15 downto 0);
    variable send_package      : std_logic_vector(7 downto 0);
    begin

    if rst = '1' then
        counter := 0;
        counter_2 := 0;
        state <= idle;
    else
        state <= state;
    end if;

    if (clk'event and clk='1') then

        case state is

            when idle =>
                counter := 0;
                counter_2 := 0;
                xadc_addr <= "0000000";
                xadc_en <='0';
                if xadc_eos = '1' then
                    state <= read_vpn;
                else
                    state <= idle;
                end if;

        -- when read_temp =>
        --     xadc_addr <= "0000000";
        --     if counter < 1 then
        --         xadc_en <= '1';
        --         counter := counter + 1;
        --         state <= read_temp;
        --     else
        --         xadc_en <= '0';
        --         if xadc_ready = '1' then
        --             counter := 0;
        --             temp_buffer := xadc_data;
        --             state <= read_voltage;
        --         else
        --             state <= read_temp;
        --         end if;
        --     end if;

        --  when read_voltage =>
        --  xadc_addr <= "0000001";
        --  if counter < 1 then
        --      xadc_en <= '1';
        --      counter := counter + 1;
        --      state <= read_voltage;
        --  else
        --      xadc_en <= '0';
        --      if xadc_ready = '1' then
        --          counter := 0;
        --          voltage_buffer := xadc_data;
        --          state <= read_vpn;
        --      else
        --          state <= read_voltage;
        --      end if;
        --  end if;


          when read_vpn =>
          xadc_addr <= "0000011";
          if counter < 1 then
            xadc_en <= '1';
            counter := counter + 1;
            state <= read_vpn;
          else
            xadc_en <= '0';
            if xadc_ready = '1' then
                counter := 0;
                vpn_buffer := xadc_data;
                state <= pre_send;
            else
                state <= read_vpn;
            end if;
          end if;

         -- when read_vauxpn0 =>
         -- xadc_addr <= "0010000";
         -- if counter < 1 then
         --   xadc_en <= '1';
         --   counter := counter + 1;
         --   state <= read_vauxpn0;
         -- else
         --   xadc_en <= '0';
         --   if xadc_ready = '1' then
         --       counter := 0;
         --       vauxpn0_buffer := xadc_data;
         --       state <= read_vauxpn8;
         --   else
         --       state <= read_vauxpn0;
         --   end if;
         -- end if;

         -- when read_vauxpn8 =>
         -- xadc_addr <= "0011000";
         -- if counter < 1 then
         --   xadc_en <= '1';
         --   counter := counter + 1;
         --   state <= read_vauxpn8;
         -- else
         --   xadc_en <= '0';
         --   if xadc_ready = '1' then
         --       counter := 0;
         --       vauxpn8_buffer := xadc_data;
         --       state <= pre_send;
         --   else
         --       state <= read_vauxpn8;
         --   end if;
         -- end if;

            when pre_send =>
            if tx_done= '1' then
                if counter = 0 then
                    --send_package := temp_buffer(15 downto 8);
                    --state <= send;
                elsif counter = 1 then
                    --send_package := temp_buffer(7 downto 0);
                    --state <= send;
                elsif counter = 2 then
                   -- send_package := x"20";
                   -- state <= send;
                elsif counter = 3 then
                  --  send_package := voltage_buffer(15 downto 8);
                   -- state <= send;
                elsif counter = 4 then
                    --send_package := voltage_buffer(7 downto 0);
                    --state <= send;
                elsif counter = 5 then
                    -- send_package := x"20";
                    -- state <= send;
                elsif counter = 6 then
                     send_package := "0000" & vpn_buffer(15 downto 12);
                     state <= send;
                elsif counter = 7 then
                     send_package := vpn_buffer(11 downto 4);
                     state <= send;
                elsif counter = 8 then
                   --  send_package := x"20";
                   --  state <= send;
                elsif counter = 9 then
                    -- send_package := vauxpn0_buffer(15 downto 8);
                   --  state <= send;
                elsif counter = 10 then
                  --   send_package := vauxpn0_buffer(7 downto 0);
                   --  state <= send;
                elsif counter = 11 then
                    -- send_package := x"20";
                    -- state <= send;
                elsif counter = 12 then
                   --  send_package := vauxpn8_buffer(15 downto 8);
                  --   state <= send;
                elsif counter = 13 then
                   --  send_package := vauxpn8_buffer(7 downto 0);
                  --   state <= send;
                elsif counter = 14 then
                   -- send_package := x"0A";
                 --   state <= send;
                elsif counter > 10000 then--1 s wait for (100 mhz)
                    counter := 0;
                    state <= idle;
                else
                    send_package := x"00";
                    state <= pre_send;
                end if;
                counter := counter + 1;
            else
                state <= pre_send;
            end if;


            when send =>
                tx_byte <= send_package;
                if counter_2 < 2 then
                    tx_start <= '1';
                    counter_2 := counter_2 + 1;
                    state <= send;
                else
                    tx_start  <= '0';
                    counter_2 := 0;
                    state <= pre_send;
                end if;


        end case;
    end if;

    end process;


end Behavioral;
