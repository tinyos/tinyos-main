interface ADXL345Control
{
    command error_t setRange(uint8_t range, uint8_t resolution);
    event void setRangeDone(error_t error);

    command error_t setInterrups(uint8_t interrupt_vector);
    event void setInterruptsDone(error_t error);

    command error_t setIntMap(uint8_t int_map_vector);
    event void setIntMapDone(error_t error);

    command error_t setRegister(uint8_t reg, uint8_t value);
    event void setRegisterDone(error_t error);

    command error_t setDuration(uint8_t duration);
    event void setDurationDone(error_t error);

    command error_t setLatent(uint8_t latent);
    event void setLatentDone(error_t error);

    command error_t setWindow(uint8_t window);
    event void setWindowDone(error_t error);

    command error_t setReadAddress(uint8_t address);
    event void setReadAddressDone(error_t error);

}
