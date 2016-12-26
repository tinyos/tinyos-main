
ifdef SLAVE
$(info building SLAVE)
PROG_NAME    = slave
SLAVE_FLAG   = -DSLAVE
else
$(info building MASTER)
PROG_NAME    = master
SLAVE_FLAG   =
endif

DEVICE      ?= MSP432P401R
TI_ARM_ROOT  = /opt/ti-arm
TOS_ROOT     = $(TINYOS_ROOT_DIR)
PLATFORM_DIR = $(TOS_ROOT)/tos/platforms/exp_msp432
CHIP_ROOT    = $(TOS_ROOT)/tos/chips/msp432

# DLIB_ROM    = -D__MSP432_DVRLIB_ROM__
# LIBS       += $(TI_ARM_ROOT)/driverlib/MSP432P4xx/gcc/msp432p4xx_driverlib.a

TARGET      = $(PROG_NAME)
BIN_NAME    = $(PROG_NAME).bin
SYM_NAME    = $(PROG_NAME).sym
LST_NAME    = $(PROG_NAME).lst
MAP_NAME    = $(PROG_NAME).map
LDS_NAME    = $(CHIP_ROOT)/other/msp432p401r.lds

OTHER_OBJS = cpu.o dma.o gpio.o interrupt.o spi.o sysctl.o wdt_a.o

PREFIX  = arm-none-eabi
CC      = $(PREFIX)-gcc
OBJCOPY = $(PREFIX)-objcopy
OBJDUMP = $(PREFIX)-objdump
SIZE    = $(PREFIX)-size
NM      = $(PREFIX)-nm

ifdef V
VB = -v
LD_TR = -t
$(info *** Verbose ($(VB) $(LD_TR)))
endif

# might need -funwind-tables    see https://wiki.linaro.org/KenWerner/Sandbox/libunwind?action=AttachFile&do=get&target=libunwind-LDS.pdf
#     libunwind

VPATH += $(CHIP_ROOT)/driverlib

INCS += -I.
#INCS += -I$(TI_ARM_ROOT)/arm/include
#INCS += -I$(TI_ARM_ROOT)/arm/include/CMSIS
#INCS += -I$(TI_ARM_ROOT)/driverlib/MSP432P4xx
INCS += -I$(CHIP_ROOT)/driverlib

INCS += -I$(CHIP_ROOT)/dma
INCS += -I$(CHIP_ROOT)/usci
INCS += -I$(CHIP_ROOT)/include
INCS += -I$(CHIP_ROOT)/../cortex

ARCH        = -mcpu=cortex-m4  -march=armv7e-m -mthumb
FLOAT       = -mfloat-abi=hard -mfpu=fpv4-sp-d16
DEV_FLAGS   = -D__$(DEVICE)__ $(DLIB_ROM)
GCC_FLAGS   = -Dgcc -Wall -Os
DEBUG_FLAGS = -g -ggdb
LIBS       += -lc -lgcc -lnosys -lm

#LD_ADDS   += -Wl,-Map=$(MAP_NAME) -Wl,--cref
LD_ADDS    += -Wl,-Map=$(MAP_NAME)
LD_ADDS    += -Wl,--gc-sections

# --specs=nano.specs
CFLAGS  = --specs=nano.specs -nostartfiles $(ARCH) $(FLOAT) $(DEV_FLAGS) $(GCC_FLAGS) $(DEBUG_FLAGS)
LDFLAGS = -T$(LDS_NAME) $(LD_ADDS) $(CFLAGS) $(LIBS)

OBJS    = $(PROG_NAME).o startup.o $(OTHER_OBJS)

#all: .bytes $(LST_NAME) $(BIN_NAME) $(SYM_NAME)
all: .bytes $(LST_NAME) $(SYM_NAME)

.PHONY: printvars
printvars:
	@$(foreach X,$(sort $(.VARIABLES)),		  \
	$(if						  \
	     $(filter-out environment% default automatic, $(origin $X)), \
	 $(info $X=$($X)  <$(origin $X)>  <$(value $X)>)))

print-%: ; @echo $* = $($*)

%.o: %.c
	$(CC) $(VB) $(INCS) $(CFLAGS) -c $< -o $@

slave.o: master.c
	$(CC) $(VB) $(SLAVE_FLAG) $(INCS) $(CFLAGS) -c $< -o $@

startup.o: $(PLATFORM_DIR)/startup.c
	$(CC) $(VB) $(INCS) $(CFLAGS) -c $< -o $@

symbols_hw: $(PLATFORM_DIR)/symbols_hw.c
	$(CC) $(VB) $(INCS) $(CFLAGS) -c $< -o $@

$(TARGET): $(OBJS) symbols_hw
	$(CC) $(VB) $(LD_TR) $(LDFLAGS) $(OBJS) -o $@

.bytes: $(TARGET)
	$(SIZE) $(TARGET) | tee .bytes

#$(BIN_NAME): $(TARGET)
#	$(OBJCOPY) --output-target=binary $(TARGET) $(BIN_NAME)

$(LST_NAME): $(TARGET)
	$(OBJDUMP) -d --source -w $(TARGET) > $(LST_NAME)

$(SYM_NAME): $(TARGET)
	$(NM) -an $(TARGET) > $(SYM_NAME)

clean:
	-rm -f .bytes *.o *.map *.lst *.sym master slave symbols_hw
