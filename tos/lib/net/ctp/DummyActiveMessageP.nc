module DummyActiveMessageP {
  provides interface LinkPacketMetadata;
}

implementation
{

  async command bool LinkPacketMetadata.highChannelQuality(message_t* msg) {
    return 0;
  }

}
