/**
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#ifndef __TOSBOOT_PLATFORM_H__
#define __TOSBOOT_PLATFORM_H__

enum {
  TOSBOOT_ARGS_ADDR = 0,      // address of TOSBoot args in internal flash
  TOSBOOT_GESTURE_MAX_COUNT = 3,  // number of resets to force golden image
  TOSBOOT_GOLDEN_IMG_ADDR = 0x0L, // address of the golden image in external flash
  TOSBOOT_INT_PAGE_SIZE = 512L, // size of each internal program flash page. Each page is 64Kbytes but it is better to split it into 128 parts (65536/512=128).
};

#endif  // __TOSBOOT_PLATFORM_H__
