#include "sslp.h"
#include <lib6lowpan/ip.h>
interface SSLPNode
{


	command error_t setUA();

	command bool getUAState();

	command error_t setSA();

	command bool getSAState();

	#ifdef NODE_SA

	//add services to the services advertised by the SA
	command error_t addService(char *service,char *scope,char *url,uint16_t lifetime);

	//remove services from the services advertised by the SA

	command error_t removeService(char *service,char *scope,char *url);
	#endif	

	//get the services advertised by the SA

	command char * getServices(char *service,uint16_t len);
	

	//check whether any services matching to the scope are present

	command  bool servicesPresent(char *scope);

	//Get the service URL for the service type
	command error_t getServiceURL(char *servicetype,char *scope,char *serviceurl);



	//change the scope of the existing service
	
	command error_t changeScope(char *service,char *new_scope);

	//check whether the service and scope exist or not if the scope is not defined then check whether only the service is present
	command uint8_t findService(char *service,char *scope);
	
	#ifdef PRINTFUART_ENABLED
		command error_t printServices();
	#endif

	





}
