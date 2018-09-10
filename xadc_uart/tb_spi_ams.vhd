library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity tb_spi_ams is
end entity;

architecture arch of tb_spi_ams is

    component spi_ams
    	port (
    		CLK      : in  std_logic;
    		LADC     : out std_logic;
    		SYNC     : out std_logic;
    		SCLK     : out std_logic;
    		DIN      : out std_logic;
    		out_test : out std_logic_vector(15 downto 0));
    end component;

    signal CLK      : std_logic;
    signal LADC     : std_logic;
    signal SYNC     : std_logic;
    signal SCLK     : std_logic;
    signal DIN      : std_logic;
    signal out_test : std_logic_vector(15 downto 0);

    constant clk_period : time := 100 ns;

begin

    spi_ams_i : spi_ams
	port map (
		CLK      => CLK,
		LADC     => LADC,
		SYNC     => SYNC,
		SCLK     => SCLK,
		DIN      => DIN,
		out_test => out_test);

    clk_process : process
    begin
        clk <= '1';
        wait for clk_period/2;
        clk <= '0';
        wait for clk_period/2;
    end process;


end architecture;