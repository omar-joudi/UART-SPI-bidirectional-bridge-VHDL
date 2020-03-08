----------------------------------
--UART-SPI BRIDGE
--bridge.vhd
--
--GSoC 2020
--
--Copyright (C) 2020 Omar Joudi
--Email: s-omarmonzer@zewailcity.edu.eg
----------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bridge is 
	generic (
		clk_rate: natural:= 50000000;
		--
		sampling_rate: natural:= 16;
		data_width_uart: natural:= 8;
		stop_ticks_uart: natural:= 16;
		--
		slaves_no: natural:= 4;
		operating_frequency_spi: natural:= 5000000;
		delay_spi: natural:= 10
	); 
	port (
		clk, reset: in std_logic;
		rx, miso: in std_logic;
		tx, mosi, sclk: out std_logic;
		ss: out std_logic_vector (3 downto 0)
	);
end bridge;

architecture arch of bridge is 
	
	constant baud_rate: std_logic_vector(15 downto 0):= "0010010110000000"; --9600
	--
	signal rx_data_uart: std_logic_vector(7 downto 0);
	signal rx_idle_uart: std_logic;
	signal rx_ready_uart: std_logic;
	--
	signal tx_data_uart: std_logic_vector(7 downto 0);
	signal tx_start_uart: std_logic;
	signal tx_busy_uart: std_logic;
	--
	signal tx_data_spi: std_logic_vector(15 downto 0);
	signal rx_data_spi: std_logic_vector(15 downto 0);
	--
	signal rx_idle_spi: std_logic;
	signal rx_ready_spi: std_logic;
	signal rx_start_spi: std_logic;
	--
	signal tx_busy_spi: std_logic;
	signal tx_start_spi: std_logic;
	--
	signal lsb_first: std_logic;
	signal ckp: std_logic; --clock polarity
	signal cke: std_logic; --clock phase
	signal data_width_spi: unsigned(3 downto 0);
	signal s_select: std_logic_vector(1 downto 0);
	--
	type bridge_fsm is (idle_uart_rx, command1, command2, send_from_uart_to_spi, receive_from_spi, idle_spi_rx, send_to_uart, idle_uart_tx, stop);
	signal state: bridge_fsm;
	--
	signal command: std_logic_vector(1 downto 0); --to determine which recieve from uart state to go to after the idle state (recieve command1, command2, data)
	signal word_complete: std_logic; --to determine if the whole word has arrived from UART (if word size > 8 bits)
	--
	signal no_words: unsigned(5 downto 0);
	signal no_words_2: unsigned(5 downto 0); --another counter for sending data from memory to uart
	--
	type spi_received_memory is array(63 downto 0) of std_logic_vector(15 downto 0);
	signal memory: spi_received_memory;
	--

	begin

	uart_mod: entity work.uart(arch)
		port map(
			clk => clk,
			reset => reset,
			baud_rate => baud_rate,
			--rx 
			rx => rx,
			rx_data => rx_data_uart,
			rx_idle => rx_idle_uart,
			rx_ready => rx_ready_uart,
			--tx
			tx_start => tx_start_uart,
			tx_data => tx_data_uart,
			tx_busy => tx_busy_uart,
			tx => tx);
	--
	spi_mod: entity work.spi(arch)
		port map(
			clk => clk,
			reset => reset,
			--
			tx_data => tx_data_spi,
			rx_data => rx_data_spi,
			--
			rx_idle => rx_idle_spi,
			rx_ready => rx_ready_spi,
			rx_start => rx_start_spi,
			--
			tx_busy => tx_busy_spi,
			tx_start => tx_start_spi,
			--
			miso => miso,
			mosi => mosi,
			sclk => sclk,
			--
			ss => ss,
			--
			lsb_first => lsb_first,
			ckp => ckp, --clock polarity
			cke => cke, --clock phase
			data_width => data_width_spi,
			s_select =>  s_select--size depends on no. of slaves
			);
	--
	process (clk)
	begin
	if rising_edge(clk) then
		if reset = '1' then
			state <= idle_uart_rx;
			--
			tx_data_uart <= (others => '0');
			tx_start_uart <= '0';
			--
			tx_data_spi <= (others => '0');
			tx_start_spi <= '0';
			--
			command <= "00";
			word_complete <= '0';
			--
		else
			case state is
				when idle_uart_rx =>
					tx_start_spi <= '0';
					tx_start_uart <= '0';
					if rx = '0' then
						case command is
							when "00" => 
								state <= command1;
							when "01" =>
								state <= command2;
							when "10" => 
								state <= send_from_uart_to_spi;
							when others =>
								state <= idle_uart_rx;
						end case;
					end if;
				when command1 =>
					if rx_ready_uart = '1' then
						state <= idle_uart_rx;
						command <= "01"; 
						no_words <= unsigned(rx_data_uart(7 downto 2));
						no_words_2 <= unsigned(rx_data_uart(7 downto 2));
						s_select <= rx_data_uart(1 downto 0);
					end if;
				when command2 =>
					if rx_ready_uart = '1' then
						if rx_data_uart(7) = '1' then	
							command <= "10"; 
							state <= idle_uart_rx;
						else
							state <= idle_spi_rx; 
						end if;
						data_width_spi <= unsigned(rx_data_uart(6 downto 3));
						cke <= rx_data_uart(2);
						ckp <= rx_data_uart(1);
						lsb_first <= rx_data_uart(0);
					end if;
				when send_from_uart_to_spi =>
					if rx_ready_uart = '1' then 
						if to_integer(data_width_spi) > 8 then
							if word_complete = '1' then 
								tx_data_spi(15 downto 8) <= rx_data_uart;
								word_complete <= '0';
								tx_start_spi <= '1';
							else 
								tx_data_spi(7 downto 0) <= rx_data_uart;
								word_complete <= '1';
							end if;
						else
							tx_data_spi(7 downto 0) <= rx_data_uart;
							tx_start_spi <= '1';	
						end if;
						if to_integer(no_words) = 0 and (word_complete = '1' or to_integer(data_width_spi) < 8) then
							word_complete <= '0';
							state <= stop;
						else
							state <= idle_uart_rx;
							if word_complete = '1' or to_integer(data_width_spi) < 8 then
								no_words <= no_words - 1;	
							end if;
						end if;
					end if;
				when receive_from_spi =>
					if rx_start_spi = '1' then 
						rx_start_spi <= '0';
					else
						if rx_ready_spi = '1' then
							memory(to_integer(no_words)) <= rx_data_spi;
							if to_integer(no_words) = 0 then
								state <= send_to_uart;
							else
								no_words <= no_words - 1;	
								state <= idle_spi_rx;
							end if;
						end if;
					end if;
				when idle_spi_rx =>
					if rx_idle_spi = '1' then
						rx_start_spi <= '1';
					else
						state <= receive_from_spi;
					end if;
				when send_to_uart =>
					if to_integer(data_width_spi) > 8 then
						if word_complete = '1' then 
							tx_data_uart <= memory(to_integer(no_words_2))(15 downto 8);
							word_complete <= '0';
						else 
							tx_data_uart <= memory(to_integer(no_words_2))(7 downto 0);
							word_complete <= '1';
						end if;
					else
						tx_data_uart <= memory(to_integer(no_words_2))(7 downto 0);
					end if;
					tx_start_uart <= '1';
					if to_integer(no_words_2) = 0 and (word_complete = '1' or to_integer(data_width_spi) < 8) then
						word_complete <= '0';
						state <= stop;
					else
						state <= idle_uart_tx;
						if word_complete = '1' or to_integer(data_width_spi) < 8 then
							no_words_2 <= no_words_2 - 1;	
						end if;
					end if;
				when idle_uart_tx =>
					if tx_start_uart = '1' then 
						tx_start_uart <= '0';
					else
						if tx_busy_uart = '0' then 
							state <= send_to_uart;
						end if;
					end if;
				when stop =>
					command <= "00";
					state <= idle_uart_rx;
			end case;
		end if;
	end if;
	end process;

end arch;