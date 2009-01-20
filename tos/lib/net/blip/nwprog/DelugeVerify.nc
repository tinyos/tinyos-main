/**
 *  An interface for obtaining the identification data of an
 *  image. The pointer returned by readDone will be destroyed by the
 *  next read.
 *
 *  @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 *  @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

interface DelugeVerify
{
  command error_t verifyImg(uint8_t imgNum);
  event void verifyImgDone(uint8_t imgNum, error_t error);
}
