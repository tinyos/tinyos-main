/* radioMode in enableBluetooth() can be set to one of the following modes,
 see the RovingNetworks AT command set for further details on module configuration */

#ifndef ROVINGNETWORKS_H
#define ROVINGNETWORKS_H
enum {
  SLAVE_MODE,
  MASTER_MODE,
  TRIGGER_MASTER_MODE,
  AUTO_MASTER_MODE    
};

enum { 
  NADA,
  INITIAL,
  FINAL
};
/*
const char * SETMODE =  "SM,";
const char * SETMASTERMODE =  "SM,1";
const char * SETSLAVEMODE =   "SM,0";
const char * DISCOVERRADIOS = "I,";
const char * DISCOVERRADIOS2 = ",0";

const char * SETFASTBAUD    = "SU,115";
const char * ENTERCOMMANDMODE = "$$$";
const char * SETSLEEPMODE   = "SW,0300";
const char * DIALRADIO      = "C,";
const char * HANGUPRADIO    = "R,1";
const char * WAKERADIO      = "";
*/
#endif
