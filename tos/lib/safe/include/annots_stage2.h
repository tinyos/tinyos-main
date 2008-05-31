#ifndef ANNOTS_STAGE2_INCLUDED
#define ANNOTS_STAGE2_INCLUDED

#ifdef SAFE_TINYOS

#define __DEPUTY_NONNULL(__n)                  __attribute__((nonnull))
#define __DEPUTY_FAT_NOK(__lo,__hi)            __attribute__((bounds((__lo),(__hi))))
#define __DEPUTY_FAT(__lo,__hi)                __DEPUTY_NONNULL(__n) __DEPUTY_FAT_NOK(__lo,__hi)
#define __DEPUTY_COUNT_NOK(__n)                __DEPUTY_FAT_NOK(__this, __this + (__n))
#define __DEPUTY_COUNT(__n)                    __DEPUTY_NONNULL(__n) __DEPUTY_COUNT_NOK(__n)
#define __DEPUTY_ONE_NOK(__n)                  __DEPUTY_COUNT_NOK(1)
#define __DEPUTY_ONE(__n)                      __DEPUTY_NONNULL(__n) __DEPUTY_ONE_NOK(__n)
#define __DEPUTY_TRUSTEDBLOCK                  __blockattribute__((trusted))
#define __DEPUTY_DMEMSET(x,y,z)                __attribute__((dmemset((x),(y),(z))))
#define __DEPUTY_DMEMCPY(x,y,z)                __attribute__((dmemcpy((x),(y),(z))))

#else 

#define __DEPUTY_NONNULL(__n)                  
#define __DEPUTY_FAT_NOK(__lo,__hi)              
#define __DEPUTY_FAT(__lo,__hi)              
#define __DEPUTY_COUNT_NOK(__n)                    
#define __DEPUTY_COUNT(__n)                    
#define __DEPUTY_ONE_NOK(__n)                   
#define __DEPUTY_ONE(__n)                   
#define __DEPUTY_TRUSTEDBLOCK                  
#define __DEPUTY_DMEMSET(x,y,z)
#define __DEPUTY_DMEMCPY(x,y,z)

#endif 

#endif 
