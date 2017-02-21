#######################################################################
# Makefile for STM32F767 NUCLEO144 board projects

PROJECT = blinky
CMSIS_PATH = ~/programming/microcontroller/stm32/ARM/STM32Cube_FW_F7_V1.6.0
OPENOCD_SCRIPT_DIR=/usr/share/openocd/scripts

################
# Sources

SOURCES_S = ${CMSIS_PATH}/Drivers/CMSIS/Device/ST/STM32F7xx/Source/Templates/gcc/startup_stm32f767xx.s

SOURCES_C = src/main.c

SOURCES_C += sys/stubs.c sys/_sbrk.c sys/_io.c
SOURCES_C += ${CMSIS_PATH}/Drivers/CMSIS/Device/ST/STM32F7xx/Source/Templates/system_stm32f7xx.c
SOURCES_C += ${CMSIS_PATH}/Drivers/BSP/STM32F7xx_Nucleo_144/stm32f7xx_nucleo_144.c
SOURCES_C += ${CMSIS_PATH}/Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_gpio.c

SOURCES_CPP =

SOURCES = $(SOURCES_S) $(SOURCES_C) $(SOURCES_CPP)
OBJS = $(SOURCES_S:.s=.o) $(SOURCES_C:.c=.o) $(SOURCES_CPP:.cpp=.o)

################
# Includes and Defines

INCLUDES += -I src
INCLUDES += -I ${CMSIS_PATH}/Drivers/CMSIS/Include
INCLUDES += -I ${CMSIS_PATH}/Drivers/CMSIS/Device/ST/STM32F7xx/Include
INCLUDES += -I ${CMSIS_PATH}/Drivers/STM32F7xx_HAL_Driver/Inc
INCLUDES += -I ${CMSIS_PATH}/Drivers/BSP/STM32F7xx_Nucleo_144

DEFINES = -DSTM32 -DSTM32F7 -DSTM32F767xx

################
# Compiler/Assembler/Linker/etc

PREFIX = arm-none-eabi

CC = $(PREFIX)-gcc
AS = $(PREFIX)-as
AR = $(PREFIX)-ar
LD = $(PREFIX)-gcc
NM = $(PREFIX)-nm
OBJCOPY = $(PREFIX)-objcopy
OBJDUMP = $(PREFIX)-objdump
READELF = $(PREFIX)-readelf
SIZE = $(PREFIX)-size
GDB = $(PREFIX)-gdb
RM = rm -f
OPENOCD=openocd

################
# Compiler options

MCUFLAGS = -mcpu=cortex-m7 -mlittle-endian
MCUFLAGS += -mfloat-abi=hard -mfpu=fpv5-sp-d16
MCUFLAGS += -mthumb

DEBUGFLAGS = -O0 -g -gdwarf-2
#DEBUGFLAGS = -O2

CFLAGS = -std=c11
CFLAGS += -Wall -Wextra --pedantic
# generate listing files
CFLAGS += -Wa,-aghlms=$(<:%.c=%.lst)

CFLAGS_EXTRA = -nostartfiles -nodefaultlibs -nostdlib
CFLAGS_EXTRA += -fdata-sections -ffunction-sections

CFLAGS += $(DEFINES) $(MCUFLAGS) $(DEBUG_FLAGS) $(CFLAGS_EXTRA) $(INCLUDES)

LDFLAGS = -static $(MCUFLAGS)
LDFLAGS += -Wl,--start-group -lgcc -lm -lc -lg -lstdc++ -lsupc++ -Wl,--end-group
LDFLAGS += -Wl,--gc-sections -Wl,--print-gc-sections -Wl,--cref,-Map=$(@:%.elf=%.map)
LDFLAGS += -L ${CMSIS_PATH}/Projects/STM32F767ZI-Nucleo/Demonstrations/SW4STM32/STM32767ZI_Nucleo/ -T STM32F767ZITx_FLASH.ld

################
# phony rules

.PHONY: all clean flash erase

all: $(PROJECT).bin $(PROJECT).hex $(PROJECT).asm

clean:
	$(RM) $(OBJS) $(OBJS:$.o=$.lst) $(PROJECT).elf $(PROJECT).bin $(PROJECT).hex $(PROJECT).map $(PROJECT).asm

flash: $(PROJECT).bin
	st-flash write $(PROJECT).bin 0x08000000

erase:
	st-flash erase

GDB_PORT:=4242
gdb-server:
	# st-util will listen on port :4242
	st-util
	# openocd will listen on port :3333
	#$(OPENOCD) -f $(OPENOCD_SCRIPT_DIR)/interface/stlink-v2-1.cfg -f $(OPENOCD_SCRIPT_DIR)/target/stm32f7x.cfg

gdb: $(PROJECT).elf
	$(GDB) --eval-command="target remote localhost:$(GDB_PORT)" --eval-command="monitor halt" $(PROJECT).elf

################
# dependency graphs for wildcard rules

$(PROJECT).elf: $(OBJS)

################
# wildcard rules

%.elf:
	$(LD) $(OBJS) $(LDFLAGS) -o $@
	$(SIZE) -A $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%.hex: %.elf
	$(OBJCOPY) -O ihex $< $@

%.asm: %.elf
	$(OBJDUMP) -dgCxw $< > $@

# EOF