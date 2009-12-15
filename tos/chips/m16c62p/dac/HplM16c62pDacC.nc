/**
 * HPL for the M16c62p D/A conversion susbsystem.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

configuration HplM16c62pDacC {
  provides interface HplM16c62pDac as Dac0;
  provides interface HplM16c62pDac as Dac1;
}
implementation {
  components new HplM16c62pDacP(&DA0, 0) as Dac0_, 
             new HplM16c62pDacP(&DA1, 1) as Dac1_;

  Dac0 = Dac0_;
  Dac1 = Dac1_;
}
