

module SpiConfigC 
{
    provides 
    {
        interface Init;
        interface ResourceConfigure;
    }
    uses {
        interface HplSam3SpiChipSelConfig;
        interface HplSam3SpiConfig;
    }
}
implementation {

    command error_t Init.init() {
        // configure clock 
        call HplSam3SpiChipSelConfig.setBaud(20);
        call HplSam3SpiChipSelConfig.setClockPolarity(0); // logic zero is inactive 
        call HplSam3SpiChipSelConfig.setClockPhase(1);    // out on rising, in on falling 
        call HplSam3SpiChipSelConfig.disableAutoCS();     // disable automatic rising of CS after each transfer 
        //call HplSam3uSpiChipSelConfig.enableAutoCS(); 
 
        // if the CS line is not risen automatically after the last tx. The lastxfer bit has to be used. 
        call HplSam3SpiChipSelConfig.enableCSActive();    
        //call HplSam3uSpiChipSelConfig.disableCSActive();  
 
        call HplSam3SpiChipSelConfig.setBitsPerTransfer(SPI_CSR_BITS_8); 
        call HplSam3SpiChipSelConfig.setTxDelay(0); 
        call HplSam3SpiChipSelConfig.setClkDelay(0); 
        return SUCCESS;
    }

    async command void ResourceConfigure.configure() {
        // Do stuff here
    }
    
    async command void ResourceConfigure.unconfigure() {
        // Do stuff here...
    }
}
