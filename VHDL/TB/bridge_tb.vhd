----------------------------------------------------------------------------
--UART-SPI BRIDGE
--bridge_tb.vhd
--
--GSoC 2020
--
--Copyright (C) 2020 Omar Joudi
--Email: s-omarmonzer@zewailcity.edu.eg
----------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity bridge_tb is

 
end bridge_tb;


architecture arch of bridge_tb is 

	signal clk, reset: std_logic;
	signal baud_rate: std_logic_vector (15 downto 0):= "0010010110000000"; --9600
	
	signal rx1_tx_bridge: std_logic;
	signal tx1_rx_bridge: std_logic;
	
	signal rx_data_1: std_logic_vector (7 downto 0);
	signal rx_idle_1: std_logic;
	signal rx_ready_1: std_logic;
	signal tx_start_1: std_logic;
	signal tx_data_1: std_logic_vector (7 downto 0);
	signal tx_busy_1: std_logic;
	
	signal miso, mosi, sclk: std_logic;
	signal ss: std_logic_vector (3 downto 0);

begin
	bridge_1: entity work.bridge(arch)
		port map(
			clk => clk,
			reset => reset,
			rx => tx1_rx_bridge,
			miso => miso,
			tx => rx1_tx_bridge,
			mosi => mosi,
			sclk => sclk,
			ss => ss
		);
	
	uart_1: entity work.uart(arch)
		port map(
			clk => clk,
			reset => reset,
			baud_rate => baud_rate,
			--rx 
			rx => rx1_tx_bridge,
			rx_data => rx_data_1,
			rx_idle => rx_idle_1,
			rx_ready => rx_ready_1,
			--tx
			tx_start => tx_start_1,
			tx_data => tx_data_1,
			tx_busy => tx_busy_1,
			tx => tx1_rx_bridge);
	
	process begin
	
		reset <= '1';
		wait for 200 ns;
		reset <= '0';
		miso <= '0';
	
		--1 words to 01 slave
		tx_data_1 <= "00000001";
		tx_start_1 <= '1';
		wait for 100 ns;
		tx_start_1 <= '0';
		wait until tx_busy_1 <= '0';
	
		--send, 10 bits word, ce = 0, cp = 1, lsb = 1
		tx_data_1 <= "11001011";
		tx_start_1 <= '1';
		wait for 100 ns;
		tx_start_1 <= '0';
		wait until tx_busy_1 <= '0';
	
		tx_data_1 <= "10101010";
		tx_start_1 <= '1';
		wait for 100 ns;
		tx_start_1 <= '0';
		wait until tx_busy_1 <= '0';
	
		tx_data_1 <= "10101010";
		tx_start_1 <= '1';
		wait for 100 ns;
		tx_start_1 <= '0';
		wait until tx_busy_1 <= '0';
	
	
		--2 words to 11 slave
		tx_data_1 <= "00000111";
		tx_start_1 <= '1';
		wait for 100 ns;
		tx_start_1 <= '0';
		wait until tx_busy_1 <= '0';
	
		--receive, 5 bits word, ce = 0, cp = 0, lsb = 0
		tx_data_1 <= "00100000";
		tx_start_1 <= '1';
		wait for 100 ns;
		tx_start_1 <= '0';
		wait until tx_busy_1 <= '0';
	
		--send 00111
		wait until ss <= "0111";
		miso <= '1';
	
		wait until sclk <= '1';
		wait until sclk <= '0';
		miso <= '1';
	
		wait until sclk <= '1';
		wait until sclk <= '0';
		miso <= '1';
	
		wait until sclk <= '1';
		wait until sclk <= '0';
		miso <= '0';
	
		wait until sclk <= '1';
		wait until sclk <= '0';
		miso <= '0';
	
		--send 10101
		wait until ss <= "1111";
	
		wait until ss <= "0111";
		miso <= '1';
	
		wait until sclk <= '1';
		wait until sclk <= '0';
		miso <= '0';
	
		wait until sclk <= '1';
		wait until sclk <= '0';
		miso <= '1';
	
		wait until sclk <= '1';
		wait until sclk <= '0';
		miso <= '0';
	
		wait until sclk <= '1';
		wait until sclk <= '0';
		miso <= '1';
		
		wait for 1500000 ns;
	
	end process;

end arch;
