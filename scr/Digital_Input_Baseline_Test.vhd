-------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
-- This file contains  modules which make up a testbench
-- suitable for testing the "device under test".
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
--library modelsim_lib;
--use modelsim_lib.util.all;

entity Digital_Input_Baseline_Test is 

--end ASC_Testcode;

  port (

----------------------------Clock Input  ---------------------------------
    CLOCK_50     : in    std_logic;                      --      50 MHz
----------------------------Push Button  ---------------------------------
    KEY          : in    std_logic_vector(1 downto 0);   --      Pushbutton[1:0]
----------------------------DPDT Switch  ---------------------------------
    SW           : in    std_logic_vector(3 downto 0);   --      Toggle Switch[3:0]
---------------------------------LED    ------------------------------------
    LED          : out   std_logic_vector(7 downto 0);   --      LED [7:0]
------------------------------SDRAM Interface  ---------------------------
    DRAM_DQ      : inout std_logic_vector(15 downto 0);  --      SDRAM Data bus 16 Bits
    DRAM_DQM     : out   std_logic_vector(1 downto 0);   --      SDRAM Data bus 2 Bits
    DRAM_ADDR    : out   std_logic_vector(12 downto 0);  --      SDRAM Address bus 13 Bits
    DRAM_WE_N    : out   std_logic;                      --      SDRAM Write Enable
    DRAM_CAS_N   : out   std_logic;                      --      SDRAM Column Address Strobe
    DRAM_RAS_N   : out   std_logic;                      --      SDRAM Row Address Strobe
    DRAM_CS_N    : out   std_logic;                      --      SDRAM Chip Select
    DRAM_BA      : out   std_logic_vector(1 downto 0);   --      SDRAM Bank Address 0
    DRAM_CLK     : out   std_logic;                      --      SDRAM Clock
    DRAM_CKE     : out   std_logic;                      --      SDRAM Clock Enable
-------------------------------EPCS------------------------------------   
--     EPCS_ASDO    : out   std_logic;
--     EPCS_DATA0   : in    std_logic;  
--     EPCS_DCLK    : out   std_logic;  
--     EPCS_NCSO    : out   std_logic;
---------------------------------Accelerometer and EEPROM----------------
    G_SENSOR_CS_N : out     std_logic;  
    G_SENSOR_INT  : in      std_logic;  
    I2C_SCLK      : out     std_logic;
    I2C_SDAT      : inout   std_logic;  
-----------------------ADC--------------------------------------------------------
    ADC_CS_N      : out     std_logic;   
    ADC_SADDR     : out     std_logic;
    ADC_SCLK      : out     std_logic; 
    ADC_SDAT      : in      std_logic;
--------------------------------2x13 GPIO Header-----------------------------------------------
--     GPIO_2            : inout   std_logic_vector(12 downto 0);
--     GPIO_2_IN         : in      std_logic_vector(2 downto 0);
-------------------------------GPIO_0, GPIO_0 connect to GPIO Default-----------------------
    GPIO_0            : inout   std_logic_vector(33 downto 0);
    GPIO_0_IN         : in      std_logic_vector(1 downto 0);
--------------------------GPIO_1, GPIO_1 connect to GPIO Default--------------------------
    GPIO_1            : inout   std_logic_vector(33 downto 0);
    GPIO_1_IN         : in      std_logic_vector(1 downto 0)
    );
  
end Digital_Input_Baseline_Test;

architecture Arch_DUT of Digital_Input_Baseline_Test is
  


--Switch Signals
  signal Switch_Status_L_i        : std_logic_vector(7 downto 0);
-- Push Button Internal Signals
  signal Key_1_i                  : std_logic;
  signal Key_2_i                  : std_logic;
  
-- Switch Internal Signals
  signal SW_1_i                   : std_logic;
  signal SW_2_i                   : std_logic;
  signal SW_3_i                   : std_logic;
  signal SW_4_i                   : std_logic;
  
-- LED internal Signals
  signal LED1_i                   : std_logic;
  signal LED2_i                   : std_logic;
  signal LED3_i                   : std_logic;
  signal LED4_i                   : std_logic;
  signal LED5_i                   : std_logic;
  signal LED6_i                   : std_logic;
  signal LED7_i                   : std_logic;
  signal LED8_i                   : std_logic;

-- General Signals
signal RST_I_i                          : std_logic; 
signal CLK_I_i                          : STD_LOGIC;
signal One_uS_i                         : STD_LOGIC;     
signal One_mS_i                         : STD_LOGIC;              
signal Ten_mS_i                         : STD_LOGIC;
signal Twenty_mS_i                      : STD_LOGIC;             
signal Hunder_mS_i                      : STD_LOGIC;
signal UART_locked_i                    : STD_LOGIC;
signal One_Sec_i                        : STD_LOGIC;
signal Two_ms_i                         : STD_LOGIC;

----------------------------------------------------------------------
-- Input Card Driver Component
----------------------------------------------------------------------  


    component SPI_In_Output is
    port (
      RST_I          : in  std_logic;
      CLK_I          : in  std_logic;
      nCS_Output_1   : out std_logic;
      nCS_Output_2   : out std_logic;
      Sclk           : out std_logic;
      Mosi           : out std_logic;
      Miso           : in  std_logic;
      Card_Select    : in  std_logic;
      Data_In_Ready  : in  std_logic;
      SPI_Outport    : in  std_logic_vector(15 downto 0);
      Data_Out_Ready : out std_logic;
      SPI_Inport     : out std_logic_vector(15 downto 0);
      Busy           : out std_logic
      );
  end component SPI_In_Output;

----------------------------------------------------------------------
-- Input Card Handler Component
----------------------------------------------------------------------  
  component SPI_Input is
    port (
      RST_I             : in  std_logic;
      CLK_I             : in  std_logic;
      Int_1             : in  std_logic;
      Int_2             : in  std_logic;
      SPI_Inport_1      : out std_logic_vector(7 downto 0);
      SPI_Inport_2      : out std_logic_vector(7 downto 0);
      SPI_Inport_3      : out std_logic_vector(7 downto 0);
      SPI_Inport_4      : out std_logic_vector(7 downto 0);
      SPI_Inport_5      : out std_logic_vector(7 downto 0);
      SPI_Inport_6      : out std_logic_vector(7 downto 0);
      SPI_Inport_7      : out std_logic_vector(7 downto 0);
      SPI_Inport_8      : out std_logic_vector(7 downto 0);
      Input_Ready       : out std_logic;
      SPI_Data_out      : out std_logic_vector(15 downto 0);
      Input_Data_ready  : out std_logic;
      Input_Card_Select : out std_logic;
      SPI_Data_in       : in  std_logic_vector(15 downto 0);
      busy              : in  std_logic;
      Sample_Rate       : in  integer range 0 to 1000;
      One_mS_pulse      : in  std_logic
      );
  end component SPI_Input;  

-- General Signals
  signal sClk,snrst,sStrobe,PWM_sStrobe,newClk,Clk : std_logic := '0';
  signal OneuS_sStrobe, Quad_CHA_sStrobe, Quad_CHB_sStrobe,OnemS_sStrobe : std_logic;
  signal One_mS_pulse_i         : std_logic;
  signal Lock_i                 : STD_LOGIC;

 
----------------------------------------------------------------------
 --Input Card Driver Signals
----------------------------------------------------------------------
  signal nCS_Output_1_i    : std_logic;
  signal nCS_Output_2_i    : std_logic;
  signal Sclk_i            : std_logic;
  signal Mosi_i            : std_logic;
  signal Miso_i            : std_logic;
  signal Card_Select_i     : std_logic;
  signal Data_In_Ready_i   : std_logic;
  signal SPI_Outport_i     : std_logic_vector(15 downto 0);
  signal Data_Out_Ready_i  : std_logic;
  signal SPI_Inport_i      : std_logic_vector(15 downto 0);

----------------------------------------------------------------------
 --Input Card Handler Signals
----------------------------------------------------------------------
  signal Int_1_i              : std_logic;
  signal Int_2_i              : std_logic;
  signal SPI_Inport_1_i       : std_logic_vector(7 downto 0);
  signal SPI_Inport_2_i       : std_logic_vector(7 downto 0);
  signal SPI_Inport_3_i       : std_logic_vector(7 downto 0);
  signal SPI_Inport_4_i       : std_logic_vector(7 downto 0);
  signal SPI_Inport_5_i       : std_logic_vector(7 downto 0);
  signal SPI_Inport_6_i       : std_logic_vector(7 downto 0);
  signal SPI_Inport_7_i       : std_logic_vector(7 downto 0);
  signal SPI_Inport_8_i       : std_logic_vector(7 downto 0);
  signal Input_Ready_i        : std_logic;
  signal SPI_Data_out_i       : std_logic_vector(15 downto 0);
  signal Input_Data_ready_i   : std_logic;
  signal Input_Card_Select_i  : std_logic;
  signal SPI_Data_in_i        : std_logic_vector(15 downto 0);
  signal busy_i               : std_logic;
  signal Sample_Rate_i        : integer range 0 to 1000;

-- ------------------------------------------------------------------------------                                             
  Begin
-- Wire link
       CLK_I_i        <= CLOCK_50;
       Sample_Rate_i  <= 100;

--MAX7301 Output -------------------------------------------------------------
       
       -- Pre Test Mapping
       GPIO_0(0)          <= nCS_Output_1_i; 
       Miso_i             <= GPIO_0(1);
       GPIO_0(3)          <= Mosi_i; 
       GPIO_0(5)          <= Sclk_i;   
       GPIO_0(7)          <= nCS_Output_2_i;         

       --Signal Redirect-------------------------------------------------------		 
       GPIO_1(3)          <= Sclk_i;
       GPIO_1(0)          <= Mosi_i;
       GPIO_1(7)     	  <= Miso_i;	
       GPIO_1(10)         <= nCS_Output_1_i;            
       GPIO_1(11)         <= nCS_Output_2_i; 

--------------------------------------------------------------------------

       -- Input Driver
       SPI_In_Output_1: entity work.SPI_In_Output
         port map (
           RST_I          => RST_I_i,
           CLK_I          => CLK_I_i,
           nCS_Output_1   => nCS_Output_1_i,
           nCS_Output_2   => nCS_Output_2_i,
           Sclk           => Sclk_i,
           Mosi           => Mosi_i,
           Miso           => Miso_i,
           Card_Select    => Input_Card_Select_i,
           Data_In_Ready  => Input_Data_ready_i,
           SPI_Outport    => SPI_Data_out_i,
           Data_Out_Ready => Data_Out_Ready_i,
           SPI_Inport     => SPI_Inport_i,
           Busy           => busy_i
           );


       -- Input Handler
      
       SPI_Input_1: entity work.SPI_Input
         port map (
           RST_I             => RST_I_i,
           CLK_I             => CLK_I_i,
           Int_1             => Int_1_i,
           Int_2             => Int_2_i,
           SPI_Inport_1      => SPI_Inport_1_i,
           SPI_Inport_2      => SPI_Inport_2_i,
           SPI_Inport_3      => SPI_Inport_3_i,
           SPI_Inport_4      => SPI_Inport_4_i,
           SPI_Inport_5      => SPI_Inport_5_i,
           SPI_Inport_6      => SPI_Inport_6_i,
           SPI_Inport_7      => SPI_Inport_7_i,
           SPI_Inport_8      => SPI_Inport_8_i,
           Input_Ready       => Input_Ready_i,
           SPI_Data_out      => SPI_Data_out_i,
           Input_Data_ready  => Input_Data_ready_i,
           Input_Card_Select => Input_Card_Select_i,
           SPI_Data_in       => SPI_Inport_i,
           busy              => busy_i,
           Sample_Rate       => Sample_Rate_i,
           One_mS_pulse      => One_mS_i
           );
  
-------------------------------------------------------------------------------
-- Test code only
-------------------------------------------------------------------------------       
sw_input: process(RST_I_i,CLOCK_50)

  begin
    if RST_I_i = '0' then
       LED                 <= (others => '0');
		 --Input_Card_Select_i <= '0';
    elsif CLOCK_50'event and CLOCK_50 = '1' then
-- Default - Activate Both Cards
-- Selcet Card1     
-- Select Card2

         if SW(2) = '0' then
        --    Input_Card_Select_i <= '0';                     -- Select Card1 
--                                                      -- Disable Card2
            if SW(0) = '0' and SW(1) = '0' then
               LED <= SPI_Inport_1_i; 
            elsif SW(0) = '1' and SW(1) = '0' then
               LED <= SPI_Inport_2_i; 
            elsif SW(0) = '0' and SW(1) = '1' then
               LED <= SPI_Inport_3_i; 
            elsif SW(0) = '1' and SW(1) = '1' then
               LED <= b"0000000" & SPI_Inport_4_i(0);
            end if;   
         else
        --      Input_Card_Select_i <= '1';                       -- Disable Card1                                         -- Select Card2
             if SW(0) = '0' and SW(1) = '0' then
                LED <= SPI_Inport_5_i; 
             elsif SW(0) = '1' and SW(1) = '0' then
                LED <= SPI_Inport_6_i; 
             elsif SW(0) = '0' and SW(1) = '1' then
                LED <= SPI_Inport_7_i; 
             elsif SW(0) = '1' and SW(1) = '1' then
                LED <= b"0000000" & SPI_Inport_8_i(0);
             end if;    
         end if;  
--         
    end if;
  end process sw_input;
  
-------------------------------------------------------------------------------
-- Timing generator
-------------------------------------------------------------------------------
 Time_Trigger: process(RST_I_i,CLOCK_50)
    variable bit_cnt_OuS       : integer range 0 to 100;
    variable bit_cnt_OmS       : integer range 0 to 60000;
    variable bit_cnt_TmS       : integer range 0 to 600000;
    variable bit_cnt_20mS      : integer range 0 to 2000000;       
    variable bit_cnt_HmS       : integer range 0 to 6000000;
    variable Sec_Cnt           : integer range 0 to 11;
    variable Two_ms_cnt        : integer range 0 to 3;
    begin
      if RST_I_i = '0' then
         bit_cnt_OuS       := 0;
         bit_cnt_OmS       := 0;
         bit_cnt_TmS       := 0;         
         bit_cnt_HmS       := 0;
         bit_cnt_20mS      := 0;          
         One_uS_i          <= '0';
         One_mS_i          <= '0';        
         Ten_mS_i          <= '0';
         Twenty_mS_i       <= '0';
         Hunder_mS_i       <= '0';
         One_Sec_i         <= '0';
      elsif CLOCK_50'event and CLOCK_50 = '1' then       
--1uS
            if bit_cnt_OuS = 50 then
               One_uS_i         <= '1';
               bit_cnt_OuS      := 0;                      
            else
               One_uS_i        <= '0';
               bit_cnt_OuS      := bit_cnt_OuS + 1;
            end if;
--1mS            
            if bit_cnt_OmS = 50000 then
               One_mS_i         <= '1';                 
               bit_cnt_OmS      := 0;
               Two_ms_cnt       := Two_ms_cnt + 1;
            else
               One_mS_i   <= '0';
               bit_cnt_OmS      := bit_cnt_OmS + 1;
            end if;
-- 2 ms
            if Two_ms_cnt = 2 then
               Two_ms_i     <= '1';
               Two_ms_cnt   := 0;
            else
               Two_ms_i      <= '0';
            end if;   
            
            if bit_cnt_TmS = 500000 then
               Ten_mS_i   <= '1';
               bit_cnt_TmS      := 0;                      
            else
               Ten_mS_i   <= '0';
               bit_cnt_TmS      := bit_cnt_TmS + 1;
            end if;

-- 20mS         
            if bit_cnt_20mS = 1000000 then
               Twenty_mS_i   <= '1';
               bit_cnt_20mS  := 0;                      
            else
               Twenty_mS_i   <= '0';
               bit_cnt_20mS  := bit_cnt_20mS + 1;
            end if;            
            
--100Ms
            if bit_cnt_HmS = 5000000 then
               Hunder_mS_i      <= '1';                  
               bit_cnt_HmS      := 0;
               Sec_Cnt          := Sec_Cnt + 1;
            else
               Hunder_mS_i      <= '0';
               bit_cnt_HmS      := bit_cnt_HmS + 1;
            end if;

-- 1 sec
            if Sec_Cnt = 10 then
               One_Sec_i <= '1';
               Sec_Cnt   := 0;
            else
              One_Sec_i  <= '0';
            end if;  
      end if;
 end process Time_Trigger;

-------------------------------------------------------------------------------
-- Reset generator
-------------------------------------------------------------------------------       


  Reset_gen : process(CLOCK_50)
          variable cnt : integer range 0 to 255;
        begin
          if (CLOCK_50'event) and (CLOCK_50 = '1') then


            if cnt = 255 then
               RST_I_i <= '1';
            else
               cnt := cnt + 1;
               RST_I_i <= '0';
             end if;
          end if;
        end process Reset_gen; 

  end Arch_DUT;

