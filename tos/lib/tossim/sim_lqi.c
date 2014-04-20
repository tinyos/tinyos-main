#include <randomlib.h>
#include <math.h>
#include "sim_lqi.h"

uint8_t bi_search(lqi_dist_t *lqi, uint8_t low_i, uint8_t high_i, uint8_t coin)
{
  uint8_t i = low_i + ((high_i - low_i + 1) / 2);
  uint8_t fromCDF = (i == 0) ? 0 : lqi[i - 1].cdf;
  uint8_t toCDF = lqi[i].cdf;
  if (fromCDF <= coin && coin < toCDF) {
    return lqi[i].lqi;
  } else if (fromCDF > coin) {
    return bi_search(lqi, low_i, i - 1, coin);
  } else {
    return bi_search(lqi, i + 1, high_i, coin);
  }
}

uint8_t sim_lqi_generate(double SNR)__attribute__ ((C, spontaneous))
{
  uint8_t coin = (RandomUniform() * 100);   // Flip a coin
  uint8_t i, closest_i = 0;
  
  // STEP 1: Find the SNR-LQI distribution
  for (i = 0; i < allSnr_len; i++) {
    if (allSnr[i].snr == SNR) {
      break;
    } else {
      if (fabs(SNR - allSnr[i].snr) < fabs(SNR - allSnr[closest_i].snr)) {
        closest_i = i;
      }
    }
  }
  i = (i == allSnr_len) ? closest_i : i;
  
  // STEP 2: Generate a LQI based on the coin tossed (a binary search)
  return bi_search(allSnr[i].lqi, 0, allSnr[i].numLqi - 1, coin);
  
  //for (j = 0; j < allSnr[i].numLqi; j++) {
  //  if (coin < allSnr[i].lqi[j].cdf) {
  //    return allSnr[i].lqi[j].lqi;
  //  }
  //}
  //return allSnr[i].snr;
}
