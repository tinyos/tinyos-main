struct @bound @deputy_scope() @macro("__DEPUTY_BOUND") { void *lo, *hi; }; 
struct @count @deputy_scope() @macro("__DEPUTY_COUNT") { int n; }; 
struct @single @deputy_scope() @macro("__DEPUTY_SINGLE") { }; 
struct @nonnull @deputy_scope() @macro("__DEPUTY_NONNULL") { }; 

#define __DEPUTY_TRUSTED                       __attribute__((trusted))
#define __DEPUTY_COPYTYPE                      __attribute__((copytype))
#define TC(__type,__expr)                      __DEPUTY_TRUSTED_CAST(__type,__expr)
#define __DEPUTY_TRUSTED_CAST(__type,__expr)   ((__type)((void * __DEPUTY_TRUSTED __DEPUTY_COPYTYPE)(__expr)))
