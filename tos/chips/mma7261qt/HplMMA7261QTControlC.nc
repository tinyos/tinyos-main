configuration HplMMA7261QTControlC
{
  provides interface HplMMA7261QTControl;
}
implementation
{
  components HplMMA7261QTControlP, HplMMA7261QTC;
  
  HplMMA7261QTControlP.Sleep -> HplMMA7261QTC.Sleep;
  HplMMA7261QTControlP.GSelect1 -> HplMMA7261QTC.GSelect1;
  HplMMA7261QTControlP.GSelect2 -> HplMMA7261QTC.GSelect2;
  
  HplMMA7261QTControl = HplMMA7261QTControlP;
}