#if NESC >= 130

struct @bound @deputy_scope() @macro("__DEPUTY_BOUND") { void *lo, *hi; }; 
struct @count @deputy_scope() @macro("__DEPUTY_COUNT") { int n; }; 
struct @single @deputy_scope() @macro("__DEPUTY_SINGLE") { }; 
struct @nonnull @deputy_scope() @macro("__DEPUTY_NONNULL") { }; 

#define COUNT(x)                               @count(x)
#define BOUND(x,y)                             @bound(x,y)
#define SINGLE                                 @single()
#define NONNULL                                @nonnull()

#ifdef SAFE_TINYOS
#define TCAST(__type,__expr)                   ((__type)((void * __DEPUTY_TRUSTED __DEPUTY_COPYTYPE)(__expr)))
#define __DEPUTY_TRUSTED                       __attribute__((trusted))
#define __DEPUTY_COPYTYPE                      __attribute__((copytype))
#else
#define TCAST(__type,__expr)                   ((__type)(__expr))                
#endif

#else // NESC < 130

#ifdef SAFE_TINYOS
#error Safe TinyOS requires nesC >= 1.3.0
#endif

#endif
