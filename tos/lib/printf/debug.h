
#ifndef DEBUG_H
#define DEBUG_H


#ifndef DEFAULT_LOG_LEVEL
#define DEFAULT_LOG_LEVEL	5
#endif

#define NOP (void)0


#define print(log_level, ...)	(log_level > DEFAULT_LOG_LEVEL) ? NOP : printf(__VA_ARGS__)

#define pr_emergency(...) 	print(EMERGENCY, __VA_ARGS__)

#define pr_alert(...)		print(ALERT, __VA_ARGS__)

#define pr_critical(...) 	print(CRITICAL, __VA_ARGS__)

#define pr_error(...)		print(ERROR, __VA_ARGS__)

#define pr_warning(...) 	print(WARNING, __VA_ARGS__)

#define pr_info(...)		print(INFO, __VA_ARGS__)

#define pr_debug(...)		print(DEBUG, __VA_ARGS__)





//Various Log Levels: (Names copied from kernel logging levels)


enum {
	EMERGENCY = 0,	//System is about to crash or is unstable
	ALERT	  = 1,	//Something bad happened and action must be taken immediately
	CRITICAL  = 2,	//Critical condition occured like serious hardware/software issue
	ERROR	  = 3,	//Often used to indicate difficulties with the hardware
	WARNING	  = 4,	//Nothing serious by itself but might indicate problems
	INFO	  = 5,	//Informational Messages,e.g: startup information
	DEBUG	  = 6,	//Debug Information
};




#endif
