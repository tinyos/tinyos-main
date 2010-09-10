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
    }
}
implementation {
    
    typedef enum {
        DELAY_5US = 6,                              // calibrated for tmote at 4MHz, iterations of busyWait
        RESET_LOW_TIME = 560/5*DELAY_5US,           // min: 480us, max: 640 us
        DELAY_60US = 60/5*DELAY_5US,                // min: 15us, max: 60us
        PRESENCE_DETECT_LOW_TIME = 240/5*DELAY_5US, // min: 60us, max: 240us
        PRESENCE_RESET_HIGH_TIME = 480/5*DELAY_5US, // maximum recommended value
        SLOT_TIME   =  65/5*DELAY_5US
    } onewiretimes_t;

    void busyWait(uint16_t ticks) {
        uint16_t i;
        for(i = 0; i < ticks; i++) {
            asm volatile  ("nop" ::);
        }
    }
    
    bool reset() {
        uint16_t i;
        call Pin.makeInput();
        call Pin.clr();
        call Pin.makeOutput();
        busyWait(RESET_LOW_TIME);
        call Pin.makeInput();
        busyWait(DELAY_60US);
        for(i = 0; (i < PRESENCE_DETECT_LOW_TIME) && (call Pin.get()); i++) {
            // wait until either the pin goes low or the timer expires
        }
        busyWait(PRESENCE_RESET_HIGH_TIME - DELAY_60US);
        return i < PRESENCE_DETECT_LOW_TIME;
    }

    void writeOne() {
        call Pin.makeOutput();
        busyWait(DELAY_5US);
        call Pin.makeInput();
        busyWait(SLOT_TIME);
    }
    
    void writeZero() {
        call Pin.makeOutput();
        busyWait(DELAY_60US);
        call Pin.makeInput();
        busyWait(DELAY_5US);
    }
    
    bool readBit() {
        bool bit;
        call Pin.makeOutput();
        busyWait(DELAY_5US);
        call Pin.makeInput();
        busyWait(DELAY_5US);
        bit = call Pin.get();
        busyWait(SLOT_TIME);
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
