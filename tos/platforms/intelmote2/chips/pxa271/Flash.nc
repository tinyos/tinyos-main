/**
 * Interface for writing and erasing in flash memory
 *
 * Author:		Josh Herbach
 * Revision:	1.0
 * Date:		09/02/2005
 */

interface Flash
{
  /**
   * Writes numBytes of the buffer data to the address in flash specified
   * by addr. This function will only set bits low for the bytes it is 
   * supposed to write to.If addr connot be written to for any reason returns
   * FAIL, otherwise returns SUCCESS.
   *
   * @returns SUCCESS or FAIL.
   */
  command error_t write(uint32_t addr, uint8_t* data, uint32_t numBytes);

  /**
   * Erases the block of flash that contains addr, setting all bits to 1.
   * If this function fails for any reason it will return FAIL, otherwise 
   * SUCCESS.
   *
   * @returns SUCCESS or FAIL.
   */
  command error_t erase(uint32_t addr);
}



