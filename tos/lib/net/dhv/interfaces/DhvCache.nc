#include<Dhv.h>

interface DhvCache{
	command void addItem(dhv_key_t key);
	command void addReqItem(dhv_key_t key);
	command void removeItem(dhv_key_t key);
	command bool hasItemToSend();
	command uint8_t* allItem();
	command uint8_t nextItem();
	command void removeAll();
}

