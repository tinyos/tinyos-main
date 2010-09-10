
generic configuration ShellCommandC(char cmd_name[]) {
  provides interface ShellCommand;
} implementation {

  enum {
    CMD_ID = unique("UDPSHELL_CLIENTCOUNT"),
  };

  components new ShellCommandP(cmd_name), UDPShellP;

  ShellCommandP.RegisterShellCommand ->  UDPShellP.RegisterShellCommand[CMD_ID];
  ShellCommand = UDPShellP.ShellCommand[CMD_ID];
}
