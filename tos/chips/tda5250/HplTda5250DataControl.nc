 /**
 * Interface for controlling the data interface of the TDA5250 Radio.
 * This interface lets you switch between Tx and Rx.
 * In conjunction to this the HplTda5250Data interface 
 * is used for the actual receiving and sending of data.
 *
 * @see HplTda5250Data
 * @author Philipp Huppertz (huppertz@tkn.tu-berlin.de)
 */
interface HplTda5250DataControl {  

/**
   * Sets the radio to transmit. 
   * 
   * @return SUCCESS on success
   *         FAIL otherwise.
	*/
  async command error_t setToTx();


  /**
   * Sets the radio to receive.
   *
   * @return SUCCESS on success
   *         FAIL otherwise.
	*/
  async command error_t setToRx();
  
}
