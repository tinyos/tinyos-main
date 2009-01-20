/**
 *  An interface for obtaining the identification data of an
 *  image. The pointer returned by readDone will be destroyed by the
 *  next read.
 *
 *  @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 *  @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

interface DelugePatch
{
  command error_t decodePatch(uint8_t imgNumPatch, uint8_t imgNumSrc, uint8_t imgNumDst);
  event void decodePatchDone(uint8_t imgNumPatch, uint8_t imgNumSrc, uint8_t imgNumDst, error_t error);
}
