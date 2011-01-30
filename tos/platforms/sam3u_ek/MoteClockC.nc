configuration MoteClockC
{

    provides {
        interface Init;
    }
}

implementation
{

    components MoteClockP, HplSam3uClockC;

    Init = MoteClockP;
    MoteClockP.HplSam3Clock -> HplSam3uClockC;

  components LedsC;
  MoteClockP.Leds -> LedsC;
}
