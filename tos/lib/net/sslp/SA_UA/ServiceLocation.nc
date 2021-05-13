
#include "sslp.h"
interface ServiceLocation
{

	


	event void receiveServices(servicelocation_entry *services,uint8_t count);

	#ifdef NODE_UA
	command error_t findServices(char *service_type,char *scope);
	command int findService(char *service,char *scope);

	command error_t findAllServices(char *scope);
	#else

	command error_t registerService(servicelocation_entry *location_entry,char *servicetype,char *scope,uint8_t state);

	command error_t deregisterService(servicelocation_entry *location_entry,char *servicetype,char *scope);
	#endif
	
	
	event void receiveServiceTypes(char *services);

	//event void receiveAllServices();

	/*command error_t getServices(char *scope);

	//you will get all the services present in the network separated by ,
	event void servicesPresent(services_available *services,uint8_t count);


	//commands for caching the service Location Entries
	command error_t addServiceEntry(struct in6_addr ip_address,char *service,uint16_t lifetime,uint16_t port,char *scope);


	command error_t deleteServiceEntry(uint8_t index);



	#ifdef PRINTFUART_ENABLED
	command error_t printServices();	
	#endif
*/

}
