library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity xadc_wrapper_top is
    Port(
    CLK_N : in std_logic;
    CLK_P : in std_logic;
    UART_TX : out std_logic;
    RST_BTN : in std_logic;
    tx_byte : out std_logic_vector(7 downto 0)
    );
end xadc_wrapper_top;

architecture Behavioral of xadc_wrapper_top is


component clk_wiz_0
port
 (-- Clock in ports
  -- Clock out ports
  clk_out1          : out    std_logic;
  -- Status and control signals
  reset             : in     std_logic;
  locked            : out    std_logic;
  clk_in1_p         : in     std_logic;
  clk_in1_n         : in     std_logic
 );
end component;

component controller
	port (
		clk      : in  std_logic;
		rst      : in  std_logic;
		uart_out : out std_logic;
        tx_byte_out : out std_logic_vector(7 downto 0)
        );
end component;

    signal clk      : std_logic;

begin

    clock_wiz_i : clk_wiz_0
       port map ( 
      -- Clock out ports  
       clk_out1 => clk,
      -- Status and control signals                
       reset => '0',
       locked => open,
       -- Clock in ports
       clk_in1_p => CLK_P,
       clk_in1_n => CLK_N
     );
     
     controller_i : controller
     port map (
         clk      => clk,
         rst      => RST_BTN,
         uart_out => UART_TX,
         tx_byte_out => tx_byte
         );


end Behavioral;
