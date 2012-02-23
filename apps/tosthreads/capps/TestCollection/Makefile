TOSTHREAD_MAIN=TestCollection.c

CFLAGS += -I$(TOSDIR)/lib/tosthreads/sensorboards/universal

CFLAGS += -I$(TOSDIR)/lib/tosthreads/lib/net/
CFLAGS += -I$(TOSDIR)/lib/net/

CFLAGS += -I$(TOSDIR)/lib/tosthreads/lib/net/ctp
CFLAGS += -I$(TOSDIR)/lib/net/ctp  -I$(TOSDIR)/lib/net/4bitle

ifneq ($(filter telosb tmote tinynode shimmer shimmer2 shimmer2r span iris epic clean,$(MAKECMDGOALS)),) 
  include $(MAKERULES)
else
%:
	@echo "    Sorry, this application only works on platforms with >8kB of RAM (telos, iris, etc.)"
cthreads:
	@:
dynthreads:
	@:
endif

