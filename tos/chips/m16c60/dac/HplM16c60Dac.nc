/**
 * HPL interface to the M16c60 D/A converers. 
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

interface HplM16c60Dac {
  /**
   * Sets the D/A value.
   * @param value The new D/A value
   */
  async command void setValue(uint8_t value);
  
  /**
   * Reads the current D/A value.
   * @return D/A value
   */
  async command uint8_t getValue();

  /**
   * Enables the D/A converter.
   */
  async command void enable();

  /**
   * Disables the D/A converter.
   */
  async command void disable();

  /**
   * Checks the state of the D/A converter.
   * @return TRUE if the D/A converter is enabled.
   */
  async command bool isEnabled();
}
