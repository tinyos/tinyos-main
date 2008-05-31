// Runtime checks for Deputy programs.

// This file is included in deputy_lib and also at the start of every
// Deputy output file.  Before this file is included you must define
// DEPUTY_ALWAYS_STOP_ON_ERROR if you want to optimize the checks.

// Note "volatile": We currently use volatile everywhere so that these
// checks work on any kind of pointer.  In the future, we may want to
// investigate the performance impact of this annotation in the common
// (non-volatile) case.

// Use inline even when not optimizing for speed, since it prevents
// warnings that would occur due to unused static functions.
#ifdef DEPUTY_ALWAYS_STOP_ON_ERROR
  #define INLINE inline __attribute__((always_inline))
#else
  #define INLINE inline
#endif

#define __LOCATION__        0
#define __LOCATION__FORMALS int flid
#define __LOCATION__ACTUALS flid

#ifndef asmlinkage
#define asmlinkage
#endif

#ifndef noreturn
#define noreturn __attribute__((noreturn))
#endif

#if defined(__KERNEL__) && defined(DEPUTY_KERNEL_COVERAGE)
INLINE static
unsigned int read_pc()
TRUSTED {
        unsigned int pc;

        asm("movl %%ebp, %0" : "=r"(pc));

        return *((unsigned int *)pc + 1);
}

extern void checkBitArrayAdd(unsigned int addr);
#endif

extern asmlinkage 
void deputy_fail_mayreturn(__LOCATION__FORMALS);

extern asmlinkage noreturn
void deputy_fail_noreturn(__LOCATION__FORMALS);

extern asmlinkage noreturn
void deputy_fail_noreturn_fast(void);

/* Search for a NULL starting at e and return its index */
extern asmlinkage
int deputy_findnull(const void *e1, unsigned int sz);

//Define deputy_memset, which we use to initialize locals
//FIXME:  We should set __deputy_memset = __builtin_memset to take advantage 
//of optimizations.  How do we do that in a portable way?
#if defined(memset) && !defined(IN_DEPUTY_LIBRARY)
#define __deputy_memset memset
#else
extern asmlinkage
void *__deputy_memset(void *s, int c, unsigned int n);
#endif

#if  defined(DEPUTY_FAST_CHECKS)
   #define deputy_fail deputy_fail_noreturn_fast
#elif defined(DEPUTY_ALWAYS_STOP_ON_ERROR)
   #define deputy_fail deputy_fail_noreturn
#else
   #define deputy_fail deputy_fail_mayreturn
#endif


/* Check that there is no NULL between e .. e+len-1. "bytes" is the size of 
 * an element */
INLINE static asmlinkage
int deputy_nullcheck(const volatile void *e, unsigned int len,
                     unsigned int bytes) {
#define NULLCHECK(type) \
    do { \
        type *p1 = (type*) e; \
        type *p2 = ((type*) e) + len; \
        while (p1 < p2 && *p1 != 0) { \
            p1++; \
        } \
        success = (p1 >= p2); \
    } while (0)

    int success = 0;

    switch (bytes) {
        case 1:
            NULLCHECK(char);
            break;
        case 2:
            NULLCHECK(short);
            break;
        case 4:
            NULLCHECK(long);
            break;
        default:      
            deputy_fail(__LOCATION__);
    }
    return success;
#undef NULLCHECK
}

#if defined(__KERNEL__) && defined(KRECOVER) && !defined(NO_INJECTION)
extern int kr_failure_injected(void);
#define INJECTED_FAILURE() (kr_failure_injected())
#else
#define INJECTED_FAILURE() 0
#endif

// what : a boolean that ought to be true
// checkName: the name of the check
// checkWhat: a string that explains what goes wrong
#if defined(__KERNEL__) && defined(DEPUTY_KERNEL_COVERAGE)
#define DEPUTY_ASSERT_TEXT(what,text,checkName)\
    checkBitArrayAdd(read_pc());\
    if (!(what) || INJECTED_FAILURE()) { \
	    deputy_fail(__LOCATION__ACTUALS); \
    }

#define DEPUTY_ASSERT(what, checkName) \
    checkBitArrayAdd(read_pc());\
    DEPUTY_ASSERT_TEXT(what, text, checkName)
#else
#define DEPUTY_ASSERT_TEXT(what, text, checkName) \
    if (!(what) || INJECTED_FAILURE()) { \
	    deputy_fail(__LOCATION__ACTUALS); \
    }

#define DEPUTY_ASSERT(what, checkName) \
    DEPUTY_ASSERT_TEXT(what, text, checkName)
#endif

INLINE static void CNonNull(const volatile void* p, __LOCATION__FORMALS) {
  DEPUTY_ASSERT(p != 0, "non-null check");
}

INLINE static void CEq(const volatile void* e1, const volatile void* e2,
                       __LOCATION__FORMALS) {
  DEPUTY_ASSERT(e1 == e2, why);
}

INLINE static void CMult(int i1, int i2, __LOCATION__FORMALS) {
  DEPUTY_ASSERT((i2 % i1) == 0, "alignment check");
}

/* Check that p + sz * e does not overflow that remains within [lo..hi). It 
 * is guaranteed on input that lo <= p <= hi, with p and h aligned w.r.t. lo 
 * and size sz. */
INLINE static void CPtrArith(const volatile void* lo, const volatile void* hi,
                             const volatile void* p, int e, unsigned int sz,
                             __LOCATION__FORMALS) {
  if (e >= 0) {
    DEPUTY_ASSERT_TEXT(e <= (hi - p) / sz, texthi, "upper bound check");
  } else {
    DEPUTY_ASSERT_TEXT(-e <= (p - lo) / sz, textlo, "lower bound check");
  }
}

INLINE static void CPtrArithNT(const volatile void* lo, const volatile void* hi,
                               const volatile void* p, int e, unsigned int sz,
                               __LOCATION__FORMALS) {
  if (e >= 0) {
    unsigned int len = (hi - p) / sz;
    if (e > len) {
      DEPUTY_ASSERT_TEXT(deputy_nullcheck(hi, e - len, sz),
                         texthi, "nullterm upper bound check");
    }
  } else {
    DEPUTY_ASSERT_TEXT(-e <= (p - lo) / sz, textlo, "lower bound check");
  }
}

INLINE static void CPtrArithAccess(const volatile void* lo,
                                   const volatile void* hi,
				   const volatile void* p,
                                   int e, unsigned int sz,
				   __LOCATION__FORMALS) {
  if (e >= 0) {
    DEPUTY_ASSERT_TEXT(e + 1 <= (hi - p) / sz, texthi, "upper bound check");
  } else {
    DEPUTY_ASSERT_TEXT(-e <= (p - lo) / sz, textlo, "lower bound check");
  }
}

INLINE static void CLeqInt(unsigned int e1, unsigned int e2,
                           __LOCATION__FORMALS) {
  DEPUTY_ASSERT(e1 <= e2, why);
}

INLINE static void CLeq(const volatile void* e1, const volatile void* e2,
                        __LOCATION__FORMALS) {
  DEPUTY_ASSERT(e1 <= e2, why);
}

/* Used to set the upped bounds of an NT string to e1, when we know that e2 
 * is a safe upper bound. Test that e1 <= e2 OR there is no NULL between 
 * e2...e1-1. */
INLINE static void CLeqNT(const volatile void* e1, const volatile void* e2,
                          unsigned int sz, __LOCATION__FORMALS) {
  if (e1 > e2) {
    DEPUTY_ASSERT(deputy_nullcheck(e2, (e1 - e2) / sz, sz), why);
  }
}

INLINE static void CNullOrLeq(const volatile void* e, 
                              const volatile void* e1, const volatile void* e2,
			      __LOCATION__FORMALS) {
  if (e) {
    DEPUTY_ASSERT(e1 <= e2, why);
  }
}

/* Check that e is NULL, or e1 <= e2, or there is no NULL from e2 to e1 */
INLINE static void CNullOrLeqNT(const volatile void* e, 
                                const volatile void* e1,
                                const volatile void* e2,
                                unsigned int sz, __LOCATION__FORMALS) {
  if (e && e1 > e2) {
    DEPUTY_ASSERT(deputy_nullcheck(e2, (e1 - e2) / sz, sz), why);
  }
}


INLINE static void CWriteNT(const volatile void* p,
                            const volatile void* hi,
                            int what, unsigned int sz,
                            __LOCATION__FORMALS) {
  if (p == hi) {
    int isNull = 0;
    switch (sz) {
      case 1: isNull = (*((const volatile char *)  p) == 0); break;
      case 2: isNull = (*((const volatile short *) p) == 0); break;
      case 4: isNull = (*((const volatile int *)   p) == 0); break;
    }
    DEPUTY_ASSERT(!isNull || what == 0, "nullterm write check");
  }
}

INLINE static void CNullUnionOrSelected(const volatile void* p,
                                        unsigned int size,
                                        int sameFieldSelected,
                                        __LOCATION__FORMALS) {
  if (!sameFieldSelected) {
    const volatile char* pp = (const volatile char*)p;
    const volatile char* pend = pp + size;
    while (pp < pend) {
      DEPUTY_ASSERT(0 == *pp++, "null union check");
    }
  }
}

INLINE static void CSelected(int what, __LOCATION__FORMALS) {
  if (!(what)) {
    deputy_fail(__LOCATION__ACTUALS); }
}

INLINE static void CNotSelected(int what, __LOCATION__FORMALS) {
  if ((what)) {
    deputy_fail(__LOCATION__ACTUALS); }
}

#define deputy_max(x, y) ((x) > (y) ? (x) : (y))

#undef DEPUTY_ASSERT
