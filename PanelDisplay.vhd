  library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;

  entity PanelDisplay is
  port ( clk : in std_logic;--50Mhz clock
         rst : in std_logic;
         rstWin : in std_logic;--separate reset for counters
         hsync : out std_logic;
         vsync : out std_logic;
         red : out std_logic_vector(3 downto 0);
         green : out std_logic_vector(3 downto 0);
         blue : out std_logic_vector(3 downto 0);
         winX : out std_logic;--leds
         winO : out std_logic;
         full : out std_logic;
         kClock: in std_logic;
         kData: in std_logic;
         out_Hex_X : out std_logic_vector (6 downto 0);
         out_Hex_O : out std_logic_vector (6 downto 0);
         error : out std_logic);	
  end PanelDisplay;

 architecture bhv of PanelDisplay is
  --------New Clock
   signal clkN : std_logic;   
        
  --------VGA counters        
   signal horiz,vert: std_logic_vector(9 downto 0);            
          
  --------Registers for X,O                
   signal outX,outO :std_logic_vector (8 downto 0);
  
  --------Rising Edge Detector
   signal edgeCounterLedO,edgeCounterLedX: std_logic;
   signal enableO,enable_win_O,enable_win_X :std_logic; 
  
  --------ROMs
   signal addressX,addressO : std_logic_vector ( 5 downto 0);
   signal dataX,dataO : std_logic_vector (63 downto 0); 
  
  --------Full and Error Combinational Logic
   signal error_t,full_t : std_logic;
  
  --------MovGen logic
   signal empty,stop,win : std_logic_vector(8 downto 0);
   signal newO: std_logic_vector(8 downto 0);
  
  --------Win Logic
   signal winX_Vector,winO_Vector : std_logic_vector(2 downto 0);
   signal winX_temp,winO_temp : std_logic;
  
  --------Counters
   signal coutX,coutO : std_logic_vector (3 downto 0);
  
  --------temp_reg
   signal din,qout : std_logic_vector (8 downto 0);
  
  --------keyboard inputs
   signal regoutClock1,regoutClock2,regoutData1,regoutData2,edgekClock,fallkClock:std_logic;
   signal kBinary_33bit:std_logic_vector(32 downto 0);
   signal x,temp_x:std_logic_vector(8 downto 0);
   signal kBinary:std_logic_vector(7 downto 0);
   signal x_played,same,en: std_logic;
   signal count : std_logic_vector (35 downto 0);--Counting 33 bits(3 keyboard words) 
 begin
    
-------Registers for storing X,O    	
	 		 
  regX :   process(clk,rst)
         begin
          if rst='1' then
            outX <= (others=>'0');
            x_played<='0';
          elsif rising_edge(clk) then
             if count=32 and error_t='0' and full_t='0' and winO_temp='0' and winX_temp='0' and same='0' and en='1' then 
                outX <= x;		 
                x_played<='1';
             else
                x_played<='0';
             end if;
          end if;
         end process;
    
  regO : process(clk, rst)
         begin
          if rst='1' then
            outO <= (others=>'0');
          elsif rising_edge(clk) then
             if x_played='1' and error_t='0' and full_t='0' and winO_temp='0' and winX_temp='0' then
                outO <= newO;
             end if;
          end if;
         end process;
	 
---------Win counters	 
  counter_win_X:process(clk,rstWin)
	        begin
            if rstWin='1' then
              coutX<=(others=>'0');
            elsif rising_edge(clk) then
	          if enable_win_X='1' and error_t='0' then
		         coutX <= coutX+1;
		       end if;
            end if;
	        end process;
	 
	 
  counter_win_O:process(clk,rstWin)
	        begin
	         if rstWin='1' then
	          coutO<=(others=>'0');
	         elsif rising_edge(clk) then
                  if enable_win_O='1' and error_t='0' then
                    coutO <= coutO +1;
                  end if;
            end if;
           end process;
		 
-------7 segmanets displays

   with coutX (3 downto 0) select
        out_Hex_X <= "1000000" when "0000",
                     "1111001" when "0001", 
		               "0100100" when "0010",
                     "0110000" when "0011",  
	                  "0011001" when "0100",
                     "0010010" when "0101",  
		               "0000010" when "0110",  
		               "1111000" when "0111",  
	                  "0000000" when "1000",  
		               "0000110" when others;  
				 
   with coutO (3 downto 0) select
        out_Hex_O <= "1000000" when "0000",
                     "1111001" when "0001", 
		               "0100100" when "0010",
                     "0110000" when "0011",  
	                  "0011001" when "0100",
                     "0010010" when "0101",  
		               "0000010" when "0110",  
		               "1111000" when "0111",  
	                  "0000000" when "1000",  
		               "0000110" when others;  			
				
-----------ROM for X,O   
  Rom_for_X : process (addressX)
              begin
                case addressX is
                  when "000000" => dataX <= "1111111000000000000000000000000000000000000000000000000001111111";
                  when "000001" => dataX <= "1111111000000000000000000000000000000000000000000000000001111111";
                  when "000010" => dataX <= "1111111000000000000000000000000000000000000000000000000001111111";
                  when "000011" => dataX <= "1111111000000000000000000000000000000000000000000000000001111111";
                  when "000100" => dataX <= "0000111111100000000000000000000000000000000000000000011111110000";
                  when "000101" => dataX <= "0000111111100000000000000000000000000000000000000000011111110000";
                  when "000110" => dataX <= "0000111111100000000000000000000000000000000000000000011111110000";
                  when "000111" => dataX <= "0000000011111110000000000000000000000000000000000111111100000000";
                  when "001000" => dataX <= "0000000011111110000000000000000000000000000000000111111100000000";
                  when "001001" => dataX <= "0000000011111110000000000000000000000000000000000111111100000000";
                  when "001010" => dataX <= "0000000000001111111000000000000000000000000001111111000000000000";
                  when "001011" => dataX <= "0000000000001111111000000000000000000000000001111111000000000000";
                  when "001100" => dataX <= "0000000000001111111000000000000000000000000001111111000000000000";
                  when "001101" => dataX <= "0000000000000000111111100000000000000000011111110000000000000000";
                  when "001110" => dataX <= "0000000000000000111111100000000000000000011111110000000000000000";
                  when "001111" => dataX <= "0000000000000000111111100000000000000000011111110000000000000000";
                  when "010000" => dataX <= "0000000000000000000011111110000000000111111100000000000000000000";
                  when "010001" => dataX <= "0000000000000000000011111110000000000111111100000000000000000000";
                  when "010010" => dataX <= "0000000000000000000011111110000000000111111100000000000000000000";
                  when "010011" => dataX <= "0000000000000000000000001111111001111111000000000000000000000000";
                  when "010100" => dataX <= "0000000000000000000000001111111001111111000000000000000000000000";
                  when "010101" => dataX <= "0000000000000000000000001111111001111111000000000000000000000000";
                  when "010110" => dataX <= "0000000000000000000000000000111111110000000000000000000000000000";
                  when "010111" => dataX <= "0000000000000000000000000000111111110000000000000000000000000000";
                  when "011000" => dataX <= "0000000000000000000000000000111111110000000000000000000000000000";
                  when "011001" => dataX <= "0000000000000000000000000000111111110000000000000000000000000000";
                  when "011010" => dataX <= "0000000000000000000000001111111001111111000000000000000000000000";
                  when "011011" => dataX <= "0000000000000000000000001111111001111111000000000000000000000000";
                  when "011100" => dataX <= "0000000000000000000000001111111001111111000000000000000000000000";
                  when "011101" => dataX <= "0000000000000000000011111110000000000111111100000000000000000000";
                  when "011110" => dataX <= "0000000000000000000011111110000000000111111100000000000000000000";
                  when "011111" => dataX <= "0000000000000000000011111110000000000111111100000000000000000000";
                  when "100000" => dataX <= "0000000000000000111111100000000000000000011111110000000000000000";
                  when "100001" => dataX <= "0000000000000000111111100000000000000000011111110000000000000000";
                  when "100010" => dataX <= "0000000000000000111111100000000000000000011111110000000000000000";
                  when "100011" => dataX <= "0000000000001111111000000000000000000000000001111111000000000000";
                  when "100100" => dataX <= "0000000000001111111000000000000000000000000001111111000000000000";
                  when "100101" => dataX <= "0000000000001111111000000000000000000000000001111111000000000000";
                  when "100110" => dataX <= "0000000011111110000000000000000000000000000000000111111100000000";
                  when "100111" => dataX <= "0000000011111110000000000000000000000000000000000111111100000000";
                  when "101000" => dataX <= "0000000011111110000000000000000000000000000000000111111100000000";
                  when "101001" => dataX <= "0000111111100000000000000000000000000000000000000000011111110000";
                  when "101010" => dataX <= "0000111111100000000000000000000000000000000000000000011111110000";
                  when "101011" => dataX <= "0000111111100000000000000000000000000000000000000000011111110000";
                  when "101100" => dataX <= "1111111000000000000000000000000000000000000000000000000001111111";
                  when "101101" => dataX <= "1111111000000000000000000000000000000000000000000000000001111111";
                  when "101110" => dataX <= "1111111000000000000000000000000000000000000000000000000001111111";
                  when "101111" => dataX <= "1111111000000000000000000000000000000000000000000000000001111111";
                  when others   => dataX <= "0000000000000000000000000000000000000000000000000000000000000000";
                end case;
              end process;
   
  Rom_for_O : process(addressO)
              begin
               case addressO is
                when "000000" => dataO <= "0000000000000000000000000001111111100000000000000000000000000000";
                when "000001" => dataO <= "0000000000000000000000000001111111100000000000000000000000000000";
                when "000010" => dataO <= "0000000000000000000000000111100001111000000000000000000000000000";
                when "000011" => dataO <= "0000000000000000000000000111100001111000000000000000000000000000";
                when "000100" => dataO <= "0000000000000000000000011110000000011110000000000000000000000000";
                when "000101" => dataO <= "0000000000000000000000011110000000011110000000000000000000000000";
                when "000110" => dataO <= "0000000000000000000000111100000000001111000000000000000000000000";
                when "000111" => dataO <= "0000000000000000000000111100000000001111000000000000000000000000";
                when "001000" => dataO <= "0000000000000000000011110000000000000011110000000000000000000000";
                when "001001" => dataO <= "0000000000000000000011110000000000000011110000000000000000000000";
                when "001010" => dataO <= "0000000000000000001111000000000000000000111100000000000000000000";
                when "001011" => dataO <= "0000000000000000001111000000000000000000111100000000000000000000";
                when "001100" => dataO <= "0000000000000000111100000000000000000000001111000000000000000000";
                when "001101" => dataO <= "0000000000000000111100000000000000000000001111000000000000000000";
                when "001110" => dataO <= "0000000000000011110000000000000000000000000011110000000000000000";
                when "001111" => dataO <= "0000000000000011110000000000000000000000000011110000000000000000";
                when "010000" => dataO <= "0000000000001111000000000000000000000000000000111100000000000000";
                when "010001" => dataO <= "0000000000001111000000000000000000000000000000111100000000000000";
                when "010010" => dataO <= "0000000000111100000000000000000000000000000000001111000000000000";
                when "010011" => dataO <= "0000000000111100000000000000000000000000000000001111000000000000";
                when "010100" => dataO <= "0000000011110000000000000000000000000000000000000011110000000000";
                when "010101" => dataO <= "0000000011110000000000000000000000000000000000000011110000000000";
                when "010110" => dataO <= "0000001111000000000000000000000000000000000000000000111100000000";
                when "010111" => dataO <= "0000001111000000000000000000000000000000000000000000111100000000";
                when "011000" => dataO <= "0000001111000000000000000000000000000000000000000000111100000000";
                when "011001" => dataO <= "0000001111000000000000000000000000000000000000000000111100000000";
                when "011010" => dataO <= "0000000011110000000000000000000000000000000000000011110000000000";
                when "011011" => dataO <= "0000000011110000000000000000000000000000000000000011110000000000";
                when "011100" => dataO <= "0000000000111100000000000000000000000000000000001111000000000000";
                when "011101" => dataO <= "0000000000111100000000000000000000000000000000001111000000000000";
                when "011110" => dataO <= "0000000000001111000000000000000000000000000000111100000000000000";
                when "011111" => dataO <= "0000000000001111000000000000000000000000000000111100000000000000";
                when "100000" => dataO <= "0000000000000011110000000000000000000000000011110000000000000000";
                when "100001" => dataO <= "0000000000000011110000000000000000000000000011110000000000000000";
                when "100010" => dataO <= "0000000000000000111100000000000000000000001111000000000000000000";
                when "100011" => dataO <= "0000000000000000111100000000000000000000001111000000000000000000";
                when "100100" => dataO <= "0000000000000000001111000000000000000000111100000000000000000000";
                when "100101" => dataO <= "0000000000000000001111000000000000000000111100000000000000000000";
                when "100110" => dataO <= "0000000000000000000011110000000000000011110000000000000000000000";
                when "100111" => dataO <= "0000000000000000000011110000000000000011110000000000000000000000";
                when "101000" => dataO <= "0000000000000000000000111100000000001111000000000000000000000000";
                when "101001" => dataO <= "0000000000000000000000111100000000001111000000000000000000000000";
                when "101010" => dataO <= "0000000000000000000000011110000000011110000000000000000000000000";
                when "101011" => dataO <= "0000000000000000000000011110000000011110000000000000000000000000";
                when "101100" => dataO <= "0000000000000000000000000111100001111000000000000000000000000000";
                when "101101" => dataO <= "0000000000000000000000000111100001111000000000000000000000000000";
                when "101110" => dataO <= "0000000000000000000000000001111111100000000000000000000000000000";
                when "101111" => dataO <= "0000000000000000000000000001111111100000000000000000000000000000";
                when others   => dataO <= "0000000000000000000000000000000000000000000000000000000000000000";
              end case;
            end process;
    
-------Frequency divider by 2    
  clkDivision:process(clk,rst)
              begin
              if rst='1' then
                clkN<='0';
              elsif rising_edge(clk) then
                clkN<=not(clkN);
              end if;
              end process;
--------Horizontal and Vertical Counters for VGA
  CountHoriz:process(clk,rst)
             begin
             if rst='1' then
               horiz<=(others=>'0');
             elsif rising_edge(clk) then
               if clkN='1' then
                 horiz<=horiz+1;
                 if horiz = 800 then horiz <= (others=>'0'); end if;		  
               end if;
             end if;
             end process;
  
  
  CountVert:process(clk,rst)
            begin
            if rst='1' then 
              vert<=(others=>'0');
            elsif rising_edge(clk) then
              if clkN='1' then
                if horiz=799 then
                  vert<=vert+1;		 
		  if vert = 524 then vert <= (others=>'0'); end if;
                    if (vert>45 and vert< 95)then-----increase address for each line
                      addressX<= addressX + "1";
                      addressO<= addressO + "1";
                    elsif (vert > 200 and vert < 250) then
                      addressX<= addressX + "1";
                      addressO<= addressO + "1";
                    elsif (vert >370 and vert < 420) then
                      addressX<= addressX + "1";
                      addressO<= addressO + "1";
                    else 
                      addressX<= "111111";
                      addressO<= "111111";
                    end if;
                end if;
              end if;
            end if;
            end process;
  
--------Combinational Logic for hsync,vsync  
  hsync<='0' when (horiz>655 and horiz<751) else '1';
  vsync<='0' when (vert>490 and vert<492) else '1'; 
  
--------Process for drawing	
  Print_table:process(clk)
              begin
              if rising_edge(clk) then
                if clkN='1' then
                  if (horiz>639 and horiz<799) then		
                    red<=(others=>'0');
                    green<=(others=>'0');
                    blue<=(others=>'0');
                  elsif (horiz>189 and horiz<224) or(horiz>415 and horiz<449) or(vert>139 and vert<169) or(vert>309 and vert<339) then --draw table
                    red<="1010";
                    green<="0101";
                    blue<="1111";
                  else  --draw background
                    red<="1111";
                    green<="1010";
                    blue<="1001";
                 ------------X[0] 
                    if outX(0)='1' then
                      if (horiz>63 and horiz<129)and (vert>45 and vert< 95) then 
                        if dataX(conv_integer(horiz-64))='1' then
                          red<= "1111";
                          green<= "1111";
                          blue<= "1111";
                        else 
                          red<="1111";
                          green<="1010";
                          blue<="1001";
                        end if;
                      end if;
                    end if;
------------O[0]
                    if outO(0)='1' then
                      if (horiz>63 and horiz<129)and (vert>45 and vert< 95) then 
                        if dataO(conv_integer(horiz-64))='1' then
                          red<= "1111";
                          green<= "1111";
                          blue<= "1111";  
                        else 
                          red<="1111";
                          green<="1010";
                          blue<="1001";
                        end if;
                      end if;
                    end if;
------------X[3]
                    if outX(3)='1' then 
                      if (vert > 200 and vert < 250) and (horiz>63 and horiz<129) then
                        if dataX(conv_integer(horiz-64))='1' then
                          red<= "1111";
                          green<= "1111";
                          blue<= "1111";
                        else 
                          red<="1111";
                          green<="1010";
                          blue<="1001";
                        end if;
                      end if;
                    end if;
------------O[3]
                    if outO(3)='1' then 
                      if (vert > 200 and vert < 250) and (horiz>63 and horiz<129) then
                        if dataO(conv_integer(horiz-64))='1' then
                          red<= "1111";
                          green<= "1111";
                          blue<= "1111";
                        else 
                          red<="1111";
                          green<="1010";
                          blue<="1001";
                        end if;
                      end if;
                    end if;		
------------X[6]
                    if outX(6)='1' then
                      if (vert >370 and vert < 420) and (horiz>63 and horiz<129) then
                        if dataX(conv_integer(horiz-64))='1' then
                          red<= "1111";
                          green<= "1111";
                          blue<= "1111";
                        else
                          red<="1111";
                          green<="1010";
                          blue<="1001";
                        end if;
                      end if;
                    end if;			
------------O[6]
		    if outO(6)='1' then
                      if (vert >370 and vert < 420) and (horiz>63 and horiz<129) then
                        if dataO(conv_integer(horiz-64))='1' then
                          red<= "1111";
                          green<= "1111";
                          blue<= "1111";
                        else
                          red<="1111";
                          green<="1010";
                          blue<="1001";
                       end if;
                     end if;
                   end if;
------------X(1)
		   if outX(1)='1' then
		     if (horiz>285 and horiz<351) and (vert>45 and vert< 95) then 
		       if dataX(conv_integer(horiz-286))='1' then
		         red<= "1111";
                         green<= "1111";
                         blue<= "1111";
                       else
                         red<="1111";
                         green<="1010";
                         blue<="1001";
                       end if;
                     end if;
                   end if;
------------O(1)
                   if outO(1)='1' then
                     if (horiz>285 and horiz<351) and (vert>45 and vert< 95) then 
                       if dataO(conv_integer(horiz-286))='1' then
                         red<= "1111";
                         green<= "1111";
                         blue<= "1111";
                       else
                         red<="1111";
                         green<="1010";
                         blue<="1001"; 
                       end if;
                     end if; 
                   end if;
------------X(4)
                   if outX(4)='1' then
                     if (vert > 200 and vert < 250) and (horiz>285 and horiz<351) then
                       if dataX(conv_integer(horiz-286))='1' then
                         red<= "1111";
                         green<= "1111";
                         blue<= "1111";
                       else
                         red<="1111";
                         green<="1010";
                         blue<="1001";
                       end if;
                     end if;
                   end if;
------------O(4)
                   if outO(4)='1' then
                     if (vert > 200 and vert < 250) and (horiz>285 and horiz<351) then
                       if dataO(conv_integer(horiz-286))='1' then
                         red<= "1111";
                         green<= "1111";
                         blue<= "1111";
                       else
                         red<="1111";
                         green<="1010";
                         blue<="1001";
                       end if;
                     end if;
                   end if;   
------------X(7)
                   if outX(7)='1' then
                     if (vert >370 and vert < 420) and (horiz>285 and horiz<351) then
                       if dataX(conv_integer(horiz-286))='1' then							              
                         red<= "1111";
                         green<= "1111";
                         blue<= "1111";
                       else
                         red<="1111";
                         green<="1010";
                         blue<="1001";
                       end if;
                     end if;
                   end if;
------------O(7)
                   if outO(7)='1' then
                     if (vert >370 and vert < 420) and (horiz>285 and horiz<351) then
                       if dataO(conv_integer(horiz-286))='1' then							              
                         red<= "1111";
                         green<= "1111";
                         blue<= "1111";
                       else
                         red<="1111";
                         green<="1010";
                         blue<="1001";
                       end if;
                     end if;
                   end if; 
------------X(2)
                   if outX(2)='1' then
                     if (vert>45 and vert< 95) and (horiz>510 and horiz<576) then
                       if dataX(conv_integer(horiz-511))='1' then
                         red<= "1111";
                         green<= "1111";
                         blue<= "1111";
                       else
                         red<="1111";
                         green<="1010";
                         blue<="1001";
                       end if;
                     end if;
                   end if;
------------O(2)
                   if outO(2)='1' then
                     if (vert>45 and vert< 95) and (horiz>510 and horiz<576) then
                       if dataO(conv_integer(horiz-511))='1' then
                         red<= "1111";
                         green<= "1111";
                         blue<= "1111";
                       else
                         red<="1111";
                         green<="1010";
                         blue<="1001";
                       end if;
                     end if;
                   end if;
------------X(5)
                   if outX(5)='1' then
                     if (vert > 200 and vert < 250) and (horiz>510 and horiz<576) then
                       if dataX(conv_integer(horiz-511))='1' then
                         red<= "1111";
                         green<= "1111";
                         blue<= "1111";
                       else
                         red<="1111";
                         green<="1010";
                         blue<="1001";
                       end if;
                     end if;
                   end if;
------------O(5)
                   if outO(5)='1' then
                     if (vert > 200 and vert < 250) and (horiz>510 and horiz<576) then
                       if dataO(conv_integer(horiz-511))='1' then
                         red<= "1111";
                         green<= "1111";
                         blue<= "1111";
                       else
                         red<="1111";
                         green<="1010";
                         blue<="1001";
                       end if;
                     end if;
                   end if;
------------X(8)
                   if outX(8)='1' then
                     if (vert >370 and vert < 420) and (horiz>510 and horiz<576) then
                       if dataX(conv_integer(horiz-511))='1' then
                         red<= "1111";
                         green<= "1111";
                         blue<= "1111";
                       else
                         red<="1111";
                         green<="1010";
                         blue<="1001";
                       end if;
                     end if;
                   end if;
------------O(8)
                   if outO(8)='1' then
                     if (vert >370 and vert < 420) and (horiz>510 and horiz<576) then
                       if dataO(conv_integer(horiz-511))='1' then
                         red<= "1111";
                         green<= "1111";
                         blue<= "1111";
                       else
                         red<="1111";
                         green<="1010";
                         blue<="1001";
                       end if;
                     end if;
                   end if;
                 end if;
               end if;
             end if;
             end process;
 
------------Combinational Logic for MovGen circuit  
    empty<=("100000000" or outO) when outX(8)='0' and outO(8)='0' else
           ("010000000" or outO) when outX(7)='0' and outO(7)='0' else
           ("001000000" or outO) when outX(6)='0' and outO(6)='0' else
           ("000100000" or outO) when outX(5)='0' and outO(5)='0' else
           ("000010000" or outO) when outX(4)='0' and outO(4)='0' else
           ("000001000" or outO) when outX(3)='0' and outO(3)='0' else
           ("000000100" or outO) when outX(2)='0' and outO(2)='0' else
           ("000000010" or outO) when outX(1)='0' and outO(1)='0' else
           ("000000001" or outO) when outX(0)='0' and outO(0)='0' else
           (others=>'0'); 

	
    stop<=("100000000" or outO) when ((outX(2)='1' and outX(5)='1') or (outX(0)='1' and outX(4)='1') or (outX(6)='1' and outX(7)='1')) and (outO(8)='0' and outX(8)='0')else 
          ("010000000" or outO) when ((outX(6)='1' and outX(8)='1') or (outX(1)='1' and outX(4)='1')) and (outO(7)='0' and outX(7)='0')else 
          ("001000000" or outO) when ((outX(0)='1' and outX(3)='1') or (outX(2)='1' and outX(4)='1') or (outX(8)='1' and outX(7)='1')) and (outO(6)='0' and outX(6)='0')else
          ("000100000" or outO) when ((outX(2)='1' and outX(8)='1') or (outX(3)='1' and outX(4)='1')) and (outO(5)='0' and outX(5)='0')else
          ("000010000" or outO) when ((outX(0)='1' and outX(8)='1') or (outX(2)='1' and outX(6)='1') or (outX(3)='1' and outX(5)='1') or (outX(1)='1' and outX(7)='1')) and (outO(4)='0' and outX(4)='0')else
          ("000001000" or outO) when ((outX(0)='1' and outX(6)='1') or (outX(4)='1' and outX(5)='1')) and (outO(3)='0' and outX(3)='0')else 
          ("000000100" or outO) when ((outX(0)='1' and outX(1)='1') or (outX(4)='1' and outX(6)='1') or (outX(8)='1' and outX(5)='1')) and (outO(2)='0' and outX(2)='0')else
          ("000000010" or outO) when ((outX(0)='1' and outX(2)='1') or (outX(4)='1' and outX(7)='1')) and (outO(1)='0' and outX(1)='0')else 
          ("000000001" or outO) when ((outX(2)='1' and outX(1)='1') or (outX(3)='1' and outX(6)='1') or (outX(4)='1' and outX(8)='1')) and (outO(0)='0' and outX(0)='0')else
          (others=>'0'); 
			 
			 
    win<= ("100000000" or outO) when ((outO(2)='1' and outO(5)='1') or (outO(0)='1' and outO(4)='1') or (outO(6)='1' and outO(7)='1')) and (outO(8)='0' and outX(8)='0')else 
          ("010000000" or outO) when ((outO(6)='1' and outO(8)='1') or (outO(1)='1' and outO(4)='1')) and (outO(7)='0' and outX(7)='0')else
          ("001000000" or outO) when ((outO(0)='1' and outO(3)='1') or (outO(2)='1' and outO(4)='1') or (outO(8)='1' and outO(7)='1')) and (outO(6)='0' and outX(6)='0')else
          ("000100000" or outO) when ((outO(2)='1' and outO(8)='1') or (outO(3)='1' and outO(4)='1')) and (outO(5)='0' and outX(5)='0')else
          ("000010000" or outO) when ((outO(0)='1' and outO(8)='1') or (outO(2)='1' and outO(6)='1') or (outO(3)='1' and outO(5)='1') or (outO(1)='1' and outO(7)='1')) and (outO(4)='0' and outX(4)='0')else 
          ("000001000" or outO) when ((outO(0)='1' and outO(6)='1') or (outO(4)='1' and outO(5)='1')) and (outO(3)='0' and outX(3)='0')else
          ("000000100" or outO) when ((outO(0)='1' and outO(1)='1') or (outO(4)='1' and outO(6)='1') or (outO(8)='1' and outO(5)='1')) and (outO(2)='0' and outX(2)='0')else 
          ("000000010" or outO) when ((outO(0)='1' and outO(2)='1') or (outO(4)='1' and outO(7)='1')) and (outO(1)='0' and outX(1)='0')else
          ("000000001" or outO) when ((outO(2)='1' and outO(1)='1') or (outO(3)='1' and outO(6)='1') or (outO(4)='1' and outO(8)='1')) and (outO(0)='0' and outX(0)='0') else
          (others=>'0'); 
 
    newO <= win when  (win(8)='1' or win(7)='1' or win(6)='1' or win(5)='1' or win(4)='1' or win(3)='1' or win(2)='1' or win(1)='1' or win(0)='1') else
            stop when  (stop(8)='1' or stop(7)='1' or stop(6)='1' or stop(5)='1' or stop(4)='1' or stop(3)='1' or stop(2)='1' or stop(1)='1' or stop(0)='1') else
            empty when (empty(8)='1' or empty(7)='1' or empty(6)='1' or empty(5)='1' or empty(4)='1' or empty(3)='1' or empty(2)='1' or empty(1)='1' or empty(0)='1') else
            (others=>'0');
		  
--------Combinational Logic for finding the winner		  
    winX_Vector(2) <='1' when outX(8 downto 6)="111" or outX(5 downto 3)="111" or outX(2 downto 0)="111" else '0';
    winX_Vector(1) <='1' when ((outX(6)='1'  and outX(3)='1' and outX(0)='1') or (outX(7)='1' and outX(4)='1' and outX(1)='1') or (outX(8)='1' and outX(5)='1' and outX(2)='1')) else '0';
    winX_Vector(0) <='1' when ((outX(8)='1' and outX(4)='1' and outX(0)='1') or (outX(6)='1' and outX(4)='1' and outX(2)='1')) else '0';
    winX_temp <= '1' when winX_Vector(2)='1' or winX_Vector(1)='1' or winX_Vector(0)='1' else '0';
    winX <= '1' when winX_temp='1' and winO_temp='0' and error_t='0' else '0';
	 
    winO_Vector(2) <='1' when outO(8 downto 6)="111" or outO(5 downto 3)="111" or outO(2 downto 0)="111" else '0';
    winO_Vector(1) <='1' when ((outO(6)='1'  and outO(3)='1' and outO(0)='1') or (outO(7)='1' and outO(4)='1' and outO(1)='1') or (outO(8)='1' and outO(5)='1' and outO(2)='1')) else '0';
    winO_Vector(0) <='1' when ((outO(8)='1' and outO(4)='1' and outO(0)='1') or (outO(6)='1' and outO(4)='1' and outO(2)='1')) else '0';
    winO_temp <= '1' when winO_Vector(2)='1' or winO_Vector(1)='1' or winO_Vector(0)='1' else '0';
    winO <= '1' when winO_temp='1' and winX_temp='0' and error_t='0' else '0';
	
--------Combinational Logic for Full and Error leds

  error_t <= '0' when (outX and outO)="000000000" else '1';
  error<=error_t;
 
  full_t <= '1' when (outX or outO)="111111111" else '0';
  full<=full_t;
 
 
 
  EdgeDetectorForWinCounters:process(clk,rstWin)
  begin
  if rstWin='1' then
    edgeCounterLedO<='0';
  elsif rising_edge(clk) then
    edgeCounterLedO<=winO_temp;
  end if;
  end process;
--------Rising Edge Detector for O		  
  enable_win_O <='1' when (not(edgeCounterLedO) and winO_temp)='1' else '0';	 
 
  
  EdgeDetectorForLeds:process(clk,rstWin)
  begin
  if rstWin='1' then
    edgeCounterLedX<='0';
  elsif rising_edge(clk) then
    edgeCounterLedX<=winX_temp;
  end if;
  end process;
--------Rising Edge Detector for X	 		  
  enable_win_X <='1' when (not(edgeCounterLedX) and winX_temp)='1' else '0';	 
      
--------Synchronizers Foe keyboard      
  sychronizerData:process(clk,rst)
                   begin
                   if rst='1' then
                     regoutData1<='0';
							regoutData2<='0';
                   elsif rising_edge(clk) then
                     regoutData1<=kData;
							regoutData2<=regoutData1;
                   end if;
                   end process; 

  sychronizerClock:process(clk,rst)
                    begin
                    if rst='1' then
                      regoutClock1<='0';
							 regoutClock2<='0';
                    elsif rising_edge(clk) then
                      regoutClock1<=kClock;
							 regoutClock2<=regoutClock1;
                    end if;
                    end process; 

--------Edge Detectors for keyboard 
  EdgeDetectorKeybClock:process(clk,rst)
                        begin
                        if rst='1' then
                          edgekClock<='0';
                        elsif rising_edge(clk) then
                          edgekClock<=regoutClock2;
                        end if;
                        end process; 
--------Falling Edge Detector for keyboard clock							
  fallkClock<='1' when (edgekClock and not(regoutClock2))='1' else '0';
      
--------Shifting and counting keyboard data      
  process(clk,rst)
  begin
  if rst='1' then
    kBinary_33bit <= (others=>'0');
     count<=(others=>'0');
  elsif rising_edge(clk) then
    if fallkClock='1' then
     if count = 32 then
        count<=(others=>'0');
        kBinary_33bit <= (others=>'0');
     else
        count<=count+1;
        kBinary_33bit(32 downto 1)<=kBinary_33bit(31 downto 0);
        kBinary_33bit(0)<=regoutData2; 
     end if;
    end if;
  end if;
  end process;
   
   
--------Keeping character pressed   
  kBinary<=kBinary_33bit(8 downto 1);  
--------Combinational Logic for matching keys with boxes   
  temp_x(0)<='1' when kBinary="01101000" else '0';
  temp_x(1)<='1' when kBinary="01111000" else '0';
  temp_x(2)<='1' when kBinary="01100100" else '0';
  temp_x(3)<='1' when kBinary="10100100" else '0';
  temp_x(4)<='1' when kBinary="01110100" else '0';
  temp_x(5)<='1' when kBinary="01101100" else '0'; 
  temp_x(6)<='1' when kBinary="10111100" else '0';
  temp_x(7)<='1' when kBinary="01111100" else '0';
  temp_x(8)<='1' when kBinary="01100010" else '0';
--------Checking if correct buttons are pressed  
  en<='1' when (temp_x(0) or temp_x(1) or temp_x(2) or temp_x(3) or temp_x(4) or temp_x(5) or temp_x(6) or temp_x(7) or temp_x(8))='1' else '0';
--------Storing to register X  
  x<=temp_x or outX;
--------Checking if same button is pressed  
  same <= '0' when (outX and temp_x)="00000000" else '1';
 end bhv;
			 
