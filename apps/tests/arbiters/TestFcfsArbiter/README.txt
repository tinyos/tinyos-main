README for TestFcfsArbiter
Author/Contact: tinyos-help@millennium.berkeley.edu
@author Kevin Klues <klueska@cs.berkeley.edu>

Description:

Please refer to TEP 108 for more information about the components
this application is used to test.

This application is used to test the functionality of the
FcfsArbiter component developed using the Resource
interface.  Three Resource users are created and all three request
control of the resource before any one of them is granted it.
Once the first user is granted control of the resource, a timer
is set to allow this user to have control of it for a specific
amount of time.  Once this timer expires, the resource is released
and then immediately requested again.  Upon releasing the resource
control will be granted to the next user that has requested it in FCFS
order.  Initial requests are made by the three resource users in the
following order.
  -- Resource 0
  -- Resource 2
  -- Resource 1
It is expected then that using a first-come-first-serve policy, control of the
resource will be granted in the order of 0,2,1 and the Leds
corresponding to each resource will flash whenever this occurs.
  -- Led 0 -> Resource 0
  -- Led 1 -> Resource 1
  -- Led 2 -> Resource 2

Tools:

None.

Known bugs/limitations:

None.

