module PlatformPinsP {
  provides interface Init;
}
implementation {
  command error_t Init.init() {

    /* clear any pendings */
    P1->IFG = 0;
    P2->IFG = 0;
    P3->IFG = 0;
    P4->IFG = 0;
    P5->IFG = 0;
    P6->IFG = 0;

    /*
     * Enable NVIC interrupts for any Ports that interrupts occur on.
     *
     * This does not enable the actual interrupt.  Still controlled via IE
     * on each Port bit
     */
    NVIC_EnableIRQ(PORT1_IRQn);
    NVIC_EnableIRQ(PORT2_IRQn);
    NVIC_EnableIRQ(PORT3_IRQn);
    NVIC_EnableIRQ(PORT4_IRQn);
    NVIC_EnableIRQ(PORT5_IRQn);
    NVIC_EnableIRQ(PORT6_IRQn);

    return SUCCESS;
  }
}
