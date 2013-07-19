/**
 * Read interface for the maxim/dallas 48 bit ID chips
 */
/**
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 */

interface ReadId48  {
  // The ID is written into the buffer pointed to by id,
  // the buffer must be at least 6 bytes (or 48 bit) long.
  // Returns SUCCESS if id points to a buffer containing the id, error
  // otherwise.
  command error_t read (uint8_t *id);
}
