/*
* The ASKNFSK Pin is not connected on the eyes platforms...
*/

module Tda5250ASKNFSKFakePinP {
  provides interface	GeneralIO;
}

implementation {
  async command void GeneralIO.set(){}
  async command void GeneralIO.clr(){}
  async command void GeneralIO.toggle(){}
  async command bool GeneralIO.get(){ return FALSE; }
  async command void GeneralIO.makeInput(){}
  async command bool GeneralIO.isOutput() { return FALSE; }
  async command void GeneralIO.makeOutput(){}
  async command bool GeneralIO.isInput() { return FALSE; }
}
