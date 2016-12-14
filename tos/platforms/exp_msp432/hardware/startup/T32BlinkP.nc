module T32BlinkP {
  uses interface Boot;
}
implementation {

#define T32_DIV_16 TIMER32_CONTROL_PRESCALE_1
#define T32_ENABLE TIMER32_CONTROL_ENABLE
#define T32_32BITS TIMER32_CONTROL_SIZE
#define T32_PERIODIC TIMER32_CONTROL_MODE

  event void Boot.booted() {
    Timer32_Type *ty = TIMER32_2;

    ty->INTCLR = 0;;            /* clear out any pending */

    /*
     * clear any pendings out of the NVIC.  note there shouldn't
     * be any because none of the the T32s should have an IE set.
     *
     * but doesn't hurt anything.  And this is an example.
     *
     * We also clear out INTC.  Any INT1 or INT2 that pops up
     * will also set INTC.  Clearing the interrupt on the timer
     * won't clear out the INTC in the NVIC.
     */
    NVIC_ClearPendingIRQ(T32_INT2_IRQn);
    NVIC_ClearPendingIRQ(T32_INTC_IRQn);

    ty->LOAD = 1048576;         /* 1 MiHz -> 1/sec */
    ty->CONTROL = T32_DIV_16 | T32_ENABLE | T32_32BITS | T32_PERIODIC |
                  TIMER32_CONTROL_IE;
    NVIC_SetPriority(T32_INT2_IRQn, 5);
    NVIC_EnableIRQ(T32_INT2_IRQn);
  }

  /*
   * toggle the light
   *
   * we also need to clear out the pending INTC from the NVIC.
   * pain in the but.  Weird design.
   */
  void T32_INT2_Handler() @C() @spontaneous() __attribute__((interrupt)) {
    TIMER32_2->INTCLR = 0;
    NVIC_ClearPendingIRQ(T32_INTC_IRQn);
    BITBAND_PERI(P1->OUT, 0) ^= 1;
  }
}
