----------------------------------
--UART-SPI BRIDGE
--spi.vhd
--
--GSoC 2020
--
--Copyright (C) 2020 Omar Joudi
--Email: s-omarmonzer@zewailcity.edu.eg
----------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi is 
	generic (
		slaves_no: natural:= 4;
		clk_rate: natural:= 50000000;
		operating_frequency: natural:= 5000000;
		delay: natural:= 10 
	);
	port (
		clk, reset: in std_logic;
		--
		tx_data: in std_logic_vector(15 downto 0);
		rx_data: out std_logic_vector(15 downto 0);
		--
		rx_idle: out std_logic;
		rx_ready: out std_logic;
		rx_start: in std_logic;
		--
		tx_busy: out std_logic;
		tx_start: in std_logic;
		--
		miso: in std_logic;
		mosi: out std_logic;
		sclk: out std_logic;
		--
		ss: out std_logic_vector(slaves_no-1 downto 0);
		--
		lsb_first: in std_logic;
		ckp: in std_logic; --clock polarity
		cke: in std_logic; --clock phase
		data_width: in unsigned (3 downto 0);
		s_select: in std_logic_vector (1 downto 0) --size depends on no. of slaves 
	);
end spi;

architecture arch of spi is 
	constant freq: natural:= clk_rate/ operating_frequency;
	--
	signal d_reg_tx: std_logic_vector (15 downto 0); --data register
	signal d_reg_rx: std_logic_vector (15 downto 0);
	--
	signal c_counter: unsigned (3 downto 0); --clock counter, size depends on freq
	signal d_counter:unsigned (3 downto 0); --counter for data
	signal delay_counter:unsigned (3 downto 0); --counter for delay
	signal shift, sample: std_logic;
	signal tx_start_reg: std_logic;
	--
	type spi_states is (idle, start, send, receive, stop); 
	signal state: spi_states;
	--
begin 
	process (clk)
	begin
		if rising_edge(clk) then
		if reset = '1' then
			d_reg_rx <= (others => '0');
			d_counter <= (others => '0');
			delay_counter <= (others => '0');
			state <= idle;
			--
			rx_idle <= '1';
			rx_ready <= '0';
			tx_busy <= '0';
			sclk <= '0'; 
			ss <= "1111"; 
		else
			case state is 
				when idle =>
					if tx_start = '1' or rx_start = '1' then 
						state <= start;
						rx_idle <= '0';
						tx_busy <= '1';
						if rx_start = '1' then 
							rx_ready <= '0'; 
							d_reg_rx <= (others => '0');
						end if;
						d_reg_tx <= tx_data;
						tx_start_reg <= tx_start;
					end if;
				when start => 
					if  shift <= '1' then
						case s_select is 
							when "00" =>
								ss <= "1110";
							when "01" =>
								ss <= "1101";
							when "10" =>
								ss <= "1011";
							when "11" =>
								ss <= "0111";
							when others => 
								ss <= "1111";
						end case;
						if tx_start_reg = '1' and cke = '0' then 
							if lsb_first = '1' then 
								mosi <= d_reg_tx(to_integer(d_counter));
							else
								mosi <= d_reg_tx(to_integer(data_width) - to_integer(d_counter));
							end if;		
						end if;
						if delay_counter = delay/2 - 1 then
							delay_counter <= (others => '0');							if tx_start_reg = '1' then
								state <= send;
							else
								state <= receive;
							end if;
						else
							delay_counter <= delay_counter +1;				
						end if;
					end if;
				when send => 
					if shift = '1' then
						if lsb_first = '1' then 
							mosi <= d_reg_tx(to_integer(d_counter));
						else
							mosi <= d_reg_tx(to_integer(data_width) - to_integer(d_counter));
						end if;
						if d_counter = data_width then 
							state <= stop;
						else
							d_counter <= d_counter + 1;
						end if;
					end if;
				when receive => 
					if sample = '1' then
						if lsb_first = '1' then
							d_reg_rx <= d_reg_rx(15 downto to_integer(data_width)) & miso & d_reg_rx(to_integer(data_width) - 1 downto 1);  
						else
							d_reg_rx <= d_reg_rx(14 downto 0) & miso;
						end if;
						if d_counter = data_width then 
							state <= stop;
						else
							d_counter <= d_counter + 1;
						end if;
					end if;
				when stop => 
					if shift = '1' then
						ss <= "1111";
						state <= idle;
						rx_idle <= '1';
						if tx_start_reg = '0' then rx_ready <= '1'; end if;
						tx_busy <= '0';
						d_counter <= (others => '0');
					end if;
			end case;
		end if;

		--clock
		if state = idle then 
			mosi <= '0';
			c_counter <= (others => '0');
			sclk <= ckp;
			shift <= '0';
			sample <= '0';
		else
			if c_counter = freq - 1 then 
				c_counter <= (others => '0');
				if cke = '1' then
					sample <= '1';
				else
					shift <= '1';
				end if;
			else 
				c_counter <= c_counter +1;
				if c_counter = freq/2  then
					sclk <= not ckp;
					shift <= '0';
					sample <= '0';
				else 
					if c_counter = freq/2 - 1 then
						if cke = '1' then
							shift <= '1';
						else
							sample <= '1';
						end if;
					else
						if c_counter = 0 then 
							sclk <= ckp;
							shift <= '0';
							sample <= '0';
						else
							shift <= '0';
							sample <= '0';
						end if;
					end if;
				end if;
			end if;
		end if;
		end if;
	end process;
	rx_data <= d_reg_rx;
end arch;
