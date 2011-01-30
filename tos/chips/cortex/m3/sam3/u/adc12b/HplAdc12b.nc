// introduce interfaces for Hpl

#include "sam3uadc12bhardware.h"

interface HplAdc12b{

  async command void startConversion();
  async command void stopConversion();
  async command void enableConversion();

}
