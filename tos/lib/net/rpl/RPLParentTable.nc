/* Interface for retrieving a parent from the parent table.
 *
 * @author JeongGil Ko (John) <jgko@cs.jhu.edu>
 * @author Brad Campbell <bradjc@umich.edu>
 */

interface RPLParentTable {
  command parent_t* get(uint8_t parent_index);
}
