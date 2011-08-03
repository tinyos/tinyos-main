
#include <Msp430Adc12.h>

module ReprogramGuardP
{
  provides {
    interface ReprogramGuard;
    interface AdcConfigure<const msp430adc12_channel_config_t*> as VoltageConfigure;
  }
  uses {
    interface Resource;
    interface Msp430Adc12SingleChannel as Sample;
  }
}

implementation
{
  const msp430adc12_channel_config_t config = {
    inch: SUPPLY_VOLTAGE_HALF_CHANNEL,
    sref: REFERENCE_VREFplus_AVss,
    ref2_5v: REFVOLT_LEVEL_1_5,
    adc12ssel: SHT_SOURCE_ACLK,
    adc12div: SHT_CLOCK_DIV_1,
    sht: SAMPLE_HOLD_4_CYCLES,
    sampcon_ssel: SAMPCON_SOURCE_SMCLK,
    sampcon_id: SAMPCON_CLOCK_DIV_1
  };
  uint16_t voltage;

  enum {
    VTHRESH = 0xE66, // 2.7V
  };

  
  task void sampleDone() {
    bool ok;
    atomic ok = (voltage > VTHRESH);
    signal ReprogramGuard.okToProgramDone(ok);
  }

  command error_t ReprogramGuard.okToProgram() {
    return call Resource.request();
  }

  event void Resource.granted() {
    call Sample.configureSingle(&config);
    call Sample.getData();
  }

  async event error_t Sample.singleDataReady(uint16_t data) {
    atomic voltage = data;
    call Resource.release();
    post sampleDone();
    return SUCCESS;
  }

  async event uint16_t * Sample.multipleDataReady(uint16_t *buffer, uint16_t numSamples) {
    return NULL;
  }

  async command const msp430adc12_channel_config_t* VoltageConfigure.getConfiguration() {
    return &config;
  }
}
