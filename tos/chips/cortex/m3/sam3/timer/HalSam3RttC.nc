configuration HalSam3RttC
{
    provides
    {
        interface Init;
        interface Alarm<TMilli,uint32_t> as Alarm;
        interface LocalTime<TMilli> as LocalTime;
    }
}

implementation
{
    components HplSam3RttC, HalSam3RttP;

    HalSam3RttP.HplSam3Rtt -> HplSam3RttC;
    HalSam3RttP.RttInit -> HplSam3RttC.Init;

    Init = HalSam3RttP;
    Alarm = HalSam3RttP;
    LocalTime = HalSam3RttP;
}    


