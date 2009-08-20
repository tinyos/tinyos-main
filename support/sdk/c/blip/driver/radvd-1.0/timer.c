/*
 *   $Id: timer.c,v 1.3 2009-08-20 17:03:05 sdhsdh Exp $
 *
 *   Authors:
 *    Pedro Roque		<roque@di.fc.ul.pt>
 *    Lars Fenneberg		<lf@elemental.net>
 *
 *   This software is Copyright 1996-2000 by the above mentioned author(s), 
 *   All Rights Reserved.
 *
 *   The license which is distributed with this software in the file COPYRIGHT
 *   applies to this software. If your distribution is missing this file, you
 *   may request it from <pekkas@netcore.fi>.
 *
 */

#include "config.h"
#include "includes.h"
#include "radvd.h"

static struct timer_lst timers_head = {
	{LONG_MAX, LONG_MAX},
	NULL, NULL,
	&timers_head, &timers_head
};

static void alarm_handler(int sig);
int inline check_time_diff(struct timer_lst *tm, struct timeval tv);

static void
schedule_timer(void)
{
	struct timer_lst *tm = timers_head.next;
	struct timeval tv;

	gettimeofday(&tv, NULL);

	if (tm != &timers_head)
	{
		struct itimerval next;
	       
	        memset(&next, 0, sizeof(next));
	       
	        timersub(&tm->expires, &tv, &next.it_value);

		signal(SIGALRM, alarm_handler);

		if ((next.it_value.tv_sec > 0) || 
				((next.it_value.tv_sec == 0) && (next.it_value.tv_usec > 0)))
		{
			dlog(LOG_DEBUG, 4, "calling alarm: %ld secs, %ld usecs", 
					next.it_value.tv_sec, next.it_value.tv_usec);

			if(setitimer(ITIMER_REAL, &next,  NULL))
				flog(LOG_WARNING, "schedule_timer setitimer for %ld.%ld failed: %s",
					next.it_value.tv_sec, next.it_value.tv_usec, strerror(errno));
		}
		else
		{
			dlog(LOG_DEBUG, 4, "next timer has already expired, queueing signal");	
			kill(getpid(), SIGALRM);
		}
	}
}

void
set_timer(struct timer_lst *tm, double secs)
{
	struct timeval tv;
	struct timer_lst *lst;
	sigset_t bmask, oldmask;
	struct timeval firein;

	dlog(LOG_DEBUG, 3, "setting timer: %.2f secs", secs);

	firein.tv_sec = (long)secs;
	firein.tv_usec = (long)((secs - (double)firein.tv_sec) * 1000000);

	dlog(LOG_DEBUG, 5, "setting timer: %ld secs %ld usecs", firein.tv_sec, firein.tv_usec);

	gettimeofday(&tv, NULL);
	timeradd(&tv, &firein, &tm->expires);

	sigemptyset(&bmask);
	sigaddset(&bmask, SIGALRM);
	sigprocmask(SIG_BLOCK, &bmask, &oldmask);

	lst = &timers_head;

	/* the timers are in the list in the order they expire, the soonest first */
	do {
		lst = lst->next;
	} while ((tm->expires.tv_sec > lst->expires.tv_sec) ||
		 ((tm->expires.tv_sec == lst->expires.tv_sec) && 
		  (tm->expires.tv_usec > lst->expires.tv_usec)));

	tm->next = lst;
	tm->prev = lst->prev;
	lst->prev = tm;
	tm->prev->next = tm;

	dlog(LOG_DEBUG, 5, "calling schedule_timer from set_timer context");
	schedule_timer();

	sigprocmask(SIG_SETMASK, &oldmask, NULL);
}

void
clear_timer(struct timer_lst *tm)
{
	sigset_t bmask, oldmask;

	sigemptyset(&bmask);
	sigaddset(&bmask, SIGALRM);
	sigprocmask(SIG_BLOCK, &bmask, &oldmask);
	
	tm->prev->next = tm->next;
	tm->next->prev = tm->prev;
	
	tm->prev = tm->next = NULL;
	
	dlog(LOG_DEBUG, 5, "calling schedule_timer from clear_timer context");
	schedule_timer();

	sigprocmask(SIG_SETMASK, &oldmask, NULL);
}

static void
alarm_handler(int sig)
{
	struct timer_lst *tm, *back;
	struct timeval tv;
	gettimeofday(&tv, NULL);
	tm = timers_head.next;

	/*
	 * This handler is called when the alarm goes off, so at least one of
	 * the interfaces' timers should satisfy the while condition.
	 *
	 * Sadly, this is not always the case, at least on Linux kernels:
	 * see http://lkml.org/lkml/2005/4/29/163. :-(.  It seems some
	 * versions of timers are not accurate and get called up to a couple of
	 * hundred microseconds before they expire.
	 *
	 * Therefore we allow some inaccuracy here; it's sufficient for us
	 * that a timer should go off in a millisecond.
	 */

	/* unused timers are initialized to LONG_MAX so we skip them */
	while (tm->expires.tv_sec != LONG_MAX && check_time_diff(tm, tv))
	{		
		tm->prev->next = tm->next;
		tm->next->prev = tm->prev;

		back = tm;
		tm = tm->next;
		back->prev = back->next = NULL;

		(*back->handler)(back->data);
	}

	dlog(LOG_DEBUG, 5, "calling schedule_timer from alarm_handler context");
	schedule_timer();
}


void
init_timer(struct timer_lst *tm, void (*handler)(void *), void *data)
{
	memset(tm, 0, sizeof(struct timer_lst));
	tm->handler = handler;
	tm->data = data;
}

int inline
check_time_diff(struct timer_lst *tm, struct timeval tv)
{
	struct itimerval diff;
	memset(&diff, 0, sizeof(diff));

	#define ALLOW_CLOCK_USEC 1000

	timersub(&tm->expires, &tv, &diff.it_value);
	dlog(LOG_DEBUG, 5, "check_time_diff, difference: %ld sec + %ld usec",
		diff.it_value.tv_sec, diff.it_value.tv_usec);

	if (diff.it_value.tv_sec <= 0) {
		/* already gone, this is the "good" case */
		if (diff.it_value.tv_sec < 0)
			return 1;
#ifdef __linux__ /* we haven't seen this on other OSes */
		/* still OK if the expiry time is not too much in the future */
		else if (diff.it_value.tv_usec > 0 &&
		            diff.it_value.tv_usec <= ALLOW_CLOCK_USEC) {
			dlog(LOG_DEBUG, 4, "alarm_handler clock was probably off by %ld usec, allowing %u",
			     tm->expires.tv_usec-tv.tv_usec, ALLOW_CLOCK_USEC);
			return 2;
		}
#endif /* __linux__ */
		else /* scheduled intentionally in the future? */
			return 0;
	}
	return 0;
}
