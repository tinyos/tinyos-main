configuration HplNandFlashC{
  provides interface HplNandFlash;

}
implementation{
  components HplNandFlashP;
  HplNandFlash = HplNandFlashP;

  components HplSam3uClockC;
  HplNandFlashP.HSMC4ClockControl -> HplSam3uClockC.HSMC4PPCntl;

  components HplSam3uGeneralIOC as IO;
  HplNandFlashP.NandFlash_CE -> IO.PioA16;
  HplNandFlashP.TempPin -> IO.PioC12;
  HplNandFlashP.NandFlash_RB -> IO.PioB24;

  HplNandFlashP.NandFlash_OE -> IO.HplPioB17;
  HplNandFlashP.NandFlash_WE -> IO.HplPioB18;
  HplNandFlashP.NandFlash_CLE -> IO.HplPioB22;
  HplNandFlashP.NandFlash_ALE -> IO.HplPioB21;
  
  HplNandFlashP.NandFlash_Data00 -> IO.HplPioB9;
  HplNandFlashP.NandFlash_Data01 -> IO.HplPioB10;
  HplNandFlashP.NandFlash_Data02 -> IO.HplPioB11;
  HplNandFlashP.NandFlash_Data03 -> IO.HplPioB12;
  HplNandFlashP.NandFlash_Data04 -> IO.HplPioB13;
  HplNandFlashP.NandFlash_Data05 -> IO.HplPioB14;
  HplNandFlashP.NandFlash_Data06 -> IO.HplPioB15;
  HplNandFlashP.NandFlash_Data07 -> IO.HplPioB16;

  HplNandFlashP.NandFlash_Data08 -> IO.HplPioB25;
  HplNandFlashP.NandFlash_Data09 -> IO.HplPioB26;
  HplNandFlashP.NandFlash_Data10 -> IO.HplPioB27;
  HplNandFlashP.NandFlash_Data11 -> IO.HplPioB28;
  HplNandFlashP.NandFlash_Data12 -> IO.HplPioB29;
  HplNandFlashP.NandFlash_Data13 -> IO.HplPioB30;
  HplNandFlashP.NandFlash_Data14 -> IO.HplPioB31;
  HplNandFlashP.NandFlash_Data15 -> IO.HplPioB6;

  components LedsC, LcdC;
  HplNandFlashP.Leds -> LedsC;
  HplNandFlashP.Draw -> LcdC;

  components new TimerMilliC() as TimerC;
  HplNandFlashP.ReadBlockTimer -> TimerC;
}