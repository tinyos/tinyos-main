module SounderP
{
  provides interface Mts300Sounder;
  uses {
    interface Timer<TMilli>;
    interface GeneralIO as SounderPin;
  }
}
implementation
{
  command void Mts300Sounder.beep(uint16_t length) {
    if (call Timer.isRunning())
      {
	uint32_t remaining = call Timer.getdt(),
	  elapsed = call Timer.getNow() - call Timer.gett0();

	/* If more time left than we are requesting, just exit */
	if (remaining > elapsed && (remaining - elapsed) > length)
	  return;

	/* Override timer with new duration */
      }
    call Timer.startOneShot(length);
    call SounderPin.makeOutput();
    call SounderPin.set();
  }

  event void Timer.fired() {
    call SounderPin.clr();
  }
}
