

interface CC2520Key
{

	/*Note that for all the security instructions, the key and counter should 		 * reside in RAM in reversed byte order compare to the data. This can be done
	 * by reversing the byte order of the key/counter before it is written to the
	 * RAM,or the MEMCPR instructions can be used to reverse the byte order of 
	 * keys/counter that are already in the RAM
         */

	command error_t setKey(uint8_t *key);
	event void setKeyDone(uint8_t status);
	
	command error_t getKey(uint8_t *key);
	event void getKeyDone(uint8_t status, uint8_t *ptr);

	/*
	 * Returns the pointer to the nonce
	 */
	command uint8_t *getTXNonce();
	

}
