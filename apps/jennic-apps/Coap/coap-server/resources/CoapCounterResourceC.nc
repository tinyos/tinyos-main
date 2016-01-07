generic configuration CoapCounterResourceC(uint8_t uri_key) {
    provides interface CoapResource;
} implementation {
    components new CoapCounterResourceP(uri_key) as CoapResourceP;
    CoapResource = CoapResourceP;

    components new TimerMilliC() as UpdateTimer;
    CoapResourceP.UpdateTimer -> UpdateTimer;

	components LedsC;
    CoapResourceP.Leds -> LedsC;
}
