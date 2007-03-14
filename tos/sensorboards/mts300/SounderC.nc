configuration SounderC
{
  provides interface Mts300Sounder;
}
implementation
{
  components SounderP, new TimerMilliC(), MicaBusC;

  Mts300Sounder = SounderP;
  SounderP.Timer -> TimerMilliC;
  SounderP.SounderPin -> MicaBusC.PW2;
}
