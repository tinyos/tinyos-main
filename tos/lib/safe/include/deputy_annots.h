#define __DEPUTY_BOUND(__lo,__hi)              __attribute__((bounds((__lo),(__hi))))
#define __DEPUTY_COUNT(__n)                    _DEPUTY_BOUND(__this, __this + (__n))
#define __DEPUTY_SINGLE(__n)                   _DEPUTY_COUNT(1)
#define __DEPUTY_TRUSTED_CAST(__type,__expr)   ((__type)((void * TRUSTED COPYTYPE)(__expr)))

#define TC(__type,__expr)                      __DEPUTY_TRUSTED_CAST(__type,__expr)
