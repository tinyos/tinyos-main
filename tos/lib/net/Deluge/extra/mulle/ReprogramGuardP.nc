// TODO(henrik) implement.

module ReprogramGuardP
{
  provides interface ReprogramGuard;
}
implementation
{
  enum {
    VTHRESH = 0x0, // 0V
  };
  task void sendOk()
  {
    signal ReprogramGuard.okToProgramDone(true);
  }

  command error_t ReprogramGuard.okToProgram()
  {
    post sendOk();
    return SUCCESS;
  }
}
