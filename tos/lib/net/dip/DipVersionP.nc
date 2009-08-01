
module DipVersionP {
  provides interface DipHelp;

  provides interface DisseminationUpdate<dip_data_t>[dip_key_t key];
}

implementation {
  int lessThan(const void* a, const void* b);

  // keys are ordered from smallest to largest.
  dip_key_t keys[UQCOUNT_DIP];
  dip_version_t versions[UQCOUNT_DIP];
  dip_index_t count = 0;

  command void DipHelp.registerKey(dip_key_t key) {
    dip_index_t i;

    keys[count] = key;
    count = count + 1;
    if(count == UQCOUNT_DIP) {
      qsort(keys, UQCOUNT_DIP, sizeof(dip_key_t), lessThan);
      dbg("DipVersionP","Key registration complete!\n");
      for(i = 0; i < UQCOUNT_DIP; i++) {
	dbg("DipVersionP","Key %x\n", keys[i]);
      }
    }
  }

  command void DisseminationUpdate.change[dip_key_t key](dip_data_t* val) {
    dip_index_t i;
    dip_version_t ver;

    i = call DipHelp.keyToIndex(key);
    ver = versions[i];

    // the version has node ID embedded in it, so need to do some shifts
    ver = ver >> 16;
    ver++;
    if ( ver == DIP_UNKNOWN_VERSION ) { ver++; }
    ver = ver << 16;
    ver += TOS_NODE_ID;

    versions[i] = ver;
  }

  command dip_index_t DipHelp.keyToIndex(dip_key_t key) {
    dip_index_t answer;
    dip_index_t i;

    answer = DIP_UNKNOWN_INDEX;
    // linear search for now since it's easier
    for(i = 0; i < UQCOUNT_DIP; i++) {
      if(keys[i] == key) { 
	answer = i;
	break;
      }
    }
    dbg("DipVersionP", "Converting key %x to index %u\n", key, answer);
    return answer;
  }

  command dip_key_t DipHelp.indexToKey(dip_index_t ind) {
    return keys[ind];
  }

  command dip_version_t DipHelp.keyToVersion(dip_key_t key) {
    dip_index_t i;

    i = call DipHelp.keyToIndex(key);
    if(i == DIP_UNKNOWN_INDEX) {
      return DIP_UNKNOWN_VERSION;
    }
    return versions[i];
  }

  command void DipHelp.setVersion(dip_key_t key, dip_version_t ver) {
    dip_index_t i;

    i = call DipHelp.keyToIndex(key);
    versions[i] = ver;
    dbg("DipVersionP","Setting key %x at index %u to version %x\n", key, i, ver);
  }

  command dip_version_t* DipHelp.getAllVersions() {
    return versions;
  }

  int lessThan(const void* a, const void* b) {
    if ((*(dip_key_t*) a) < (*(dip_key_t*) b)) {
      return -1;
    }
    else if ((*(dip_key_t*) a) > (*(dip_key_t*) b)) {
      return 1;
    }
    return 0;
  }

  // binary search code which may be unstable
  /*
  dip_index_t answer;

  search_result = (dip_key_t*) bsearch(&key, &keys, UQCOUNT_DIP,
				       sizeof(dip_key_t), lessThan);
  if(search_result == NULL) {
    return DIP_UNKNOWN_INDEX;
  }
  answer = search_result - keys;
  */
}
