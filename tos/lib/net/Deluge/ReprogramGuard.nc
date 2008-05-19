interface ReprogramGuard
{
  command error_t okToProgram();
  event void okToProgramDone(bool ok);
}
