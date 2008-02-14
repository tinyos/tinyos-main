#ifdef SAFE_TINYOS

#define __DEPUTY_BOUND(__lo,__hi)              __attribute__((bounds((__lo),(__hi))))
#define __DEPUTY_COUNT(__n)                    __DEPUTY_BOUND(__this, __this + (__n))
#define __DEPUTY_SINGLE(__n)                   __DEPUTY_COUNT(1)
#define __DEPUTY_NONNULL(__n)                  __attribute__((nonnull))
#define __DEPUTY_TRUSTEDBLOCK                  __blockattribute__((trusted))

#else

#define __DEPUTY_BOUND(__lo,__hi)              
#define __DEPUTY_COUNT(__n)                    
#define __DEPUTY_SINGLE(__n)                   
#define __DEPUTY_NONNULL(__n)                  
#define __DEPUTY_TRUSTEDBLOCK                  

#endif
