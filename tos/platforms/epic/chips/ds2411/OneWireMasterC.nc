/* -*- mode:c++; indent-tabs-mode: nil -*- */
/**
 * Dallas/Maxim 1wire bus master
 *
 */

module OneWireMasterC {
    provides {
        interface OneWireStream as OneWire;
    }
    uses {
        interface GeneralIO as Pin;
        interface BusyWait<TMicro, uint16_t>;
    }
}
implementation {
    
    typedef enum {
        DELAY_5US = 5,                              
        RESET_LOW_TIME = 560,                       // min: 480us, max: 640 us
        DELAY_60US = 60,                            // min: 15us, max: 60us
        PRESENCE_DETECT_LOW_TIME = 240,             // min: 60us, max: 240us
        PRESENCE_RESET_HIGH_TIME = 480,             // maximum recommended value
        SLOT_TIME   =  65,
    } onewiretimes_t;

    bool reset() {
        uint16_t i;
        call Pin.makeInput();
        call Pin.clr();
        call Pin.makeOutput();
        call BusyWait.wait(RESET_LOW_TIME);
        call Pin.makeInput();
        call BusyWait.wait(DELAY_60US);
        // wait until either the pin goes low or the timer expires
        for(i = 0; i < PRESENCE_DETECT_LOW_TIME; i += DELAY_5US, call BusyWait.wait(DELAY_5US))
          if (!call Pin.get()) break;
        call BusyWait.wait(PRESENCE_RESET_HIGH_TIME - DELAY_60US);
        return i < PRESENCE_DETECT_LOW_TIME;
    }

    void writeOne() {
        call Pin.makeOutput();
        call BusyWait.wait(DELAY_5US);
        call Pin.makeInput();
        call BusyWait.wait(SLOT_TIME);
    }
    
    void writeZero() {
        call Pin.makeOutput();
        call BusyWait.wait(DELAY_60US);
        call Pin.makeInput();
        call BusyWait.wait(DELAY_5US);
    }
    
    bool readBit() {
        bool bit;
        call Pin.makeOutput();
        call BusyWait.wait(DELAY_5US);
        call Pin.makeInput();
        call BusyWait.wait(DELAY_5US);
        bit = call Pin.get();
        call BusyWait.wait(SLOT_TIME);
        return bit;
    }
    
    void writeByte(uint8_t c) {
        uint8_t j;
        for(j = 0; j < 8; j++) {
            if(c & 0x01) {
                writeOne();
            }
            else {
                writeZero();
            }
            c >>= 1;
        }
    }

    uint8_t readByte() {
        uint8_t i,c = 0;
        for(i = 0; i < 8; i++) {
            c >>= 1;
            if(readBit()) {
                c |= 0x80;
            }
        }
        return c;
    }
    
    command error_t OneWire.read(uint8_t cmd, uint8_t* buf, uint8_t len) {
        error_t e = SUCCESS;
        atomic {
            if(reset()) {
                uint8_t i;
                writeByte(cmd);
                for(i = 0; i < len; i++) {
                    buf[i] = readByte();
                }
            }
            else {
                e = EOFF;
            }
        }
        return e;
    }
    
    command error_t OneWire.write(const uint8_t* buf, uint8_t len) {
        error_t e = SUCCESS;
        atomic {
            if(reset()) {
                uint8_t i;
                for(i = 0; i < len; i++) {
                    writeByte(buf[i]);
                }
            }
            else {
                e = EOFF;
            }
        }
        return e;
    }
}
