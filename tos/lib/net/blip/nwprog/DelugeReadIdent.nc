/**
 *  An interface for obtaining the identification data of an
 *  image. The pointer returned by readDone will be destroyed by the
 *  next read.
 *
 *  @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 *  @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

interface DelugeReadIdent
{
  command error_t readNumVolumes();
  command error_t readVolume(uint8_t imgNum);

  event void readNumVolumesDone(uint8_t validVolumes, uint8_t volumeFields, error_t error);
  event void readVolumeDone(uint8_t imgNum, DelugeIdent* ident, error_t error);

  //command error_t read(uint8_t imgNum);
  //event void readDone(uint8_t imgNum, DelugeIdent* ident, error_t error);
}
