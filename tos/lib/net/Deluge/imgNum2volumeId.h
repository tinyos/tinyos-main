#ifndef __IMGNUM2VOLUMEID_H__
#define __IMGNUM2VOLUMEID_H__

uint8_t _imgNum2volumeId[] = {
  VOLUME_GOLDENIMAGE,
  VOLUME_DELUGE1,
  VOLUME_DELUGE2,
  VOLUME_DELUGE3
};

enum {
  NON_DELUGE_VOLUME = 0xFF
};

uint8_t imgNum2volumeId(uint8_t imgNum)
{
  return imgNum < DELUGE_NUM_VOLUMES ? _imgNum2volumeId[imgNum] : NON_DELUGE_VOLUME;
}

#endif
