-- #################################################################################################
-- # << NEORV32 - Example setup for the tinyVision.ai Inc. "UPduino v3" (c) Board >>               #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2021, Stephan Nolting. All rights reserved.                                     #
-- #                                                                                               #
-- # Redistribution and use in source and binary forms, with or without modification, are          #
-- # permitted provided that the following conditions are met:                                     #
-- #                                                                                               #
-- # 1. Redistributions of source code must retain the above copyright notice, this list of        #
-- #    conditions and the following disclaimer.                                                   #
-- #                                                                                               #
-- # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
-- #    conditions and the following disclaimer in the documentation and/or other materials        #
-- #    provided with the distribution.                                                            #
-- #                                                                                               #
-- # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
-- #    endorse or promote products derived from this software without specific prior written      #
-- #    permission.                                                                                #
-- #                                                                                               #
-- # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
-- # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
-- # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
-- # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
-- # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
-- # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
-- # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
-- # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
-- # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
-- # ********************************************************************************************* #
-- # The NEORV32 Processor - https://github.com/stnolting/neorv32              (c) Stephan Nolting #
-- #################################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library iCE40;
use iCE40.components.all; -- for device primitives and macros

library neorv32;
use neorv32.neorv32_package.all; -- for device primitives and macros

entity neorv32_hx8kevb_top is
  port (    
    clk_i_100mhz      : in  std_ulogic;  
    -- UART (uart0) --
    uart_txd_o : out std_ulogic;
    uart_rxd_i : in  std_ulogic;
    -- GPIO --
    led_o     : out std_ulogic_vector(1 downto 0)
  );
end entity;

architecture neorv32_hx8kevb_top_rtl of neorv32_hx8kevb_top is

  -- configuration --
  constant f_clock_c : natural := 100000000; -- PLL output clock frequency in Hz
  signal ext_rstn:  std_logic;
  -- internal IO connection --
  signal con_gpio : std_logic_vector(63 downto 0);
  
begin

  process(clk_i_100mhz) is
    variable cnt : unsigned(7 downto 0) := (others => '0');
    begin
      if rising_edge(clk_i_100mhz) then
        if cnt < 255 then
          cnt := cnt + 1;
          ext_rstn <= '0';
        else
          ext_rstn <= '1';
        end if;
      end if;
    end process;

  -- The core of the problem ----------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  neorv32_inst: neorv32_top
  generic map (
	CLOCK_FREQUENCY              => f_clock_c,      -- clock frequency of clk_i in Hz
    INT_BOOTLOADER_EN            => false,   -- boot configuration: true = boot explicit bootloader; false = boot from int/ext (I)MEM
    HW_THREAD_ID                 => 0,      -- hardware thread id (32-bit)

    -- RISC-V CPU Extensions --
    CPU_EXTENSION_RISCV_A        => false,   -- implement atomic extension?
    CPU_EXTENSION_RISCV_C        => false,   -- implement compressed extension?
    CPU_EXTENSION_RISCV_E        => false,  -- implement embedded RF extension?
    CPU_EXTENSION_RISCV_M        => false,   -- implement mul/div extension?
    CPU_EXTENSION_RISCV_U        => false,  -- implement user mode extension?
    CPU_EXTENSION_RISCV_Zfinx    => false,  -- implement 32-bit floating-point extension (using INT regs!)
    CPU_EXTENSION_RISCV_Zicsr    => true,   -- implement CSR system?
    CPU_EXTENSION_RISCV_Zifencei => false,  -- implement instruction stream sync.?

    -- Extension Options --
    FAST_MUL_EN                  => false,  -- use DSPs for M extension's multiplier
    FAST_SHIFT_EN                => false,  -- use barrel shifter for shift operations
    CPU_CNT_WIDTH                => 2,     -- total width of CPU cycle and instret counters (0..64) default: 34

    -- Physical Memory Protection (PMP) --
    PMP_NUM_REGIONS              => 0,       -- number of regions (0..64)
    PMP_MIN_GRANULARITY          => 8, -- minimal region granularity in bytes, has to be a power of 2, min 8 bytes, default: 64*1024

    -- Hardware Performance Monitors (HPM) --
    HPM_NUM_CNTS                 => 0,       -- number of implemented HPM counters (0..29)
    HPM_CNT_WIDTH                => 0,      -- total size of HPM counters (0..64) default: 40

    -- Internal Instruction memory --
    MEM_INT_IMEM_EN              => true,    -- implement processor-internal instruction memory
    MEM_INT_IMEM_SIZE            => 8*1024, -- size of processor-internal instruction memory in bytes

    -- Internal Data memory --
    MEM_INT_DMEM_EN              => true,    -- implement processor-internal data memory
    MEM_INT_DMEM_SIZE            => 2*1024, -- size of processor-internal data memory in bytes

    -- Internal Cache memory --
    ICACHE_EN                    => false,  -- implement instruction cache
    ICACHE_NUM_BLOCKS            => 4,      -- i-cache: number of blocks (min 1), has to be a power of 2
    ICACHE_BLOCK_SIZE            => 64,     -- i-cache: block size in bytes (min 4), has to be a power of 2
    ICACHE_ASSOCIATIVITY         => 1,      -- i-cache: associativity / number of sets (1=direct_mapped), has to be a power of 2

    -- Processor peripherals --
    IO_GPIO_EN                   => true,   -- implement general purpose input/output port unit (GPIO)?
    IO_MTIME_EN                  => true,   -- implement machine system timer (MTIME)?
    IO_UART0_EN                  => true,   -- implement primary universal asynchronous receiver/transmitter (UART0)?
    IO_PWM_NUM_CH                => 0,      -- number of PWM channels to implement (0..60); 0 = disabled
    IO_WDT_EN                    => true    -- implement watch dog timer (WDT)?
  )
  port map (
    -- Global control --
    clk_i      => std_ulogic(clk_i_100mhz),
    rstn_i     => std_ulogic(ext_rstn),

    -- GPIO --
    gpio_o     => con_gpio,

    -- primary UART --
    uart0_txd_o => uart_txd_o, -- UART0 send data
    uart0_rxd_i => uart_rxd_i, -- UART0 receive data
    uart0_rts_o => open, -- hw flow control: UART0.RX ready to receive ("RTR"), low-active, optional
    uart0_cts_i => '0'  -- hw flow control: UART0.TX allowed to transmit, low-active, optional

  );
  
  led_o <= con_gpio(4 downto 3);
    
end architecture;
