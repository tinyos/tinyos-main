generic module Z1UsciP() {
  provides interface Msp430SpiConfigure[ uint8_t id ];
  provides interface Msp430I2CConfigure[ uint8_t id ];
}
implementation {

  msp430_spi_union_config_t msp430_spi_z1_config = { {
    ubr		: 2,			/* smclk/2   */
    ucmode	: 0,			/* 3 pin master, no ste */
    ucmst	: 1,
    uc7bit	: 0,			/* 8 bit */
    ucmsb	: 1,			/* msb first, compatible with msp430 usart */
    ucckpl	: 1,			/* inactive state low */
    ucckph	: 0,			/* data captured on rising, changed falling */
    ucssel	: 2,			/* smclk */
  } };

  async command msp430_spi_union_config_t* Msp430SpiConfigure.getConfig[uint8_t id]() {
    return (msp430_spi_union_config_t*) &msp430_spi_z1_config;
  }

  msp430_i2c_union_config_t msp430_i2c_z1_config = { {
    ucmode  : 3,			/* i2c mode */
    ucmst   : 1,			/* master */
    ucmm    : 0,			/* single master */
    ucsla10 : 0,			/* 7 bit slave */
    uca10   : 0,			/* 7 bit us */
    uctr    : 0,			/* rx mode to start */
    ucssel  : 2,			/* smclk */
    i2coa   : 1,			/* our address is 1 */
    ucgcen  : 1,			/* respond to general call */
    ubr     : 800,			/* smclk/2 */
  } };

  async command msp430_i2c_union_config_t* Msp430I2CConfigure.getConfig[uint8_t id]() {
    return (msp430_i2c_union_config_t *) &msp430_i2c_z1_config;
  }

}
