
#include <DIP.h>

interface DIPHelp {
  command void registerKey(dip_key_t key);

  command dip_index_t keyToIndex(dip_key_t key);
  command dip_key_t indexToKey(dip_index_t ind);
  command dip_version_t keyToVersion(dip_key_t key);
  command void setVersion(dip_key_t key, dip_version_t ver);
  command dip_version_t* getAllVersions(); 
}
