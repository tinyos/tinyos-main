configuration ReprogramGuardC
{
  provides interface ReprogramGuard;
}

implementation
{
  components ReprogramGuardP;
  
  ReprogramGuard = ReprogramGuardP;
}
