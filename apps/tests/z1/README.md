Readme file for Z1 test applications
Antonio Liñán <alinan@zolertia.com>
September 17, 2014

Tested with:

  msp430-gcc --version
  msp430-gcc (GCC) 4.6.3 20120301 (mspgcc LTS 20120406 unpatched)

  nescc --version
  nescc: 1.3.3
  gcc: gcc (Ubuntu/Linaro 4.6.3-1ubuntu5) 4.6.3

  tinyos-tools 2.2.0

  GIT revision:
    3a499120d412344471619b397803cdcc0829a524

All test applications are working, but Ziglets/TestBMP085 fails, this is a known
legacy problem with the current implementation of the BMP085 driver, current
work-around is to use msp430-gcc 3.2.3
