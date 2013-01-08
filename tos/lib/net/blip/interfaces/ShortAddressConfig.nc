interface ShortAddressConfig
{
  command void setShortAddr(uint16_t address);

  event void setShortAddrDone(error_t error);
}
