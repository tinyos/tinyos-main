
#include <Dhv.h>

interface DhvHelp {
  command void registerKey(dhv_key_t key);

  command dhv_index_t keyToIndex(dhv_key_t key);
  command dhv_key_t indexToKey(dhv_index_t ind);
  command dhv_version_t keyToVersion(dhv_key_t key);
  command void setVersion(dhv_key_t key, dhv_version_t ver);
  command dhv_version_t* getAllVersions();
	command dhv_version_t getHSum();
	command uint8_t* getVBits(uint32_t bindex);
	command uint32_t computeHash(uint8_t left, uint8_t right,uint32_t salt);	 
}
