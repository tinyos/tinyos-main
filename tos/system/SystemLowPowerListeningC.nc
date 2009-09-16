configuration SystemLowPowerListeningC
{
  provides interface SystemLowPowerListening;
}

implementation
{
  components SystemLowPowerListeningP;
  SystemLowPowerListening = SystemLowPowerListeningP;
}
