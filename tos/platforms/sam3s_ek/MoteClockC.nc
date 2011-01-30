configuration MoteClockC
{

    provides {
        interface Init;
    }
}

implementation
{

    components MoteClockP, HplSam3sClockC;

    Init = MoteClockP;
    MoteClockP.HplSam3Clock -> HplSam3sClockC;

  components LedsC;
  MoteClockP.Leds -> LedsC;
}
