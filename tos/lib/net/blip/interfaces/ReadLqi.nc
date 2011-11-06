/* Platform-independent wrappers for commonly-provided link metrics.  
 */

interface ReadLqi {
  /* Read the Link Quality Indicator */
  command uint8_t readLqi(message_t *msg);
  /* Read the Received Signal Strength Indicator */
  command uint8_t readRssi(message_t *msg);  
}
