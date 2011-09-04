configuration Stm25pPowerC{
  provides interface SplitControl;
  uses interface SplitControl as SpiControl;
}
implementation{
  components Stm25pPowerP, MainC, HplStm25pPinsC;
  Stm25pPowerP.Init<-MainC.SoftwareInit;
  Stm25pPowerP.Power->HplStm25pPinsC.Power;
  #ifdef STM25P_HW_POWER_DISABLE
    SplitControl=SpiControl;
  #else
    components new TimerMilliC();
    SplitControl=Stm25pPowerP;
    Stm25pPowerP.Timer->TimerMilliC;
    Stm25pPowerP.SpiControl=SpiControl;
  #endif
}