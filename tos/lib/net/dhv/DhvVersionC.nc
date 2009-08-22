/**
 * DHV Vector Message Configuration
 *
 * Define interfaces and components.
 *
 * @author Thanh Dang
 * @author Seungweon Park
 *
 * @modified 1/3/2009   Added meaningful documentation.
 * @modified 8/28/2008  Defined DHV modules.
 * @modified 8/28/2008  Took the source code from DIP.
 **/

#include <Dhv.h>

configuration DhvVersionC {
  provides interface DhvHelp;
  provides interface DisseminationUpdate<dhv_data_t>[dhv_key_t key];
	provides interface DhvCache as DataCache;
	provides interface DhvCache as VectorCache; 
}

implementation {
  components DhvVersionP;
  DhvHelp = DhvVersionP;
  DisseminationUpdate = DhvVersionP;
	DataCache = DhvVersionP.DhvDataCache;
	VectorCache = DhvVersionP.DhvVectorCache;
}
