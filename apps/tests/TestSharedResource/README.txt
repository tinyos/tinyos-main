README for TestSharedResource
Author/Contact: tinyos-help@millennium.berkeley.edu
@author Kevin Klues <klues@tkn.tu-berlin.de>

Description:

This application is used to test the use of Shared Resources.  
Three Resource users are created and all three request
control of the resource before any one of them is granted it.
Once the first user is granted control of the resource, it performs
some operation on it.  Once this operation has completed, a timer
is set to allow this user to have control of it for a specific
amount of time.  Once this timer expires, the resource is released
and then immediately requested again.  Upon releasing the resource
control will be granted to the next user that has requested it in 
round robin order.  Initial requests are made by the three resource 
users in the following order.
  -- Resource 0
  -- Resource 2
  -- Resource 1
It is expected then that using a round robin policy, control of the
resource will be granted in the order of 0,1,2 and the Leds
corresponding to each resource will flash whenever this occurs.
  -- Led 0 -> Resource 0
  -- Led 1 -> Resource 1
  -- Led 2 -> Resource 2

Tools:

None.

Known bugs/limitations:

None.

