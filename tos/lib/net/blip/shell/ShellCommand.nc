
interface ShellCommand {

  /*
   * evaluate the command that this command provides
   * @argc the number of arguments
   * @argv the arguments
   * @return a string to send back as the reply to the shell client.
   *         if NULL, nothing is sent.
   */
  event char *eval(int argc, char **argv);

  /*
   * request a buffer.  The result of this command may be returned
   * from 'eval', but otherwise the buffer may not be used outside of
   * the context it is called from.
   */
  command char *getBuffer(uint16_t len);

  /*
   * write a string to the shell buffer; if no client is connected it
   * will fail silently
   */
  command void write(char *str, int len);
}
