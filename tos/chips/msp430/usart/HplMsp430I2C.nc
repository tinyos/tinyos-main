
#include <msp430usart.h>

interface HplMsp430I2C {
  
  async command bool isI2C();
  async command void clearModeI2C();
  async command void setModeI2C( msp430_i2c_config_t* config );
  
  // U0CTL
  async command void setMasterMode();
  async command void setSlaveMode();
  
  async command void enableI2C();
  async command void disableI2C();
  
  // I2CTCTL
  async command bool getWordMode();
  async command void setWordMode( bool mode );

  async command bool getRepeatMode();
  async command void setRepeatMode( bool mode );
  
  async command uint8_t getClockSource();
  async command void setClockSource( uint8_t src );
  
  async command bool getTransmitReceiveMode();
  async command void setTransmitMode();
  async command void setReceiveMode();
  
  async command bool getStartByte();
  async command void setStartByte();
  
  async command bool getStopBit();
  async command void setStopBit();
  
  async command bool getStartBit();
  async command void setStartBit();
  
  // I2CDR
  async command uint8_t getData();
  async command void setData( uint8_t data );
  
  // I2CNDAT
  async command uint8_t getTransferByteCount();
  async command void setTransferByteCount( uint8_t count );
  
  // I2CPSC
  async command uint8_t getClockPrescaler();
  async command void setClockPrescaler( uint8_t scaler );
  
  // I2CSCLH and I2CSCLL
  async command uint16_t getShiftClock();
  async command void setShiftClock( uint16_t shift );
  
  // I2COA
  async command uint16_t getOwnAddress();
  async command void setOwnAddress( uint16_t addr );
  
  // I2CSA
  async command uint16_t getSlaveAddress();
  async command void setSlaveAddress( uint16_t addr );
  
  // I2CIE
  async command void disableStartDetect();
  async command void enableStartDetect();
  
  async command void disableGeneralCall();
  async command void enableGeneralCall();
  
  async command void disableTransmitReady();
  async command void enableTransmitReady();
  
  async command void disableReceiveReady();
  async command void enableReceiveReady();
  
  async command void disableAccessReady();
  async command void enableAccessReady();
  
  async command void disableOwnAddress();
  async command void enableOwnAddress();
  
  async command void disableNoAck();
  async command void enableNoAck();
  
  async command void disableArbitrationLost();
  async command void enableArbitrationLost();
  
  // I2CIFG
  async command bool isStartDetectPending();
  async command bool isGeneralCallPending();
  async command bool isTransmitReadyPending();
  async command bool isReceiveReadyPending();
  async command bool isAccessReadyPending();
  async command bool isOwnAddressPending();
  async command bool isNoAckPending();
  async command bool isArbitrationLostPending();
  
  // I2CIV
  async command uint8_t getIV();
  
}
