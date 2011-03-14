/**
 * HPL for the M16c60 D/A conversion susbsystem.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

configuration HplM16c60DacC {
  provides interface HplM16c60Dac as Dac0;
  provides interface HplM16c60Dac as Dac1;
}
implementation {
  components new HplM16c60DacP((uint16_t)&DA0, 0) as Dac0_, 
             new HplM16c60DacP((uint16_t)&DA1, 1) as Dac1_;

  Dac0 = Dac0_;
  Dac1 = Dac1_;
}
