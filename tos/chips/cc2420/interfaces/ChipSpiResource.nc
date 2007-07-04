
/**
 * Interface for the SPI resource for an entire chip.  The chip accesses
 * the platform SPI resource one time, but can have multiple clients 
 * using the SPI bus on top.  When all of the clients are released, the
 * chip will normally try to release itself from the platforms SPI bus.
 * In some cases, this isn't desirable - so even though upper components
 * aren't actively using the SPI bus, they can tell the chip to hold onto
 * it so they can have immediate access when they need. 
 *
 * Any component that aborts a release MUST attempt the release at a later
 * time if they don't acquire and release the SPI bus naturally after the
 * abort.
 * 
 * @author David Moss
 */
interface ChipSpiResource {
  
  /**
   * The SPI bus is about to be automatically released.  Modules that aren't
   * using the SPI bus but still want the SPI bus to stick around must call
   * abortRelease() within the event.
   */
  async event void releasing();

  
  /**
   * Abort the release of the SPI bus.  This must be called only with the
   * releasing() event
   */
  async command void abortRelease();
  
  /**
   * Release the SPI bus if there are no objections
   * @return SUCCESS if the SPI bus is released from the chip.
   *      FAIL if the SPI bus is already in use.
   *      EBUSY if some component aborted the release.
   */
  async command error_t attemptRelease();
  
}
