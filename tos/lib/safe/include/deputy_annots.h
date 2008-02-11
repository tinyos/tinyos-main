#define __DEPUTY_BOUND(__lo,__hi)              __attribute__((bounds((__lo),(__hi))))
#define __DEPUTY_COUNT(__n)                    __DEPUTY_BOUND(__this, __this + (__n))
#define __DEPUTY_SINGLE(__n)                   __DEPUTY_COUNT(1)
#define __DEPUTY_TRUSTED_CAST(__type,__expr)   ((__type)((void * __DEPUTY_TRUSTED __DEPUTY_COPYTYPE)(__expr)))

#define TC(__type,__expr)                      __DEPUTY_TRUSTED_CAST(__type,__expr)

#define __DEPUTY_NONNULL                       __attribute__((nonnull))
#define __DEPUTY_TRUSTED                       __attribute__((trusted))
#define __DEPUTY_COPYTYPE                      __attribute__((copytype))
#define __DEPUTY_TRUSTEDBLOCK                  __blockattribute__((trusted))
