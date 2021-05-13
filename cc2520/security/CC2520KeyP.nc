#define NONCE_SIZE	16

#ifndef FLAG_FIELD
#define FLAG_FIELD	FLAG_ENC			//M = 4 L = 2
#endif

#ifndef SECURITY_CONTROL
#define SECURITY_CONTROL SEC_ENC	//MIC-64	
#endif

module CC2520KeyP
{
	provides interface CC2520Key;
	provides interface Init;
	uses{
		interface CC2520Ram as Key;
		interface CC2520Ram as TXNonce;
		interface GeneralIO as CSN;
		interface Resource as SpiResource;
		interface ActiveMessageAddress;
	}	
}

implementation
{
	uint8_t *setKey = NULL;
	uint8_t *getKey = NULL;
	uint8_t operation;
	enum flags{
		SETKEY=4,
		GETKEY=5,
	};
	static uint8_t nonceTx[NONCE_SIZE];
	static uint8_t nonceRx[NONCE_SIZE];
	/*
	 * The nonce must be correctly initialized before receive or transmit CTR or
	 * CCM operations are started.The format of the nonce is 
	 *Initialization vector:
	 * Flags + Nonce + Sequence Counter
         * ---------------------------------------------------------------------
      	 *|Bytes:1|8		  |4		|1		|2	  	|
	 *----------------------------------------------------------------------
	 *|Flags  | Source Address|Frame Counter|Security Level | Sequence Cnter|
  	 *----------------------------------------------------------------------
	 *
	 * Flags field
	 *
      	 * ------------------------------------------------------
         * |Bits:7   |6		|5..3		|2..0		|
 	 * ------------------------------------------------------
	 * |Reserved |Adata	| M'		|L'		|
	 * ------------------------------------------------------
	 *
	 * Bit 7 is Reserved and should be set to 0. Adata indicates whether there is 
	 * additional data or not
	 *
  	 * M' is the length of the size of the authentication field. M' is encoded as 
	 * (M-2)/2 and valid values are even numbers from 4 to 16. L' is size of the
	 * length field and is encoded as  L-1.
	 *
	 *
         */

	command error_t Init.init()
	{
		uint8_t i;
	 	// Initialise nonce bytes to 0
    		for(i=0;i<NONCE_SIZE;i++)
    		{
		        nonceTx[i] = 0;
			nonceRx[i] = 0;
    		}
		// Set nonce flag field (Byte 0)
		nonceTx[0] = FLAG_FIELD;
		nonceRx[0] = FLAG_FIELD;
			
		 // Set byte 7 and 8 of nonce to myAddr
		nonceTx[7] = (uint8_t)((call ActiveMessageAddress.amAddress()) >> 8);
		nonceTx[8] = (uint8_t)(call ActiveMessageAddress.amAddress() & 0xff);
		
		// Set Security mode field of nonces (Byte 13)
		nonceTx[13] = SECURITY_CONTROL;
		nonceRx[13] = SECURITY_CONTROL;	

		//Setting sequence counter to 1
		nonceTx[15] = 0x01;
		nonceRx[15] = 0x01;
		
		//While transmitting just we have to copy the frameCounter into the nonce
		return SUCCESS;
	}

	task void resourceReq()
 	{
    		error_t error;
		error = call SpiResource.immediateRequest();
		if(error != SUCCESS){
			post resourceReq();
    		}
  	}

	void reverseArray(uint8_t *ptr,uint8_t length)
	{
		uint8_t i,tmp;
		for(i=0; i< length/2;i++)
		{
			tmp = ptr[i];
			ptr[i] = ptr[length -i];
			ptr[length-i] = tmp;	
		}	
	}

	event void SpiResource.granted()
  	{
		uint8_t ret;	
		if(operation == SETKEY)
 		{
			reverseArray(setKey, 16);
			reverseArray(nonceTx, 16);
			reverseArray(nonceRx, 16);

			call CSN.clr();
		/*Load and reverse the key (or reverse in software before loading)*/
			ret = call Key.write(0, setKey, 16);
			call CSN.set();
			
			call CSN.clr();
			call TXNonce.write(0, nonceTx, 16);
			call CSN.set();

			
			signal CC2520Key.setKeyDone(ret);
		}else if(operation == GETKEY)
		{
			call CSN.clr();
			ret = call Key.read(0, getKey, 16);
			call CSN.set();
			signal CC2520Key.getKeyDone(ret,getKey);
		}
		call SpiResource.release();
	}

	async event void ActiveMessageAddress.changed(){
		// TODO Auto-generated method stub
	}


	command uint8_t* CC2520Key.getTXNonce()
	{
		return nonceTx;
	}

	command error_t CC2520Key.setKey(uint8_t *key)
  	{
		setKey = key;
		operation = SETKEY;
		if(call SpiResource.request() != SUCCESS){
      			post resourceReq();
    		}
		return SUCCESS;
	}


	command error_t CC2520Key.getKey(uint8_t *key)
	{
		getKey = key;
		operation = GETKEY;
		if(call SpiResource.request() != SUCCESS){
      			post resourceReq();
    		}
		return SUCCESS;
	}


}
