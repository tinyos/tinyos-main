README for TestPowerManager
Author/Contact: tinyos-help@millennium.berkeley.edu
@author Kevin Klues <klueska@cs.wustl.edu>

Description:

Please refer to TEP 115 for more information about the components
this application is used to test.

This application tests the functionality of the various non-mcu power
management components that are used with non-virtualized devices.
Different policies can be tested by making a simple wiring change
in the "MyComponentsC" configuration.  This component is used
to simulate a non-virtualized device that has a set of resource users
that need to share it.  An arbiter component is used to control
access to the resource, and one of the 6 default power management
policies can be chosen to perform shutdown of the device whenever
it is no longer in use.  Depending on the power management policy
chosen, power down of the device will occur through either the
AsyncStdControl, StdControl, or SplitControl interfaces and will
occur at different times.  The application itself simply wires to
"MyComponentC" and is unaware of the power management policy being
used by it.

Two resource users are created by the application to share the
"MyComponent" resource.  They each hold the device for a specific
amount of time and then release it.  There is some delay between
when the first user releases the resource and when the second one
requests it.  Since the resource uses one of the default power
management polices, we expect the device to be automatically shutdown
whenever both resource users do not require use of the resource.
Different shutdown times will occur, however, depeneding on which
power mangament policy is under test.  The various leds are used to
indicate which resource user currently has control of the resource,
and whether the "MyComponent" device is currently powered on or not.

  -- Led0 0n  -> MyComponent" powered on
  -- Led0 0ff -> MyComponent" powered off
  -- Led1 0n  -> Resource 0 controls "MyComponent" resource
  -- Led1 0ff -> Resource 0 does not control "MyComponent" resource
  -- Led2 0n  -> Resource 1 controls "MyComponent" resource
  -- Led2 0ff -> Resource 1 does not control "MyComponent" resource

This application demonstrates, therefore, not only how one would use
one of the provided power management polices to control the power
states of a non-virtualized device, but also how to wire everything
together.

Tools:

None.

Known bugs/limitations:

None.

