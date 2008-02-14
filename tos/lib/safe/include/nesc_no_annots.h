struct @bound @deputy_scope() @macro("__DEPUTY_BOUND") { void *lo, *hi; }; 
struct @count @deputy_scope() @macro("__DEPUTY_COUNT") { int n; }; 
struct @single @deputy_scope() @macro("__DEPUTY_SINGLE") { }; 
struct @nonnull @deputy_scope() @macro("__DEPUTY_NONNULL") { }; 

#define __DEPUTY_TRUSTED                       
#define __DEPUTY_COPYTYPE                      
#define TC(__type,__expr)                      __DEPUTY_TRUSTED_CAST(__type,__expr)   
#define __DEPUTY_TRUSTED_CAST(__type,__expr)   ((__type)(__expr))   
