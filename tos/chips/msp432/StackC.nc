/**
 * Basic CPU stack interface.
 *
 * See Stack.nc (interface) for details.
 *
 * @author Eric B. Decker
 */


configuration StackC {
  provides interface Stack;
}

implementation {
  components StackP;
  Stack = StackP;
}
