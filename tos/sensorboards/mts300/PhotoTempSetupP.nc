generic configuration PhotoTempSetupP(const char *resname)
{
  provides interface Resource[uint8_t client];
  uses {
    interface Timer;
    interface Resource as SharingResource;
    interface GeneralIO as Power;
  }
}
implementation
{
  components
    new RoundRobinArbiterC(resname) as Arbiter,
    new SplitControlPowerManager() as Power,
    new PhotoTempControlP() as Control;
  
  Resource = Arbiter;
  Power.ResourceDefaultOwner -> Arbiter;
  Power.ArbiterInfo -> Arbiter;
  Power.SplitControl -> Control;

  Control.Resource = SharingResource;
  Control.Power = Power;
  Control.Timer = Timer;
}
