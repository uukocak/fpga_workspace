library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity xadc_wrapper_top is
    Port(
    CLK_N       : in  std_logic;
    CLK_P       : in  std_logic;
    UART_TX     : out std_logic;
    RST_BTN     : in  std_logic;
    tx_byte     : out std_logic_vector(7 downto 0);
    AMS_LADC    : out std_logic;
    AMS_SYNC    : out std_logic;
    AMS_SCLK    : out std_logic;
    AMS_DIN     : out std_logic;
    vp          : in  std_logic;
    vn          : in  std_logic;
    vauxp0      : in  std_logic;
    vauxn0      : in  std_logic;
    vauxp8      : in  std_logic;
    vauxn8      : in  std_logic
    );
end xadc_wrapper_top;

architecture Behavioral of xadc_wrapper_top is


component clk_wiz_0
port
 (-- Clock in ports
  -- Clock out ports
  clk_out1          : out    std_logic;
  clk_out2          : out    std_logic;
  -- Status and control signals
  reset             : in     std_logic;
  locked            : out    std_logic;
  clk_in1_p         : in     std_logic;
  clk_in1_n         : in     std_logic
 );
end component;

component controller
	port (
		clk         : in  std_logic;
		rst         : in  std_logic;
		xadc_vp     : in  std_logic;
		xadc_vn     : in  std_logic;
		xadc_vauxp0 : in  std_logic;
		xadc_vauxn0 : in  std_logic;
		xadc_vauxp8 : in  std_logic;
		xadc_vauxn8 : in  std_logic;
		uart_out    : out std_logic;
		tx_byte_out : out std_logic_vector(7 downto 0));
end component;


component spi_ams
	port (
		CLK  : in  std_logic;
		LADC : out std_logic;
		SYNC : out std_logic;
		SCLK : out std_logic;
		DIN  : out std_logic);
end component;


    signal clk : std_logic;
    signal clk_10 : std_logic;

begin

    spi_ams_i : spi_ams
	port map (
		CLK  => CLK_10,
		LADC => AMS_LADC,
		SYNC => AMS_SYNC,
		SCLK => AMS_SCLK,
		DIN  => AMS_DIN);

    clock_wiz_i : clk_wiz_0
       port map (
      -- Clock out ports
       clk_out1 => clk,
       clk_out2 => clk_10,
      -- Status and control signals
       reset => '0',
       locked => open,
       -- Clock in ports
       clk_in1_p => CLK_P,
       clk_in1_n => CLK_N
     );


     controller_i : controller
        port map (
        clk         => clk,
        rst         => RST_BTN,
        xadc_vp     => vp,
        xadc_vn     => vn,
        xadc_vauxp0 => vauxp0,
        xadc_vauxn0 => vauxn0,
        xadc_vauxp8 => vauxp8,
        xadc_vauxn8 => vauxn8,
        uart_out    => UART_TX,
        tx_byte_out => tx_byte);


end Behavioral;
