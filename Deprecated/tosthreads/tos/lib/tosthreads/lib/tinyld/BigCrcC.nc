configuration BigCrcC {
  provides interface BigCrc;
}

implementation {
  components CrcC,
             BigCrcP;
  
  BigCrc = BigCrcP;
  
  BigCrcP.Crc -> CrcC;
}
