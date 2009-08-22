#include<Dhv.h>

interface DhvLogic{
	command error_t setItem(dhv_key_t key);
	command error_t setReqItem(dhv_key_t key);
	command error_t unsetItem(dhv_key_t key);
	command uint8_t nextItem();
  command uint8_t * allItem();
} 
