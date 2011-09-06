/** 
 * Standard Benchmark Database file
 * ------------------------------------------------------------------------
 * This is a no-modify file, keep it untouched.
 */


/* Throughput problems
 * ----------------------
 * 
 * In these problems, edges are present with continous message sending policies
 * meaning that motes try to send messages as fast as they can.
 * Such edges next to each other influence each other's behaviour.
 *
 * All of these benchmarks can be run with 4 motes (not all requires 4).
 */

#ifndef EXCLUDE_STANDARD_THROUGHPUT

/** One-edge throughput **/
_BMARK_START_(10)
  { 1, 2, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** Two-edge throughput **/
_BMARK_START_(11)
  { 1, 2, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID },
  { 2, 1, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** Three-edge, circle-style throughput **/
_BMARK_START_(12)
  { 1, 2, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID },
  { 2, 3, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID },
  { 3, 1, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** One broadcast flooding mote **/
_BMARK_START_(13)
  { 4, ALL, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** Two broadcast flooding motes **/
_BMARK_START_(14)
  { 4, ALL, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID },
  { 3, ALL, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** Three broadcast flooding motes **/
_BMARK_START_(15)
  { 4, ALL, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID },
  { 3, ALL, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID },
  { 2, ALL, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** Two parallel throughput links **/
_BMARK_START_(16)
  { 1, 2, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID },
  { 3, 4, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** Two parallel throughput links, one with ACK request**/
_BMARK_START_(17)
  { 1, 2, NO_TIMER , { SEND_ON_INIT,  0, NEED_ACK, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID },
  { 3, 4, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** One throughput link next to one broadcast flooding mote **/
_BMARK_START_(18)
  { 1, 2, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID },
  { 3, ALL, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** Hidden terminal problem (2 motes flooding the same mote) **/
_BMARK_START_(19)
  { 1, 2, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID },
  { 3, 2, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** Hidden terminal problem (3 motes flooding the same mote) **/
_BMARK_START_(20)
  { 1, 4, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID },
  { 2, 4, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID },
  { 3, 4, NO_TIMER , { SEND_ON_INIT,  0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID }
_BMARK_END_

#endif // EXCLUDE_STANDARD_THROUGHPUT

/* Collision problems
 * ----------------------
 * 
 * In these problems, communication is based on timers. Since all 4 timers that
 * are supported can be highly customized, different timer configurations could
 * result different scenarios.
 * If the sending windows match, collision occur, thus the name of these benchmarks.
 *
 * All of these benchmarks can be run with 4 motes.
 */ 

#ifndef EXCLUDE_STANDARD_COLLISION

/** Two parallel timer-based links **/
_BMARK_START_(30)
  { 1, 2, {TIMER(1), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },
  { 3, 4, {TIMER(2), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** Two parallel timer-based links, broadcasting **/
_BMARK_START_(31)
  { 4, ALL, {TIMER(1), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },
  { 3, ALL, {TIMER(2), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** Three parallel timer-based links, broadcasting **/
_BMARK_START_(32)
  { 4, ALL, {TIMER(1), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },
  { 3, ALL, {TIMER(2), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID }, 
  { 2, ALL, {TIMER(3), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** Three parallel timer-based links, direct links **/
_BMARK_START_(33)
  { 1, 2, {TIMER(1), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },
  { 2, 3, {TIMER(2), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },
  { 3, 4, {TIMER(3), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** Three timer-based links having a common destination **/
_BMARK_START_(34)
  { 1, 4, {TIMER(1), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },
  { 2, 4, {TIMER(2), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },
  { 3, 4, {TIMER(3), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** One timer-based link influenced by a parallel flooding link **/
_BMARK_START_(35)
  { 1, 2, {TIMER(1), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },
  { 3, 4, NO_TIMER, { SEND_ON_INIT, 0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** One timer-based link influenced by a parallel flooding link (broadcast) **/
_BMARK_START_(36)
  { 1, 2, {TIMER(1), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },
  { 4, ALL, NO_TIMER, { SEND_ON_INIT, 0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID }
_BMARK_END_

#endif // EXCLUDE_STANDARD_COLLISION

/* Forwarding problems
 * ----------------------
 * 
 * In these problems, communication initiation is based on timers. Additionally, networks
 * are created such a way that messages are to be forwarded, so if any mote hears a message,
 * it should forward it on at least one link.
 *
 * All of these benchmarks can be run with 6 motes (not all requires 6).
 */ 

#ifndef EXCLUDE_STANDARD_FORWARDING

/** M2 forwards to M1 what it hears from M1 **/
_BMARK_START_(50)
  { 1, 2, {TIMER(1), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), REPLY_ON(1), START_MSG_ID },
  { 2, 1, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** M2 forwards to M1 what it hears from M1. 
    Also, a flooding broadcast disturbance edge is present. **/
_BMARK_START_(51)
  { 1, 2, {TIMER(1), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), REPLY_ON(1), START_MSG_ID },
  { 2, 1, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },
  { 4, ALL, NO_TIMER, { SEND_ON_INIT, 0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** A message chain with 4 motes. M1 initiates, M2,M3 forwards to a sink mote, M4. **/
_BMARK_START_(52)
  { 1, 2, {TIMER(1), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), REPLY_ON(1), START_MSG_ID },
  { 2, 3, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), REPLY_ON(2), START_MSG_ID },
  { 3, 4, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** A message chain with 6 motes. M1 initiates, M2,M3,M4,M5 forwards to a sink mote, M6. **/
_BMARK_START_(53)
  { 1, 2, {TIMER(1), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), REPLY_ON(1), START_MSG_ID },
  { 2, 3, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), REPLY_ON(2), START_MSG_ID },
  { 3, 4, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), REPLY_ON(3), START_MSG_ID },
  { 4, 5, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), REPLY_ON(4), START_MSG_ID },
  { 5, 6, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** Two distinct, parallel forwarding chains: M1->M2->M3 and M4->M5->M6. **/
_BMARK_START_(54)
  { 1, 2, {TIMER(1), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), REPLY_ON(1), START_MSG_ID },
  { 2, 3, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },
  { 4, 5, {TIMER(2), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), REPLY_ON(3), START_MSG_ID },
  { 5, 6, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** A "message collector" binary tree:
    M1, M2 transmits to M4, M4 forwards these messages to M5.
    M3 also transmits to M5.
    M5 forwards those messages that are heared either from M4 or M3 to M6.    
 **/
_BMARK_START_(55)
  { 1, 4, {TIMER(1), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), REPLY_ON(3), START_MSG_ID },
  { 2, 4, {TIMER(2), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), REPLY_ON(3), START_MSG_ID },
  { 3, 5, {TIMER(3), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), REPLY_ON(4), START_MSG_ID },      
  { 4, 5, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), REPLY_ON(4), START_MSG_ID },
  { 5, 6, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** A "noisy message collector" binary tree:
    M1, M2 transmits to M4, M4 forwards these messages to M5.
    M3 also transmits to M5.
    M6 acts as a disturbance mote, continously broadcasting.   
 **/
_BMARK_START_(56)
  { 1, 4, {TIMER(1), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), REPLY_ON(3), START_MSG_ID },
  { 2, 4, {TIMER(2), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), REPLY_ON(3), START_MSG_ID },
  { 3, 5, {TIMER(3), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },
  { 4, 5, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },
  { 6, ALL, NO_TIMER, { SEND_ON_INIT, 0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** A near complete binary tree message collector network.
    There are three chains :  M1 -> M4 -> M6,  M2 -> M5 -> M6, and M3 -> M5 -> M6.
 **/
_BMARK_START_(57)
  { 1, 4, {TIMER(1), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), REPLY_ON(3), START_MSG_ID },
  { 2, 5, {TIMER(2), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), REPLY_ON(4), START_MSG_ID },
  { 3, 5, {TIMER(3), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), REPLY_ON(4), START_MSG_ID },
  { 4, 6, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },
  { 5, 6, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** A "message disseminator" binary tree:
    M6 transmits to M5 which duplicates these messages towards M4 and M3. M3 is a sink, while 
    M4 also forwards the messages to M1 and M2.
 **/
_BMARK_START_(58)
  { 6, 5, {TIMER(1), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), REPLY_ON(1) | REPLY_ON(2), START_MSG_ID },
  { 5, 4, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), REPLY_ON(3) | REPLY_ON(4), START_MSG_ID },
  { 5, 3, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },      
  { 4, 1, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },
  { 4, 2, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** A "noisy message disseminator" binary tree:
    M5 sends messages to M4 and M3. M3 is a sink, while M4 forwards the messages to M1 and M2.
    M6 acts as a disturbance mote, continously broadcasting.
 **/
_BMARK_START_(59)
  { 5, 4, {TIMER(1), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), REPLY_ON(2) | REPLY_ON(3), START_MSG_ID },
  { 5, 3, {TIMER(2), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },
  { 4, 1, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },
  { 4, 2, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },
  { 6, ALL, NO_TIMER, { SEND_ON_INIT, 0, 0, 0, 0 }, NUM(INFINITE), NO_REPLY, START_MSG_ID }
_BMARK_END_

/** A near complete binary tree message dissemination network.
    There are three chains :  M6 -> M4 -> M1,  M6 -> M5 -> M2, and M6 -> M5 -> M3.
 **/
_BMARK_START_(60)
  { 6, 4, {TIMER(1), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), REPLY_ON(2), START_MSG_ID },
  { 6, 5, {TIMER(2), 0}, { SEND_ON_TIMER, 0, 0, 0, 0 }, NUM(1), REPLY_ON(3) | REPLY_ON(4), START_MSG_ID },
  { 4, 1, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID },
  { 5, 2, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID }, 
  { 5, 3, NO_TIMER, { SEND_ON_REQ, 0, 0, 0, 0 }, NUM(1), NO_REPLY, START_MSG_ID } 
_BMARK_END_

#endif // EXCLUDE_STANDARD_FORWARDING

