#ifndef LPL_H
#define LPL_H

/**
 * Amount of time, in milliseconds, to keep the radio on after
 * a successful receive addressed to this node
 */
#ifndef DELAY_AFTER_RECEIVE
#define DELAY_AFTER_RECEIVE 100
#endif

/**
 * The LPL defaults to stay-on.
 */
#ifndef LPL_DEF_LOCAL_WAKEUP
#define LPL_DEF_LOCAL_WAKEUP 0
#endif

#ifndef LPL_DEF_REMOTE_WAKEUP
#define LPL_DEF_REMOTE_WAKEUP 0
#endif

#endif
