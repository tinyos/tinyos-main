README for TestAM
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

TestAM sends active message broadcasts at 1Hz and blinks LED 0 whenever 
it has sucessfully sent a broadcast. Whenever it receives one of these 
broadcasts from another node, it blinks LED 1.  It uses the radio HIL 
component ActiveMessageC, and its packets are AM type 240.  This application 
is useful for testing AM communication and the ActiveMessageC component.

Tools:

None.

Known bugs/limitations:

None.

