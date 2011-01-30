

generic module Sam3uSpiP(uint8_t chip_id)
{
    provides 
    {
        interface ResourceConfigure as SubResourceConfigure;
    }
    uses {
        interface ResourceConfigure;
        interface HplSam3uSpiConfig;
    }
}
implementation {

    async command void SubResourceConfigure.configure() {
        call HplSam3uSpiConfig.selectChip(chip_id);
        call ResourceConfigure.configure();
    }
    
    async command void SubResourceConfigure.unconfigure() {
        call ResourceConfigure.unconfigure();
    }
}
