typedef uint32_t time_t;

#define HAVE_WDAY
#undef HAVE_DST

struct tm
{
  int tm_sec;			/* Seconds.	[0-60] (1 leap second) */
  int tm_min;			/* Minutes.	[0-59] */
  int tm_hour;			/* Hours.	[0-23] */
  int tm_mday;			/* Day.		[1-31] */
  int tm_mon;			/* Month.	[0-11] */
  int tm_year;			/* Year	- 1900.  */
#ifdef HAVE_WDAY
  int tm_wday;			/* Day of week.	[0-6] */
#endif
  int tm_yday;			/* Days in year.[0-365]	*/
  int tm_isdst;			/* DST.		[-1/0/1]*/

#ifdef __UCLIBC_HAS_TM_EXTENSIONS__
#ifdef	__USE_BSD
  long int tm_gmtoff;		/* Seconds east of UTC.  */
  __const char *tm_zone;	/* Timezone abbreviation. */
#else
  long int __tm_gmtoff;		/* Seconds east of UTC.  */
  __const char *__tm_zone;	/* Timezone abbreviation. */
#endif
#endif /* __UCLIBC_HAS_TM_EXTENSIONS__ */
};
