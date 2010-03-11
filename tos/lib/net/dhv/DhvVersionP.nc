/**
 * DHV Version Check Module
 *
 * Module checks version of the data item.
 * details on the working of the parameters, please refer to Thanh Dang et al.,
 * "DHV: A Code Consistency Maintenance Protocol for Multi-Hop Wireless Sensor
 * Networks" EWSN 09.
 *
 * @author Thanh Dang
 * @author Seungweon Park
 *
 * @modified 1/3/2009   Added meaningful documentation.
 * @modified 8/28/2008  Defined DHV modules.
 * @modified 8/28/2008  Took the source code from DIP.
 **/

module DhvVersionP {
  provides interface DhvHelp;
  provides interface DisseminationUpdate<dhv_data_t>[dhv_key_t key];
	provides interface DhvCache as DhvDataCache;
  provides interface DhvCache as DhvVectorCache;
}

implementation {

  // keys are ordered from smallest to largest.
  dhv_key_t keys[UQCOUNT_DHV];
  dhv_version_t versions[UQCOUNT_DHV];
  dhv_index_t count = 0;

  //keep track of task
  uint8_t data_to_send[UQCOUNT_DHV];
  uint8_t vector_to_send[UQCOUNT_DHV];
  uint8_t vbit[(UQCOUNT_DHV == 0)?0:((UQCOUNT_DHV-1)/VBIT_LENGTH +1)];

/*utility for debugging purposes */
	void printDataStatus()
	{
		dhv_index_t i;

		for(i = 0; i < UQCOUNT_DHV; i++){
			dbg("DhvVersionP", "Data Status %d: %u \n",i, data_to_send[i]);
		}
	}


	void printVectorStatus()
	{
		dhv_index_t i;

		for(i = 0; i < UQCOUNT_DHV; i++){
			dbg("DhvVersionP", "T Vector Status %d: %u \n",i, vector_to_send[i]);
		}
	}

	
	void printVersionStatus()
	{
		dhv_index_t i;

		for(i = 0; i < UQCOUNT_DHV; i++){
			dbg("DhvVersionP", "Version Status %d: 0x%08x \n",i, versions[i]);
		}
	}


  /*DhvDataCache interface implementation */
	command void DhvDataCache.addItem(dhv_key_t key){
		dhv_index_t i;
	  
		dbg("DhvVersionP", "Add Item to data vector key %d\n", i);	
		i = call DhvHelp.keyToIndex(key);
		data_to_send[i] = ID_DHV_ADS;
		printDataStatus();
	}

	command void DhvDataCache.addReqItem(dhv_key_t key){
		dhv_index_t i;
	  
		dbg("DhvVersionP", "Add Req Item to data vector key %d\n", i);	
		i = call DhvHelp.keyToIndex(key);
		data_to_send[i] = ID_DHV_REQ;
		printDataStatus();
	}

	command void DhvDataCache.removeItem(dhv_key_t key){
		dhv_index_t i;

		i = call DhvHelp.keyToIndex(key);
		data_to_send[i] = ID_DHV_NO;
		
		dbg("DhvVersionP", "Remove Item from data vector key %d\n", i);	
		printDataStatus();
	}

	command bool DhvDataCache.hasItemToSend(){
		dhv_index_t i;

		for(i = 0; i < UQCOUNT_DHV; i++){
			if(data_to_send[i] > ID_DHV_NO){return TRUE;}
		}
		return FALSE;
	}

	command uint8_t* DhvDataCache.allItem(){
		return data_to_send;
	}
	
	command uint8_t DhvDataCache.nextItem(){
		dhv_index_t i;
		for(i = 0; i < UQCOUNT_DHV; i++){
			if(data_to_send[i] > ID_DHV_NO ){
				return i;
			}
		}
		return UQCOUNT_DHV;
	}

	command void DhvDataCache.removeAll(){
		dhv_index_t i;

		for(i=0; i < UQCOUNT_DHV; i++){
			data_to_send[i] = ID_DHV_NO;
		}
	}

	/*vector cache */
	command void DhvVectorCache.addItem(dhv_key_t key){
		dhv_index_t i;

		i = call DhvHelp.keyToIndex(key);
		vector_to_send[i] = ID_DHV_ADS;
		
		dbg("DhvVersionP", "Add Item to vector_to_send index %d\n", i);
		printVectorStatus();
	}

	command void DhvVectorCache.addReqItem(dhv_key_t key){
		dhv_index_t i;

		i = call DhvHelp.keyToIndex(key);
		vector_to_send[i] = ID_DHV_ADS;
		
		dbg("DhvVersionP", "Add Item to vector_to_send index %d\n", i);
		printVectorStatus();
	}

	command void DhvVectorCache.removeItem(dhv_key_t key){
		dhv_index_t i;

		i = call DhvHelp.keyToIndex(key);
		vector_to_send[i] = ID_DHV_NO;
		
		dbg("DhvVersionP", "Remove Item from vector_to_send index %d\n", i);
		printVectorStatus();
	}


	command bool DhvVectorCache.hasItemToSend(){
		dhv_index_t i;

		for(i = 0; i < UQCOUNT_DHV; i++){
			if(vector_to_send[i] > ID_DHV_NO){return TRUE;}
		}
		return FALSE;
	}

  command uint8_t* DhvVectorCache.allItem(){
		return vector_to_send;
	}


	command uint8_t DhvVectorCache.nextItem(){
		dhv_index_t i;

		for(i = 0; i < UQCOUNT_DHV; i++){
			if(vector_to_send[i] > ID_DHV_NO){
				return i;
			}
		}
		return UQCOUNT_DHV;
	}


	command void DhvVectorCache.removeAll(){
		dhv_index_t i;

		for(i=0; i < UQCOUNT_DHV; i++){
			vector_to_send[i] = ID_DHV_NO;
		}
	}


  command void DhvHelp.registerKey(dhv_key_t key) {
    keys[count] = key;
    count = count + 1;
    if(count == UQCOUNT_DHV) {
      dbg("DhvVersionP","Key registration complete!\n");
    }
		//printVersionStatus();
  }

  command void DisseminationUpdate.change[dhv_key_t key](dhv_data_t* val) {
    dhv_index_t i;
    dhv_version_t ver;

		dbg("DhvVersioP", "Updateing version for key %d \n", key);
    i = call DhvHelp.keyToIndex(key);
    ver = versions[i];
    ver++;
    versions[i] = ver;
		printVersionStatus();
  }

  command dhv_index_t DhvHelp.keyToIndex(dhv_key_t key) {
    dhv_index_t answer;
    dhv_index_t i;

    answer = DHV_UNKNOWN_INDEX;
    // linear search for now since it's easier

    for(i = 0; i < UQCOUNT_DHV; i++) {
      if(keys[i] == key) { 
				answer = i;
				break;
      }
    }
    dbg("DhvVersionP", "Converting key %x to index %u\n", key, answer);
    return answer;
  }

  command dhv_key_t DhvHelp.indexToKey(dhv_index_t ind) {
    return keys[ind];
  }

  command dhv_version_t DhvHelp.keyToVersion(dhv_key_t key) {
    dhv_index_t i;
    i = call DhvHelp.keyToIndex(key);
    return versions[i];
  }

  command void DhvHelp.setVersion(dhv_key_t key, dhv_version_t ver) {
    dhv_index_t i;
    i = call DhvHelp.keyToIndex(key);
    versions[i] = ver;
    dbg("DhvVersionP","Setting key %x at index %u to version 0x%08x\n", key, i, ver);
  }

  command dhv_version_t* DhvHelp.getAllVersions() {
    return versions;
  }

	command uint32_t DhvHelp.computeHash(uint8_t left, uint8_t right, uint32_t salt) {
     dhv_index_t i;
     uint32_t hashValue = salt;
     uint8_t *sequence;
     if(right <= left) return 0;
     sequence = ((uint8_t*) (versions + left)); 
     for(i = 0; i <= (right-left-1)*sizeof(dhv_version_t); i++) {
       hashValue += sequence[i];
       hashValue += (hashValue << 10);
       hashValue ^= (hashValue >> 6);
     }
     hashValue += (hashValue << 3);
     hashValue ^= (hashValue >> 11);
     hashValue += (hashValue << 15);
     return hashValue;
   }

 command uint8_t* DhvHelp.getVBits(uint32_t bindex){
	dhv_version_t version;
	uint8_t cur_byte;
	dhv_index_t i,j;
	

	j = 0;
	version = 0;
	cur_byte = 0;

	dbg("DhvVersionP", "getVBits at index %d \n", bindex);
	printVersionStatus();

	for(i = 1; i <= UQCOUNT_DHV; i++){
      version = versions[i-1];
			//dbg("DhvVersionP", "version %d 0x%08x \n", i, version);
      version = (version >>(bindex-1)) << (DHV_VERSION_LENGTH*8-1) >> (j + 24); //get the bindex bit

			//dbg("DhvVersionP", "shifted version 1 by %d :  0x%08x   -> 0x%08x : %d \n", VBIT_LENGTH-1, versions[i-1], version, j);
      cur_byte = cur_byte | version; 
			//dbg("DhvVersionP", "shifted version 2  0x%08x   -> 0x%08x : %d  cur_byte 0x%08x \n\n\n", versions[i-1], version, j, cur_byte);
      j++;

      if(j == VBIT_LENGTH){  
        //reset j
        j = 0;
        vbit[(i-1)/VBIT_LENGTH] = cur_byte;
				dbg("DhvVersionP", "vertical bits %d  0x%02x 0x%02x \n", (i-1)/VBIT_LENGTH, cur_byte, vbit[(i-1)/VBIT_LENGTH]);
        cur_byte = 0;
      }   
    }
		
		//debug
		for(i= 0; i < sizeof(vbit); i++){
			dbg("DhvVersionP", "vbit %d -> 0x%02x \n", i, vbit[i]);
		}

		return vbit;   		
 	}

	command dhv_version_t DhvHelp.getHSum(){
		dhv_version_t hsum;
		dhv_index_t i;
		hsum = versions[0];

		for(i =1 ; i < UQCOUNT_DHV; i++){
			hsum = hsum^versions[i];
		}
		return hsum;
	}

}
