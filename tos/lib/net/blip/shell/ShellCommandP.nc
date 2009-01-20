
generic module ShellCommandP(char cmd_name[]) {
  uses interface RegisterShellCommand;
} implementation {
  event char *RegisterShellCommand.getCommandName() {
    return cmd_name;
  }
}
