----------------------------------------------------------------------------
--UART-SPI BRIDGE
--uart_tb.vhd
--
--GSoC 2020
--
--Copyright (C) 2020 Omar Joudi
--Email: s-omarmonzer@zewailcity.edu.eg
----------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity uart_tb is 


end uart_tb;


architecture arch of uart_tb is
 
	signal clk, reset: std_logic;
	signal baud_rate: std_logic_vector (15 downto 0):= "0010010110000000"; --9600

	signal rx1_tx2: std_logic;
	signal tx1_rx2: std_logic;

	signal rx_data_1: std_logic_vector (7 downto 0);
	signal rx_idle_1: std_logic;
	signal rx_ready_1: std_logic;
	signal tx_start_1: std_logic;
	signal tx_data_1: std_logic_vector (7 downto 0);
	signal tx_busy_1: std_logic;

	signal rx_data_2: std_logic_vector (7 downto 0);
	signal rx_idle_2: std_logic;
	signal rx_ready_2: std_logic;
	signal tx_start_2: std_logic;
	signal tx_data_2: std_logic_vector (7 downto 0);
	signal tx_busy_2: std_logic;

begin
	uart_1: entity work.uart(arch)
		port map(
			clk => clk,
			reset => reset,
			baud_rate => baud_rate,
			--
			rx => rx1_tx2,
			rx_data => rx_data_1,
			rx_idle => rx_idle_1,
			rx_ready => rx_ready_1,
			--
			tx_start => tx_start_1,
			tx_data => tx_data_1,
			tx_busy => tx_busy_1,
			tx => tx1_rx2);

	uart_2: entity work.uart(arch)
		port map(
			clk => clk,
			reset => reset,
			baud_rate => baud_rate,
			-- 
			rx => tx1_rx2,
			rx_data => rx_data_2,
			rx_idle => rx_idle_2,
			rx_ready => rx_ready_2,
			--
			tx_start => tx_start_2,
			tx_data => tx_data_2,
			tx_busy => tx_busy_2,
			tx => rx1_tx2);

	process begin

		--reset
		reset <= '1';
		wait for 200 ns;

		reset <= '0';
		wait for 200 ns;

		--send data via uart1 and uart2
		tx_data_1 <= "10101010";
		tx_start_1 <= '1';

		tx_data_2 <= "11110000";
		tx_start_2 <= '1';

		wait for 200 ns;

		wait until rx_data_2 = "11110000";

	end process;

end arch;
