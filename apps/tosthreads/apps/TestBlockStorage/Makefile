COMPONENT=TestBlockStorageAppC

ifneq ($(filter telosb,$(MAKECMDGOALS)),)
  CFLAGS+=-DUSE_STM25P
endif
ifneq ($(filter micaz iris,$(MAKECMDGOALS)),)
  CFLAGS+=-DUSE_AT45DB
endif

include $(MAKERULES)
