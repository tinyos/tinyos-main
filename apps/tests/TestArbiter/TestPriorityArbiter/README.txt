README for TestPriorityArbiter
Author/Contact: tinyos-help@millennium.berkeley.edu
@author Kevin Klues <klues@tkn.tu-berlin.de>
@author Philipp Huppertz <huppertz@tkn.tu-berlin.de>

Description:

Please refer to TEP 108 for more information about the components
this application is used to test.

This application is used to test the functionality of the
FcfsPriorityArbiter component developed using the Resource
interface. 
 
In this test there are 4 users of one resource. The leds indicate which
user is the owner of the resource:
 - normal priority client 1  - led 0
 - normal priority client 2  - led 1
 - power manager             - led 2
 - high priority client      - led 0 and led 1 and led 2
 
The short flashing of the according leds inidicate that a user has requested the
resource. The users have the following behaviour:
 - normal priority clients are idle for a period of time before requesting the resource. 
   If they are granted the resource they will use it for a specific amount of time before releasing it.
 - power manager only request the resource if its idle. It releases the resource immediatly 
   if there is a request from another client.
 - high priority client behaves like a normal client but it will release the resource 
   after a shorter period of time if there are requests from other clients. 

The poliy of the arbiter should be FirstComeFirstServed with one exception: 
If the high priority client requests the resource, the resource will be granted to the 
high priority client after the release of the current owner regardless of the internal queue of the arbiter. 
After the high priority client releases the resource the normal FCFS arbitration resumes.

Tools:

None.

Known bugs/limitations:

None.

