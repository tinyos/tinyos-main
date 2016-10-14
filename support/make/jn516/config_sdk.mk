#-*-Makefile-*- vim:syntax=make

NXP_MAKE_BASE_DIR = $(JENNIC_SDK_DIR) # needed?
SDK_BASE_DIR = $(JENNIC_SDK_DIR)

#use tinyos linker script (modifies start vectors), instead of standard jennic
TOS_COMPILE = TRUE

include $(JENNIC_SDK_DIR)/Chip/Common/Build/config.mk
include $(JENNIC_SDK_DIR)/Platform/Common/Build/config.mk
include $(JENNIC_SDK_DIR)/Stack/Common/Build/config.mk

#$(info >> CFLAGS >> $(CFLAGS))
#$(info >> INCFLAGS >> $(INCFLAGS))
#$(info >> PFLAGS >> $(PFLAGS))
#$(info >> LDFLAGS >> $(LDFLAGS))
#$(info >> LDLIBS >> $(LDLIBS))
#$(info ...)

CFLAGS += -Ubool -Wno-packed

#radio includes
APPLIBS += MMAC
#INCFLAGS += -I$(COMPONENTS_BASE_DIR)/MAC/Include
PFLAGS += -I$(TINYOS_ROOT_DIR)/support/make/jn516/include
PFLAGS += $(INCFLAGS)
PFLAGS += -DTOS_BUILD

#endian: jn516x is big endian
#CFLAGS += -D__BYTE_ORDER__=4321

#MicroSpecific
#CFLAGS += -DEMBEDDED -DUSER_VSR_HANDLER

LDLIBS := $(addsuffix _$(JENNIC_CHIP_FAMILY),$(APPLIBS)) $(LDLIBS)

#$(info >> CFLAGS >> $(CFLAGS))
#$(info >> PFLAGS >> $(PFLAGS))
#$(info >> LDFLAGS >> $(LDFLAGS))
#$(info >> LDLIBS >> $(LDLIBS))
#$(info ...)

#LINKCMD = link_JN5168.ld
#LOPTS = -Wl,--gc-sections -Wl,-u_main -L$(TINYOS_ROOT_DIR)/support/make/jn516/linkscripts/old $(LDFLAGS) -T$(LINKCMD) -Wl,--start-group  $(addprefix -l,$(LDLIBS)) -Wl,--end-group -Wl,-Map,$(MAIN_MAP)
LOPTS = -Wl,--gc-sections -Wl,-u_main -L$(TINYOS_ROOT_DIR)/support/make/jn516/linkscripts $(LDFLAGS) -T$(LINKCMD) -Wl,--start-group  $(addprefix -l,$(LDLIBS)) -Wl,--end-group -Wl,-Map,$(MAIN_MAP)

LDFLAGS := $(LOPTS)
#LDFLAGS += -T$(LINKCMD) $(addprefix -l,$(LDLIBS)) -Wl,-Map,$(MAIN_MAP)

#$(info >> LDFLAGS >> $(LDFLAGS))
#$(info ...)
#$(error stopping...)

# using custom exception handlers
TOSMAKE_ADDITIONAL_INPUTS+=$(TINYOS_ROOT_DIR)/support/make/jn516/c/jn516_exception_handlers.c
TOSMAKE_ADDITIONAL_INPUTS+=$(TINYOS_ROOT_DIR)/support/make/jn516/c/jn516_startup.c

# adapting output of the sdk makefiles
PFLAGS += -I$(COMPONENTS_BASE_DIR)/MicroSpecific/Include
PFLAGS := $(subst -gcc= , , $(PFLAGS))
PFLAGS := $(subst -I$(COMPONENTS_BASE_DIR)/AppApi/Include, , $(PFLAGS))
PFLAGS := $(subst -I$(COMPONENTS_BASE_DIR)/MAC/Include, , $(PFLAGS))
PFLAGS := $(subst -I$(COMPONENTS_BASE_DIR)/Mac/Include, , $(PFLAGS))
PFLAGS := $(subst -I$(COMPONENTS_BASE_DIR)/TimerServer/Include, , $(PFLAGS))
PFLAGS := $(subst -I$(COMPONENTS_BASE_DIR)/Common/Include, , $(PFLAGS))
LDFLAGS := $(subst -flto, , $(LDFLAGS))
CFLAGS := $(subst -flto, , $(CFLAGS))
