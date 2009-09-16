module HplMMA7261QTControlP
{
  provides interface HplMMA7261QTControl;
  
  uses interface GeneralIO as Sleep;
  uses interface GeneralIO as GSelect1;
  uses interface GeneralIO as GSelect2;
}
implementation
{
  async command void HplMMA7261QTControl.on()
  {
    call Sleep.set();
  }
  
  async command void HplMMA7261QTControl.off()
  {
    call GSelect1.clr();
    call GSelect2.clr();
    call Sleep.clr();
  }
  
  async command void HplMMA7261QTControl.gSelect(uint8_t val)
  {
    // TODO(henrik) implement.
  }
}