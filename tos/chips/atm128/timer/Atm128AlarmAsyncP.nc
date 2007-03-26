generic module Atm128AlarmAsyncP(typedef precision, int divider) {
  provides {
    interface Init;
    interface Alarm<precision, uint32_t>;
    interface Counter<precision, uint32_t>;
  }
  uses {
    interface HplAtm128Timer<uint8_t> as Timer;
    interface HplAtm128TimerCtrl8 as TimerCtrl;
    interface HplAtm128Compare<uint8_t> as Compare;
  }
}
implementation
{
  uint8_t set;
  uint32_t t0, dt;
  uint32_t base, lastNow;

  void oopsT0() {
  }

  void oopsNow() {
  }

  enum {
    MINDT = 10,
    MAXT = 230
  };

  void setOcr0(uint8_t n) {
    while (ASSR & 1 << OCR0UB)
      ;
    if (n == TCNT0)
      n++;
    OCR0 = n; 
  }

  void setInterrupt() {
    bool fired = FALSE;

    atomic
      {
	uint8_t interrupt_in = 1 + call Compare.get() - call Timer.get();
	uint8_t newOcr0;

	if (interrupt_in < MINDT || (call TimerCtrl.getInterruptFlag()).bits.ocf0)
	  return; // wait for next interrupt
	if (!set)
	  newOcr0 = MAXT;
	else
	  {
	    uint32_t now = call Counter.get();
	    if (now < t0) 
	      {
		oopsT0();
		t0 = now;
	      }
	    if (now - t0 >= dt)
	      {
		set = FALSE;
		fired = TRUE;
		newOcr0 = MAXT;
	      }
	    else
	      {
		uint32_t alarm_in = (t0 + dt) - base;

		if (alarm_in > MAXT)
		  newOcr0 = MAXT;
		else if (alarm_in < MINDT)
		  newOcr0 = MINDT;
		else
		  newOcr0 = alarm_in;
	      }
	  }
	newOcr0--; // interrupt is 1ms late
	setOcr0(newOcr0);
      }
    if (fired)
      signal Alarm.fired();
  }

  async event void Compare.fired() {
    base += call Compare.get() + 1;
    setInterrupt();
  }  

  command error_t Init.init() {
    atomic
      {
	Atm128TimerControl_t x;

	call Compare.start();
	x.flat = 0;
	x.bits.cs = divider;
	x.bits.wgm1 = 1;
	call TimerCtrl.setControl(x);
	call Compare.set(MAXT);
	setInterrupt();
      }
    return SUCCESS;
  }

  async command uint32_t Counter.get() {
    uint32_t now;

    atomic
      {
	uint8_t now8 = call Timer.get();

	if ((call TimerCtrl.getInterruptFlag()).bits.ocf0)
	  now = base + call Counter.get() + call Timer.get();
	else
	  now = base + now8;

	if (now < lastNow)
	  {
	    oopsNow();
	    now = lastNow;
	  }
	lastNow = now;
      }
    return now;
  }

  async command bool Counter.isOverflowPending() {
    return FALSE;
  }

  async command void Counter.clearOverflow() { }

  async command void Alarm.start(uint32_t ndt) {
    call Alarm.startAt(call Counter.get(), ndt);
  }

  async command void Alarm.stop() {
    atomic set = FALSE;
  }

  async command bool Alarm.isRunning() {
    atomic return set;
  }

  async command void Alarm.startAt(uint32_t nt0, uint32_t ndt) {
    atomic
      {
	set = TRUE;
	t0 = nt0;
	dt = ndt;
      }
    setInterrupt();
  }

  async command uint32_t Alarm.getNow() {
    return call Counter.get();
  }

  async command uint32_t Alarm.getAlarm() {
    atomic return t0 + dt;
  }

  async event void Timer.overflow() { }
}
