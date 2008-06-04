#ifndef ANNOTS_STAGE1_INCLUDED
#define ANNOTS_STAGE1_INCLUDED
#include <stddef.h>

#define __DEPUTY_UNUSED__                      __attribute__((unused))

// define away two obsolete annotations
#define BOUND(x,y)
#define SINGLE

#if NESC >= 130

struct @nonnull @deputy_scope() @macro("__DEPUTY_NONNULL") { }; 
struct @fat @deputy_scope() @macro("__DEPUTY_FAT") { void *lo, *hi; }; 
struct @fat_nok @deputy_scope() @macro("__DEPUTY_FAT_NOK") { void *lo, *hi; }; 
struct @count @deputy_scope() @macro("__DEPUTY_COUNT") { int n; }; 
struct @count_nok @deputy_scope() @macro("__DEPUTY_COUNT_NOK") { int n; }; 
struct @one @deputy_scope() @macro("__DEPUTY_ONE") { }; 
struct @one_nok @deputy_scope() @macro("__DEPUTY_ONE_NOK") { };
struct @dmemset @deputy_scope() @macro("__DEPUTY_DMEMSET") {void *p; int what; size_t sz; };
struct @dmemcpy @deputy_scope() @macro("__DEPUTY_DMEMCPY") {void *dst; void *src; size_t sz; };

#define NONNULL                                @nonnull()
#define FAT(x,y)                               @fat(x,y)
#define FAT_NOK(x,y)                           @fat_nok(x,y)
#define COUNT(x)                               @count(x)
#define COUNT_NOK(x)                           @count_nok(x)
#define ONE                                    @one()
#define ONE_NOK                                @one_nok()
#define DMEMSET(x,y,z)                         @dmemset(x,y,z)
#define DMEMCPY(x,y,z)                         @dmemcpy(x,y,z)
#define TRUSTEDBLOCK                           @unsafe()

#else // NESC < 130

#ifdef SAFE_TINYOS
#error Safe TinyOS requires nesC >= 1.3.0
#endif

#define NONNULL                                
#define FAT(x,y)                             
#define FAT_NOK(x,y)                             
#define COUNT(x)                               
#define COUNT_NOK(x)                               
#define ONE 
#define ONE_NOK
#define DMEMSET(x,y,z)
#define DMEMCPY(x,y,z)
#define TRUSTEDBLOCK

#endif // NESC version check

#ifdef SAFE_TINYOS
#define TCAST(__type,__expr)                   ((__type)((void * __DEPUTY_TRUSTED __DEPUTY_COPYTYPE)(__expr)))
#define __DEPUTY_TRUSTED                       __attribute__((trusted))
#define __DEPUTY_COPYTYPE                      __attribute__((copytype))
#else
#define TCAST(__type,__expr)                   ((__type)(__expr))                
#endif 

#ifdef SAFE_TINYOS
void * (DMEMSET(1, 2, 3) memset)(void*, int, size_t);
void * (DMEMCPY(1, 2, 3) memcpy)(void*, const void*, size_t);
#endif

#endif
