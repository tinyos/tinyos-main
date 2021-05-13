

interface Option{




command int length_opt(uint8_t search_type);	//gives the length of each option

command uint8_t * findoption(void *payload,uint8_t first_type,uint8_t search_type);

command uint8_t * ptrMsg(void *payload);

}
