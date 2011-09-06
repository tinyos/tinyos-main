/** 
 * User Defined Benchmark Database file
 * ------------------------------------------------------------------------
 * 
 * This is a user-modifiable file, keep it clean, and stay to the rules below.
 *
 * Instructions for how to define a benchmark:
 *  1, All benchmarks MUST begin with a _BMARK_START_(X) macro, where X is its unique identifier.
 *     Note that if multiple benchmarks have the same id, only the first is seen by the program,
 *     others are ignored -- thus only eating expensive memory.
 *     Valid ids are from [200,...,255], lower values are reserved for standard benchmarks.
 *
 *  2, All benchmarks MUST end with a _BMARK_END_ macro.
 *  3, Between these macros, the edges (allowed communication links between two)
 *     separate motes) of the modeled network are enlisted.
 *     
 *     Each edge is a 7-element structure :
 *     { SENDER, RECEIVER, TIMER_DESC, POLICY_DESC, MSG_COUNT, REPLY, 'START_MSG_ID' }
 *      
 *  4, SENDER:    - any positive number, denoting the mote id
 *     RECEIVER:  - any positive number other than the sender, denoting the mote id,
 *                - 'ALL', denoting all motes. This automatically implies
 *                   that on this edge, broadcasting is used
 * 
 *     TIMER_DESC:
 *                - 'NO_TIMER', if timers are not used on this edge
 *                - {START_TIMER_DESC, STOP_TIMER_DESC} otherwise
 *
 *     START_TIMER_DESC:
 *     STOP_TIMER_DESC:
 *                - '0', if sending/stopping is not initiated by a timer
 *                - 'TIMER(X)', representing the Xth timer, ex: TIMER(2)
 *     
 *     POLICY_DESC:
 *                - { SEND_TRIG, STOP_TRIG, ACK, 0, 0 }
 *     SEND_TRIG: - 'SEND_ON_REQ', to send only if implicitly required (see below)
 *                - 'SEND_ON_INIT', to send message on benchmark start,
 *                - 'SEND_ON_TIMER', to send message on timer event (
 *                  see START_TIMER_DESC)
 *     STOP_TRIG: - '0', if no message sending stopper is required
 *                - 'STOP_ON_ACK', if message sending is required to stop on an ACK
 *                - 'STOP_ON_TIMER', if message sending is req. to stop on a timer event (
 *                  see STOP_TIMER_DESC)
 *     ACK:       - '0', if acknowledgements are not requested
 *                - 'NEED_ACK', if acknowledgements are requested
 *
 *     MSG_COUNT: - NUM(X), denoting X message(s) to send, where X can be from [1,..,255].
 *                - NUM(INFINITE), denoting continous message sending.
 *
 *     REPLY:     - 'NO_REPLY', if message is not required to send on reception
 *                - 'REPLY_EDGE(X)', if message is to send on reception on edge X.
 *                - 'REPLY_EDGE(X) | REPLY_EDGE(Y) | ...', if message is to send on reception 
 *                   on edge X AND on edge Y also.
 *                   (the edge ids count from zero in the current benchmark)
 *
 * By specifying the edges, the required mote count is implicitly determined by the maximal mote id
 * present either in the sender or receiver sections of the edge descriptions. (This can aslo be
 * overridden with a command line option (-mc) of the PC program. )
 *
 * In the following example, the implied mote count is 1:
 * _BMARK_START_(202)
 *  { 1, ALL, NO_TIMER , ... }
 * _BMARK_END_
 *
 * However, if someone would like to increase this number (ex. to 4), there is a naughty trick:
 * _BMARK_START_(202)
 *  { 4, ALL, NO_TIMER , ... }
 * _BMARK_END_
 *
 * You are encouraged to use this motecount-force, rather than depending on the command-line option.
 *
 * For complete examples, see the demo benchmarks below.
 * These benchmarks are only for demo and reference purposes, so do not hesitate to erase them / comment them out to reduce the memory overhead.
 *  
 */

// Send 10 messages (Mote1 -> Mote 2) when the test starts, and that's it.
_BMARK_START_(200)
  { 1, 2, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(10), NO_REPLY, START_MSG_ID }
_BMARK_END_

// Send 10 messages (Mote2 -> Mote 1) when the test starts, and that's it.
_BMARK_START_(201)
  { 2, 1, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(10), NO_REPLY, START_MSG_ID }
_BMARK_END_

/* Send 10 broadcast messages when the test starts.
 * Note: try this benchmark with different motecount options on the PC side
 *  - if motecount is set to 1 (default for this benchmark), no reception is seen in receiver side stats,
 *  - if motecount is set to 2 (-mc 2): 10 reception (Mote 2 is now present, hearing Mote 1),
 *  - if motecount is set to 5 (-mc 5): 40 reception (Mote 2,3,4,5 are present, hearing Mote 1),
 *  - ...
 */
_BMARK_START_(202)
  { 1, ALL, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(10), NO_REPLY, START_MSG_ID }
_BMARK_END_

// Send 10 messages when the test starts, and request acks.
_BMARK_START_(203)
  { 1, 2, NO_TIMER , { SEND_ON_INIT,  0, NEED_ACK, 0, 0 }, NUM(10), NO_REPLY, START_MSG_ID }
_BMARK_END_

// Send a message and request ack for it. If not acked, fallback at most 5 times.
_BMARK_START_(204)
  { 1, 2, NO_TIMER , { SEND_ON_INIT, STOP_ON_ACK, NEED_ACK, 0, 0 }, NUM(5), NO_REPLY, START_MSG_ID }
_BMARK_END_

// Mote 1 sends 3 messages to Mote 2.
// Mote 2 sends messages to Mote1, stops when ack received and sends at most 7 messages if no ack received.
_BMARK_START_(205)
  { 1, 2, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(3), NO_REPLY, START_MSG_ID },
  { 2, 1, NO_TIMER , { SEND_ON_INIT,  STOP_ON_ACK, NEED_ACK, 0, 0 }, NUM(7), NO_REPLY, START_MSG_ID }
_BMARK_END_

// Start sending continously messages when the test starts. Message sending stops when the test stops.
_BMARK_START_(206)
  { 1, 2, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID }
_BMARK_END_

/**
 * Mote 1 starts contin. sending msgs to Mote 2 when the test starts. (1st edge)
 * Also Mote 1 is sending cont. broadcast msgs. (2nd edge)
 * Mote 3 sends at most 100 messages to Mote 1, request acks, and if it receives an ack, stops. (3rd edge)
 *
 * Note that this way the broadcast messages (2nd edge) are heared by Mote 2 and Mote 3, so the receiver side
 * statistics will be the double of the sender side ones on the 2nd edge. (Since every broadcast message sent by Mote 1 is heared by two motes!)
 */
_BMARK_START_(207)
  { 1, 2  , NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID },
  { 1, ALL, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID },
  { 3, 1  , NO_TIMER , { SEND_ON_INIT,  STOP_ON_ACK, 0, 0, 0 }, NUM(100), NO_REPLY, START_MSG_ID }
_BMARK_END_

// Send one message on every timer tick. Timer1 is used.
_BMARK_START_(208)
  { 1, 2, {TIMER(1),0} , { SEND_ON_TIMER,  0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID }
_BMARK_END_

/* 1st edge: Send at most 10 messages on every timer tick. If ack received, stop sending. Timer1 is used.
 * 2nd edge: Send one broadcast message to every node when Timer2 tickens.
 */
_BMARK_START_(209)
  { 1, 2, {TIMER(1),0} , { SEND_ON_TIMER,  STOP_ON_ACK, 0, 0, 0 }, NUM(10), NO_REPLY, START_MSG_ID },
  { 1, ALL, {TIMER(2),0} , { SEND_ON_TIMER,  0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID }
_BMARK_END_

/* Start cont. sending messages on every timer tick of Timer1, and stop sending if Timer2 tickens.
 * By changing the type (oneshot/periodic) and frequency of the timers, different traffic patterns are 
 * likely to be generated.
 */
_BMARK_START_(210)
  { 1, 2, {TIMER(1),TIMER(2)} , { SEND_ON_TIMER,  STOP_ON_TIMER, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID }
_BMARK_END_

/* Mote 1 sends 3 messages on every timer tick of Timer1.
 * Mote 2 starts cont. sending messages when the test starts and stops it if Timer2 tickens 
 * or receives an ack, whichever comes first.
 */
_BMARK_START_(211)
  { 1, 2, {TIMER(1), 0} , { SEND_ON_TIMER,  0, 0, 0, 0 }, NUM(3), NO_REPLY, START_MSG_ID },
  { 2, 1, {0,TIMER(2)} , { SEND_ON_INIT,  STOP_ON_TIMER | STOP_ON_ACK , 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID }
_BMARK_END_

/* Mote 1 sends 2 messages to Mote 2 on every Timer1 ticks. It stops (only sends one message) if Mote 2
 * acknowledges the message. 
 * If Mote 2 hears a message, it replies on edge 1 ( see REPLY_ON(1) of the 1st edge ), which means it 
 * will send one message to Mote 3 (2nd edge). 
 * Since REPLY_ON(2) is present in the 2nd edge, every time Mote 3 hears a message, it should reply on the 
 * 3rd edge: sends one message to Mote 1.
 */
_BMARK_START_(212)
  { 1, 2,   {TIMER(1),0}, { SEND_ON_TIMER,  STOP_ON_ACK, 0, 0, 0 }, NUM(2), REPLY_ON(1), START_MSG_ID },
  { 2, 3,   NO_TIMER , { SEND_ON_REQ,  0, 0, 0, 0 }, NUM(1), REPLY_ON(2), START_MSG_ID },
  { 3, 1,   NO_TIMER , { SEND_ON_REQ,  0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID }
_BMARK_END_

/* 1st edge : Mote 1 -> Mote 2: Exactly 2 messages on Timer1 ticks, request acks.
 *  - every time Mote 2 hears a message from this edge, it should reply on the 3rd edge ( see REPLY_ON(2) )
 * 2nd edge : Mote 3 -> Mote 2: One message on every Timer2 ticks, stop either on Timer3 ticks or on acks. 
 *  - note that in this case the STOP_ON_X policies are useless, since
 *    on this edge only one message is to be sent, so no use to 'stop' it...
 *  - every time Mote 2 hears a message from this edge, it should reply on the 3rd edge ( see REPLY_ON(2) )
 * 3rd edge : Mote 2 broadcasts exactly one message.
 *  - if anyone (Mote 1,Mote 3) hears it, it should reply on the 4th edge ( REPLY_ON(3) ). Since the 4th edge's
 *    sender is 3, this only applies for Mote 3.
 * 4th edge : Mote 3 -> Mote 1: Exactly 4 messages to transmit.
 *  - note that this edge has SEND_ON_INIT, so 4 messages are also transmitted when the test starts,
 *    not just when Mote 3 replies for messages it gets on the 3rd edge! 
 */
_BMARK_START_(213)
  { 1, 2,   {TIMER(1),0}, { SEND_ON_TIMER, 0, NEED_ACK, 0, 0 }, NUM(2), REPLY_ON(2), START_MSG_ID },
  { 3, 2,   {TIMER(2),TIMER(3)}, { SEND_ON_TIMER, STOP_ON_TIMER | STOP_ON_ACK, 0, 0, 0 }, NUM(1), REPLY_ON(2), START_MSG_ID },
  { 2, ALL, NO_TIMER    , { SEND_ON_REQ,  0, 0, 0, 0 }, NUM(1), REPLY_ON(3), START_MSG_ID },
  { 3, 1,   NO_TIMER    , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(4) , NO_REPLY, START_MSG_ID }
_BMARK_END_


