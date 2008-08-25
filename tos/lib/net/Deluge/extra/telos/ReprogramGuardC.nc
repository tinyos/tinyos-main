configuration ReprogramGuardC
{
  provides interface ReprogramGuard;
}

implementation
{
  components ReprogramGuardP;
  components new VoltageC();
  
  ReprogramGuard = ReprogramGuardP;
  ReprogramGuardP.Voltage -> VoltageC;
}
