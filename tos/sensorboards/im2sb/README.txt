Intel Mote 2 Demo Sensorboard Release Notes

* The configuration provided assumes the following I2C addresses:

  TSL2561 - 0x49
  TMP175  - 0X4A
  MAX136  - 0x34

These address assignments are compatible with the DS2745 on the optional battery board.  Modify the address assignments as needed.

* The TMP175 anbd TSL2561 interrupts will work ONLY IF the board has been modified to include a pullup resistor on their associated interrupt lines. Some boards do not include these resistors.




