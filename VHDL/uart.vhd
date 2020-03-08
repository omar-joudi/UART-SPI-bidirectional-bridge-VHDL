----------------------------------
--UART-SPI BRIDGE
--uart.vhd
--
--GSoC 2020
--
--Copyright (C) 2020 Omar Joudi
--Email: s-omarmonzer@zewailcity.edu.eg
----------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart is 
	generic (
		clk_rate: natural:= 50000000;
		sampling_rate: natural:= 16;
		data_width: natural:= 8;
		stop_ticks: natural:= 16 --ticks for stop bits
	);
	port (
		clk: in std_logic;
		reset: in std_logic;
		baud_rate: in std_logic_vector (15 downto 0);
		--rx 
		rx: in std_logic;
		rx_data: out std_logic_vector (7 downto 0);
		rx_idle: out std_logic;
		rx_ready: out std_logic;
		--
		--tx
		tx_start: in std_logic;
		tx_data: in std_logic_vector (7 downto 0);
		tx_busy: out std_logic;
		tx: out std_logic);
end uart;

architecture arch of uart is 
	signal freq: natural;
	type state_type is (idle, start, data, stop); 
	--rx signals
	signal rx_state: state_type;
	signal s_counter_rx: unsigned (3 downto 0); --counter for clock sampling ticks
	signal d_counter_rx: unsigned (2 downto 0); --counter for data register	signal 
	signal d_reg_rx: std_logic_vector (7 downto 0);
	signal counter_rx: unsigned (9 downto 0); --counter for module frequency--size depends on freq
	signal tick_rx: std_logic; 
	--tx signals
	signal tx_state: state_type;
	signal s_counter_tx: unsigned (3 downto 0); --counter for clock sampling ticks
	signal d_counter_tx: unsigned (2 downto 0); --counter for data register	signal  
	signal d_reg_tx: std_logic_vector (7 downto 0);
	signal counter_tx: unsigned (9 downto 0); --counter for module frequency--size depends on freq
	signal tick_tx: std_logic; 
	
	begin

	process (clk)
	begin
	if rising_edge(clk) then
	
	if reset = '1' then
		freq <= clk_rate/(to_integer(unsigned(baud_rate))*sampling_rate);
		--rx signals reset
		rx_state <= idle;
		s_counter_rx <= (others => '0');
		d_counter_rx <= (others => '0');
		s_counter_rx <= (others => '0');
		d_reg_rx <= (others => '0');
		rx_idle <= '1';
		rx_ready <= '0';
		--tx signals reset
		tx_state <= idle;
		s_counter_tx <= (others => '0');
		d_counter_tx <= (others => '0');
		d_reg_tx <= (others => '0');
		tx <= '1';
		tx_busy <= '0';
	else
	--rx FSM
		case rx_state is
			when idle =>
				if rx = '0' then
					rx_ready <= '0';
					rx_idle <= '0';
					rx_state <= start;
				end if;
			when start =>
				if tick_rx = '1' then
				if s_counter_rx = sampling_rate/2 - 1 then
					rx_state <= data;
					s_counter_rx <= (others => '0');
				else
					s_counter_rx <= s_counter_rx + 1;
				end if;
				end if;				
			when data =>
				if tick_rx = '1' then
				if s_counter_rx = sampling_rate - 1 then
					d_reg_rx <= rx & d_reg_rx(data_width - 1 downto 1);
					s_counter_rx <= (others => '0');
					if d_counter_rx = data_width - 1 then
						rx_state <= stop;
						d_counter_rx <= (others => '0');
					else
						d_counter_rx <= d_counter_rx +1;
					end if;
				else
					s_counter_rx <= s_counter_rx + 1;
				end if;
				end if;			
			when stop =>
				if tick_rx = '1' then
				if s_counter_rx = stop_ticks/2 - 1 then
					rx_ready <= '1';
					rx_state <= idle;
					s_counter_rx <= (others => '0');
					rx_idle <= '1';
				else
					s_counter_rx <= s_counter_rx + 1;
				end if;
				end if;			
		end case;
	--tx FSM
		case tx_state is
			when idle =>
				if tx_start = '1' then
					tx_busy <= '1';
					tx_state <= start;
				end if;
			when start =>
				if tick_tx = '1' then
				tx <= '0';
					tx_state <= data;
					d_reg_tx <= tx_data;
				end if;				
			when data =>
				if tick_tx = '1' then
				if s_counter_tx = sampling_rate - 1 then
					tx <= d_reg_tx(to_integer(d_counter_tx)); 
					s_counter_tx <= (others => '0');
					if d_counter_tx = data_width - 1 then
						tx_state <= stop;
						d_counter_tx <= (others => '0');
					else
						d_counter_tx <= d_counter_tx +1;
					end if;
				else
					s_counter_tx <= s_counter_tx + 1;
				end if;
				end if;			
			when stop =>
				if tick_tx = '1' then
				if s_counter_tx = stop_ticks - 1 then
					tx <= '1';
					tx_state <= idle;
					s_counter_tx <= (others => '0');
					tx_busy <= '0';
				else
					s_counter_tx <= s_counter_tx + 1;
				end if;
				end if;			
		end case;

	end if;
	
	--Generating ticks for rx
	if rx_state = idle then
		counter_rx <= (others => '0');
		tick_rx <= '0';
	else 
		if  counter_rx = freq -1  then 
			counter_rx <= (others => '0');
			tick_rx <= '1';
		else
			counter_rx <= counter_rx + 1;
			tick_rx <= '0';
		end if;
	end if;
	--Generating ticks for tx
	if tx_state = idle then
		counter_tx <= (others => '0');
		tick_tx <= '0';
	else 
		if  counter_tx = freq - 1 then 
			counter_tx <= (others => '0');
			tick_tx <= '1';
		else
			counter_tx <= counter_tx + 1;
			tick_tx <= '0';
		end if;
	end if;
	--
	end if;
	end process;
	rx_data <= d_reg_rx;
end arch;
