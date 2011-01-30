#include <HplNandFlash.h>

interface HplNandFlash{
  //command void writeColumnAddress();
  //command void writeRowAddress();
  //command void isOperationComplete();
  //command void writeData();
  //command void readData();

  //command void eraseBlock_i(); // internal functions 
  //command void writePage_i(); // internal functions
  //command void copyPage_i(); // internal functions

  command void init(struct RawNandFlash *HplNand, const struct NandFlashModel *model, uint32_t commandAddr, uint32_t addressAddr, uint32_t dataAddr);
  command uint8_t findNandModel(const struct NandFlashModel *modelList, uint8_t size, struct NandFlashModel *model, uint32_t chipId);
  command void reset();
  command uint32_t readId();
  command uint8_t eraseBlock(const struct RawNandFlash *raw, uint16_t block);
  command uint8_t readPage(const struct RawNandFlash *raw, uint16_t block, uint16_t page, void *data, void *spare);
  command uint8_t writePage(const struct RawNandFlash *raw, uint16_t block, uint16_t page, void *data, void *spare);
  command uint8_t copyPage(const struct RawNandFlash *raw, uint16_t sourceBlock, uint16_t sourcePage, uint16_t destBlock, uint16_t destPage);
  command uint8_t copyBlock(const struct RawNandFlash *raw, uint16_t sourceBlock, uint16_t destBlock);



  command uint16_t getPageDataSize(const struct NandFlashModel *model);
  command uint32_t getDeviceSizeInPages(const struct NandFlashModel *model);
  command uint16_t getBlockSizeInPages(const struct NandFlashModel *model);
  command uint8_t getPageSpareSize(const struct NandFlashModel *model);
  command uint8_t hasSmallBlocks(const struct NandFlashModel *model);
  command uint16_t getDeviceSizeInBlocks(const struct NandFlashModel * model);
  command void readBadBlockMarker(const struct NandSpareScheme *scheme, const uint8_t *spare, uint8_t *marker);
  command void writeBadBlockMarker(const struct NandSpareScheme *scheme, uint8_t *spare, uint8_t marker);
  command uint32_t getDeviceSizeInBytes(const struct NandFlashModel *model);
  command uint32_t getBlockSizeInBytes(const struct NandFlashModel *model);
  command uint8_t readBlock(const struct RawNandFlash *raw, uint16_t block, void *data);
  command uint8_t writeBlock(const struct RawNandFlash *raw, uint16_t block, void *data);
}