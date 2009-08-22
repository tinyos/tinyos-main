interface DhvStateLogic{
	command void setDiffSummary();
	command void setSameSummary();
	command uint32_t getVBitState();
	command void setVBitState(uint32_t state);
  command void unsetVBitIndex(uint8_t dindex);
  command uint8_t getVBitIndex();
  command void setVBitIndex(uint8_t dindex);
  command void setHSumStatus();
  command void unsetHSumStatus();
  command uint8_t getHSumStatus();
}
