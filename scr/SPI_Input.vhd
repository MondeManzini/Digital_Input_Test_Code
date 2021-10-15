-------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
-- Kutunse SPI Input
--
-- The firmware performs the following functions:
--
-- IConfiguration of the device.
-- Performing a read of each channel 
-- The method would be to place the address in the ADR_I register and issue a WE_
-- I signal for one ckl cycle only,one clock later the DAT_O will have the four
-- channel As below.
--
-- Signals and registers
-- Bit_Rate_Enable:  this signal is used for the 2Mhz clock for the SPI driver
-- 
--
-- Written by  : Raphael van Rensburg
-- Edited By   : Norah  
-- Tested      : 13/02/2012 Simulation only - Initialiation. SPI read and writes,
--               data
--             : Test do file is SPI_Input.do
-- Last update : 14/02/2012 - Initial release  Version 1.0
--             : 27/06/2013 - Changed File Name from BMO_SPI_Input to ASC_SPI_Input
-- Outstanding : 
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity SPI_Input is

  port (
-- General Signals                  
    RST_I               : in std_logic;
    CLK_I               : in std_logic;
--SPI control signals    
    Int_1               : in  std_logic;
    Int_2               : in  std_logic;    
-- Data Out to MUX
    SPI_Inport_1        : out std_logic_vector(7 downto 0);
    SPI_Inport_2        : out std_logic_vector(7 downto 0);
    SPI_Inport_3        : out std_logic_vector(7 downto 0);
    SPI_Inport_4        : out std_logic_vector(7 downto 0);
    SPI_Inport_5        : out std_logic_vector(7 downto 0);
    SPI_Inport_6        : out std_logic_vector(7 downto 0);
    SPI_Inport_7        : out std_logic_vector(7 downto 0);
    SPI_Inport_8        : out std_logic_vector(7 downto 0);
    Input_Ready         : out std_logic;
-- SPI Data Ouput
    SPI_Data_out        : out std_logic_vector(15 downto 0);
    Input_Data_ready    : out std_logic;
    Input_Card_Select   : out std_logic;
-- SPI Data input
    SPI_Data_in         : in  std_logic_vector(15 downto 0);
    busy                : in  std_logic;
-- Refresh signals
    Sample_Rate         : in  integer range 0 to 1000;
    One_mS_pulse        : in  std_logic
    );
  
end SPI_Input;

architecture Arch_DUT of SPI_Input is

  constant No_Op                 : std_logic_vector(7 downto 0)             := X"00";
  constant Config                : std_logic_vector(7 downto 0)             := X"04"; -- Configuration register
  constant Config_Transition     : std_logic_vector(7 downto 0)             := X"06";
  constant Config_1              : std_logic_vector(7 downto 0)             := X"09";
  constant Config_2              : std_logic_vector(7 downto 0)             := X"0A";
  constant Config_3              : std_logic_vector(7 downto 0)             := X"0B";
  constant Config_4              : std_logic_vector(7 downto 0)             := X"0C";  
  constant Config_5              : std_logic_vector(7 downto 0)             := X"0D";
  constant Config_6              : std_logic_vector(7 downto 0)             := X"0E";
  constant Config_7              : std_logic_vector(7 downto 0)             := X"0F";
  constant output                : std_logic_vector(7 downto 0)             := X"55";
  constant In_w_nPU              : std_logic_vector(7 downto 0)             := X"AA"; --Input with no pull ups
  constant In_w_PU               : std_logic_vector(7 downto 0)             := X"FF"; --Input with pull ups    
  constant Inout_w_PU            : std_logic_vector(7 downto 0)             := X"FF"; --Input/Output with pull ups

  
   
  type SPI_Drive_states is (idle,CS_on,FE_1,RE_1,Cycle_cnt,CS_off,byte_cnt,Last_Sclk);
  
  signal SPI_Drive_state       : SPI_Drive_states;  



  signal SPI_data_o            : std_logic_vector(15 downto 0);
  signal SPI_data_i            : std_logic_vector(15 downto 0);
  signal Lock                  : std_logic;
  signal Trigger               : std_logic;
  signal Card_Select_i         : std_logic;
  signal Input_Data_ready_i    : std_logic;
  
  begin
    Input_Card_Select  <= Card_Select_i;
    Input_Data_ready   <= Input_Data_ready_i;
    SPI_Data_out       <= SPI_data_i;      
    SPI_data_o         <= SPI_Data_in;
    
    SPI_Initialization: process(RST_I,CLK_I)
      
        variable bit_cnt       : integer range 0 to 1024;
        variable bit_number    : integer range 0 to 16;
        variable Device_number : integer range 0 to 4;
        variable int_cnt       : integer range 0 to 100;   -- initialization counter
        variable wait_cnt      : integer range 0 to 100;  -- wait counter
        variable Delay_cnt     : integer range 0 to 1000; -- wait counter 
    begin
      if RST_I = '0' then
         bit_cnt            := 0;
         lock               <= '0';
         Input_Data_ready_i <= '0';
         int_cnt            := 0;
         wait_cnt           := 0;
         SPI_data_i         <= (others => '0');
         Trigger            <= '0';
         SPI_Inport_1       <= (others => '0');
         SPI_Inport_2       <= (others => '0');   
         SPI_Inport_3       <= (others => '0');     
         SPI_Inport_4       <= (others => '0');
         SPI_Inport_5       <= (others => '0');
         SPI_Inport_6       <= (others => '0');   
         SPI_Inport_7       <= (others => '0');     
         SPI_Inport_8       <= (others => '0');
         Input_Ready        <= '0';
         Delay_cnt          := 0;
         Card_Select_i      <= '0';
      elsif CLK_I'event and CLK_I = '1' then
         if One_mS_pulse = '1' then
            bit_cnt         := bit_cnt + 1;
         end if;
         
         if bit_cnt = Sample_Rate then
            Trigger         <= '1';
            bit_cnt         := 0;                      
          else
            Trigger         <= '0';
          end if;   
-------------------------------------------------------------------------------
-- Configuration Card 1
-------------------------------------------------------------------------------                     
       if int_cnt = 0 and busy = '0' and Lock = '0' then
          SPI_data_i            <= Config & X"01";
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
          Card_Select_i         <=  '0';
--          
       elsif int_cnt = 1 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 2 and busy = '0' and Lock = '0' then 
          SPI_data_i            <= Config_Transition & X"00";
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 3 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 4 and busy = '0' and Lock = '0' then
          SPI_data_i            <= Config_1 & In_w_nPU;
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 5 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 6 and busy = '0' and Lock = '0' then
          SPI_data_i            <= Config_2 & In_w_nPU;
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 7 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 8 and busy = '0' and Lock = '0' then
          SPI_data_i            <= Config_3 & In_w_nPU;
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 9 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 10 and busy = '0' and Lock = '0' then
          SPI_data_i            <= Config_4 & In_w_nPU;
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 11 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 12 and busy = '0' and Lock = '0' then
          SPI_data_i            <= Config_5 & In_w_nPU;
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 13 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 14 and busy = '0' and Lock = '0' then
          SPI_data_i            <= Config_6 & In_w_nPU;
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 15 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 16 and busy = '0' and Lock = '0' then
          SPI_data_i            <= Config_7 & In_w_nPU;
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
         
       elsif int_cnt = 17 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 18 and busy = '0' and Lock = '0' then
    --      Card_Select_i         <=  '1';
          SPI_data_i            <=  X"00" & X"00";
--          SPI_data_i            <= Config & X"01";
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
                 
       elsif int_cnt = 19 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt      := int_cnt + 1;
          else
             Delay_cnt    := Delay_cnt + 1;
          end if;
-------------------------------------------------------------------------------
-- Configuration Card 2
-------------------------------------------------------------------------------          
       elsif int_cnt = 20 and busy = '0' and Lock = '0' then
          Card_Select_i         <=  '1';
          SPI_data_i            <= Config & X"01";
 --         SPI_data_i            <= Config_Transition & X"00";
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 21 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 22 and busy = '0' and Lock = '0' then
          SPI_data_i            <= Config_Transition & X"00";
--          SPI_data_i            <= Config_1 & In_w_nPU;
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 23 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 24 and busy = '0' and Lock = '0' then
          SPI_data_i            <= Config_1 & In_w_nPU;
 --         SPI_data_i            <= Config_2 & In_w_nPU;
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 25 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 26 and busy = '0' and Lock = '0' then
          SPI_data_i            <= Config_2 & In_w_nPU;
 --         SPI_data_i            <= Config_3 & In_w_nPU;
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 27 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 28 and busy = '0' and Lock = '0' then
          SPI_data_i            <= Config_3 & In_w_nPU;
    --      SPI_data_i            <= Config_4 & In_w_nPU;
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 29 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 30 and busy = '0' and Lock = '0' then
          SPI_data_i            <= Config_4 & In_w_nPU;
 --         SPI_data_i            <= Config_5 & In_w_nPU;
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 31 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt      := int_cnt + 1;
          else
             Delay_cnt    := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 32 and busy = '0' and Lock = '0' then
          SPI_data_i            <= Config_5 & In_w_nPU;
--          SPI_data_i            <= Config_6 & In_w_nPU;
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 33 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 34 and busy = '0' and Lock = '0' then
          SPI_data_i            <= Config_6 & In_w_nPU;
 --         SPI_data_i            <= Config_7 & In_w_nPU;
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 35 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;


       elsif int_cnt = 36 and busy = '0' and Lock = '0' then         
          SPI_data_i            <= Config_7 & In_w_nPU;
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 37 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;


        elsif int_cnt = 38 and busy = '0' and Lock = '0' then         
          SPI_data_i            <= X"00" & X"00";
          Input_Data_Ready_i    <= '1';
          int_cnt               := int_cnt + 1;
          lock                  <= '1';
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 39 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;         
-------------------------------------------------------------------------------
-- Raed Card 1
-------------------------------------------------------------------------------          
       elsif int_cnt = 40 then  
             int_cnt            := int_cnt + 1;             
             Input_Ready        <= '0';
             
       elsif int_cnt = 41 then                      
             wait_cnt           := 5;
             if Trigger  = '1' then
              --  int_cnt := 0;
                int_cnt         := int_cnt + 1;
             end if;
             
       elsif int_cnt = 42 and busy = '0' and Lock = '0' then
          Card_Select_i         <=  '0';
          SPI_data_i            <= X"C4" & X"00";
          Input_Data_Ready_i    <= '1';
          lock                  <= '1'; 
          int_cnt               := int_cnt + 1;
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 43 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
                   
       elsif int_cnt = 44 and busy = '0' and Lock = '0' then
          SPI_data_i            <= X"CC" & X"00";
          Input_Data_Ready_i    <= '1';
          lock                  <= '1';
          int_cnt               := int_cnt + 1;
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 45 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;          
          
       elsif int_cnt = 46 and busy = '0' and Lock = '0' then
          SPI_data_i            <= X"D4" & X"00";
          SPI_Inport_1          <= SPI_data_o(7 downto 0);  --C4
          Input_Data_Ready_i    <= '1';
          lock                  <= '1';
          int_cnt               := int_cnt + 1;
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 47 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 48 and busy = '0' and Lock = '0' then
          SPI_data_i            <= X"DC" & X"00";
          SPI_Inport_2          <= SPI_data_o(7 downto 0);  --CC
          Input_Data_Ready_i    <= '1';
          lock                  <= '1';
          int_cnt               := int_cnt + 1;
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 49 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 50 and busy = '0' and Lock = '0' then
          SPI_data_i            <= X"00" & X"00";
          SPI_Inport_3          <= SPI_data_o(7 downto 0);  --D4
          Input_Data_Ready_i    <= '1';
          lock                  <= '1';
          int_cnt               := int_cnt + 1;
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 51 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then             
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;         

-- Raed Card 2
            
       elsif int_cnt = 52 and busy = '0' and Lock = '0' then
          Card_Select_i         <=  '1';
          SPI_data_i            <= X"C4" & X"00";
          SPI_Inport_4          <= SPI_data_o(7 downto 0);  --DC
          Input_Data_Ready_i    <= '1';
          lock                  <= '1';
          int_cnt               := int_cnt + 1;
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 53 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
            int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 54 and busy = '0' and Lock = '0' then
          SPI_data_i            <= X"CC" & X"00";
          Input_Data_Ready_i    <= '1';
          lock                  <= '1';
          int_cnt               := int_cnt + 1;
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 55 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 56 and busy = '0' and Lock = '0' then
          SPI_data_i            <= X"D4" & X"00";
          SPI_Inport_5          <= SPI_data_o(7 downto 0);  --C4
          Input_Data_Ready_i    <= '1';
          lock                  <= '1';
          int_cnt               := int_cnt + 1;
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 57 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 58 and busy = '0' and Lock = '0' then
          SPI_data_i            <= X"DC" & X"00";
          SPI_Inport_6          <= SPI_data_o(7 downto 0);  --CC
          Input_Data_Ready_i    <= '1';
          lock                  <= '1';
          int_cnt               := int_cnt + 1;
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 59 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 60 and busy = '0' and Lock = '0' then
          SPI_data_i            <= X"00" & X"00";
          SPI_Inport_7          <= SPI_data_o(7 downto 0);  --D4
          Input_Data_Ready_i    <= '1';
          lock                  <= '1';
          int_cnt               := int_cnt + 1;
          wait_cnt              := 5;
          Delay_cnt             := 0;
          
       elsif int_cnt = 61 and busy = '0' and Lock = '0' then          
          if Delay_cnt = 500 then
             int_cnt            := int_cnt + 1;
          else
             Delay_cnt          := Delay_cnt + 1;
          end if;
          
       elsif int_cnt = 62 and busy = '0' and Lock = '0' then          
          SPI_Inport_8          <= SPI_data_o(7 downto 0);  --DC
          Delay_cnt             := 0;
	  Input_Ready           <= '1';
          int_cnt               := 40;
          
       else
        Input_Data_Ready_i <= '0';
        if wait_cnt = 0 then
           lock  <= '0';
        else
           wait_cnt := wait_cnt - 1;
        end if;      
        
       end if;      
      end if;
          
    end process SPI_Initialization;
      
  end Arch_DUT;

