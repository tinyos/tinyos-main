module MSP430ADC12ChannelConfigM {
  uses interface MSP430ADC12ChannelConfig;  
}
implementation
{
  async event msp430adc12_channel_config_t MSP430ADC12ChannelConfig.getConfigurationData(uint8_t channel) {
    msp430adc12_channel_config_t config = {
      channel, REFERENCE_AVcc_AVss, REFVOLT_LEVEL_1_5,
      SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_4_CYCLES,
      SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1 };

    return config;
  }
}

