#define __DEPUTY_BOUND(__lo,__hi)              
#define __DEPUTY_COUNT(__n)                    
#define __DEPUTY_SINGLE(__n)                   
#define __DEPUTY_TRUSTED_CAST(__type,__expr)   ((__type)(__expr))

#define TC(__type,__expr)                      __DEPUTY_TRUSTED_CAST(__type,__expr)

#define __DEPUTY_NONNULL                       
#define __DEPUTY_TRUSTED                       
#define __DEPUTY_COPYTYPE                      
#define __DEPUTY_TRUSTEDBLOCK                  
