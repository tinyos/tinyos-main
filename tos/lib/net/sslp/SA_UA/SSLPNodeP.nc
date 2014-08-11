
#include <AM.h>

module SSLPNodeP
{
	provides interface SSLPNode;
	uses interface ServiceLocation;
	#ifdef NODE_SA
		uses interface Timer<TMilli>;
	#endif

}

implementation
{	

	uint8_t DAState=FALSE;
	uint8_t SAstate=FALSE,UAstate=FALSE;
		char DA_SCOPE[10];
	services_available sa_services[MAX_SERVICE_ADVERTISE];	
	char Services[40];
	uint8_t REGISTRATION_STATE;
	/*This function returns the length of the string*/
	uint8_t stringlength(char *data)
	{
		uint8_t i;
		uint8_t count=0;
		for(i=0;*(data+i)!='\0';i++)
			count++;	
		return count;

	}
	//function that returns the index
	int allocindex()
	{
		int index;
		for(index=0;index<MAX_SERVICE_ADVERTISE;index++)
		{
			if(!stringlength(sa_services[index].service))
			{
				break;
			}

		}
		if(index==MAX_SERVICE_ADVERTISE)
			return -1;
		return index;
	}
	//returns -1 when the service is not found in its list
	int findService(char *service)
	{	
		int index;
		printf("\n find service:%s",service);
		for(index=0;index<MAX_SERVICE_ADVERTISE;index++)
		{
			if((stringlength(service)))
			{
				printf("\n service %d :%s",index,sa_services[index].service);
			//If the string length is zero then there is problem.
				if(!memcmp(service,&sa_services[index].service,stringlength(service)))
					return index;
			}
		}
		return -1;
	}

	
	//returns 0 when the service is deleted 1 when the service is not deleted 
	int delService(char *service)
	{
		int index;
		index=findService(service);	
		if(index!=-1)
		{
			printf("\n Index is %d",index);
			//memset(&sa_services[index],0,sizeof(services_available));
			memmove((void *)&sa_services[index],(void *)&sa_services[index+1],
			sizeof(services_available)*(MAX_SERVICE_ADVERTISE-index-1));
			//we are clearing the last entry as memmove will make the entry as garbage
			memset(&sa_services[MAX_SERVICE_ADVERTISE-1],0,sizeof(services_available));
			return 0;
		}	
		printf("\n Index is %d",index);
		return 1;
	}

	//Returns 0 when it is duplicate else returns 1 when it is  not duplicate or when no entry exists
	int duplication(char *service,char *scope,char *url)
	{
		uint8_t i;
	
		for(i=0;i<MAX_SERVICE_ADVERTISE&&sa_services[i].lifetime;i++)
		{
			if(!(memcmp(&sa_services[i].service,service,stringlength(sa_services[i].service)))&&
			    !(memcmp(&sa_services[i].scope,scope,stringlength(sa_services[i].scope))) &&
		 	  !(memcmp(&sa_services[i].url,url,stringlength(sa_services[i].url))))
				return 0;
		}
		return 1;
	}


	//returns -1 when the scope is changed else returns 0
	int changeScope(char *service,char *new_scope)
	{
	
		int index=findService(service);
		if(index==-1)
			return index;
		else
		{	
			//clear the already existing scope
			memset(sa_services[index].scope,0,sizeof(sa_services[index].scope));
			memcpy(sa_services[index].scope,new_scope,stringlength(new_scope));
			return 0;
		}

	}

	//Returns the count of the number of services present
	uint8_t service_count()
	{
		uint8_t count=0,i;
		for(i=0;i<MAX_SERVICE_ADVERTISE;i++)
		{
			if(stringlength(sa_services[i].service))
				count++;
		}
		return count;
	}

	command error_t SSLPNode.setUA()
	{
		UAstate=TRUE;
		printf("\n setting the node as UA");
		return SUCCESS;
	}

	command error_t SSLPNode.getUAState()
	{

		return UAstate;
	}


	command error_t SSLPNode.setSA()
	{
		
		SAstate=TRUE;
		printf("\n setting the node as SA");
		#ifdef NODE_SA
			call Timer.startPeriodic(60000U);		//Timer for 1 Minute
		#endif
		return SUCCESS;
	}

	command error_t SSLPNode.getSAState()
	{
		return SAstate;
	}

	
	#ifdef NODE_SA
	command error_t SSLPNode.addService(char *serv,char *scop,char *url,uint16_t lifetime)
	{
		int index=allocindex();
		servicelocation_entry location_entry;
		if(index==-1)
			return FAIL;
		else
		{
			//TODO:Add the duplicate Mechanism Here
			if(duplication(sa_services[index].service,sa_services[index].scope,sa_services[index].url))
			{
				memcpy(&sa_services[index].service,serv,stringlength(serv));
				memcpy(&sa_services[index].scope,scop,stringlength(scop));
				memcpy(&sa_services[index].url,url,stringlength(url));
			}
			else{
				printf("\n already present just update the lifetime");
			}
			sa_services[index].lifetime=lifetime;	//This is just to update the lifetime
			//printf("\n Service Added Successfully");

			//Register the Service with the DA
			location_entry.lifetime=lifetime;
			location_entry.LT=URL_ADDR;
			location_entry.length_url=stringlength(url);
			memcpy(&location_entry.url,url,stringlength(url));
			
			call ServiceLocation.registerService(&location_entry,serv,scop,FRESH);

			
			return SUCCESS;
		}
	}	

	command error_t SSLPNode.removeService(char *service,char *scope,char *url)
	{
		uint8_t index;
		servicelocation_entry location_entry;
		index=findService(service);
		if(call SSLPNode.getSAState())
		{
			if(index!=-1)
			{
				//if the entry is present then send a service deregistration message
				if(!(memcmp(service,&sa_services[index].service,stringlength(service)))&&
				    !(memcmp(scope,&sa_services[index].scope,stringlength(scope)))&&
				    !(memcmp(url,&sa_services[index].url,stringlength(url))))
				{
					//send a service deregistration message					
					location_entry.lifetime=0;
					location_entry.LT = URL_ADDR;
					location_entry.length_url=stringlength(url);
					memcpy(&location_entry.url,url,stringlength(url));
					memset(&sa_services[index],0,sizeof(sa_services[index]));
					call ServiceLocation.deregisterService(&location_entry,service,scope);
					return SUCCESS;
				}
				else
					return FAIL;

			}
			return FAIL;
		}else
			return FAIL;
	}
	#endif
	//returns FAIL when the service is not present else return SUCCESS
	command uint8_t SSLPNode.findService(char *service,char *scope)
	{
		int index;
		if(call SSLPNode.getSAState())
		{
			printf("\n Node.findService:%s with scope:%s",service,scope);
			//first check whether the service exists or not
			index=findService(service);
			if(index==-1)
				return NONE;
			//if the service exist then check whether the scope matches with the already existing scope
			if((!memcmp(scope,sa_services[index].scope,stringlength(scope)))||
			   !memcmp(scope,"default",stringlength("default"))||
			   !memcmp(scope,"",stringlength(scope)))
				return SERV_SCOPE;
			else
				return SERV;
		}
		//UA does not have any services
		return NONE;
	}

	command error_t SSLPNode.changeScope(char *service,char *new_scope)
	{
		if(call SSLPNode.getSAState())
			if(changeScope(service,new_scope)==0)			
				return SUCCESS;
		return FAIL;

	}

	command char * SSLPNode.getServices(char *scope,uint16_t len)
	{
		if(call SSLPNode.getSAState())
		{

			uint8_t i;
			memset(&Services,0,sizeof(Services));
			for(i=0;i<service_count();i++)
			{
				if(!(memcmp(&sa_services[i].scope,scope,len))&&sa_services[i].lifetime)
				{
					memcpy(&Services[stringlength(Services)],"service:",stringlength("service:"));
					printf("\nscope %s is present adding the service:%s",scope,sa_services[i].service);
					memcpy(&Services[stringlength(Services)],sa_services[i].service,
					stringlength(sa_services[i].service));
					printf("\n after adding service:%s",Services);
					Services[stringlength(Services)]=',';
				}
				else
				{
					printf("\n scope %s is not present with scope %s",scope,sa_services[i].scope);
				}
			}

			Services[stringlength(Services)-1]='\0';
			return Services;
		}	
		return 0;
	}	


	command bool SSLPNode.servicesPresent(char *scope)
	{
		if(call SSLPNode.getSAState())
		{
			uint8_t i;
			for(i=0;i<service_count();i++)
			{
				if(!(memcmp(&sa_services[i].scope,scope,stringlength(scope)))&&sa_services[i].lifetime)
				{
					return TRUE;
				}
			}
		}
		return FALSE;
	}

	command error_t SSLPNode.getServiceURL(char *servicetype,char *scope,char *url)
	{
		
		int index;
		if(call SSLPNode.getSAState())
		{

			index=findService(servicetype);
			if(index==-1)
			{
				printf("service:%s not found ",servicetype);
				return FAIL;
			}
			else 
			{
				if(!(memcmp(scope,&sa_services[index].scope,stringlength(scope)))||
				    !(memcmp(scope,"default",stringlength("default"))) ||
				   !(memcmp(scope,"",stringlength(scope))))	
					memcpy(url,&sa_services[index].url,stringlength(sa_services[index].url));
					url[stringlength(url)]='\0';
				return SUCCESS;
			}
		}		
		return FAIL;
	}
	
	#ifdef PRINTFUART_ENABLED
	//if he is an SA he will print the services
	command error_t SSLPNode.printServices()
	{
		//int i;
		if(call SSLPNode.getSAState())
		{	
		/*	printf("\n Service \t\t IP_Address\t\tPort Number\t\tscope\n");
			for(i=0;i<MAX_SERVICE_ADVERTISE;i++)
			{
				if(stringlength(sa_services[i].service))
				{
					printf("%s\t\t",sa_services[i].service);
					//printf_in6addr(&sa_services[i].ip_address);
					//printf("\t\t\t%d",sa_services[i].port_no);
					printf("\t\t%s\n",sa_services[i].scope);
				}
			}*/
			return SUCCESS;
		}
		else	//UA dont have the services
			return FAIL;
	}
	
	#endif

	event void ServiceLocation.receiveServices(servicelocation_entry *services,uint8_t count){


	}

	event void ServiceLocation.receiveServiceTypes(char *services)
	{


	}
	#ifdef NODE_SA
	event void Timer.fired()
	{
		uint8_t i;
		servicelocation_entry location_entry;
		for(i=0;i<MAX_SERVICE_ADVERTISE;i++)
		{
			if(sa_services[i].lifetime)	//checking whether the lifetime is greater than zero
			{
				sa_services[i].lifetime-=1;
				if(sa_services[i].lifetime==1)	//renew the registration
				{
					printf("\n Renewing the registration");
					sa_services[i].lifetime=SERVICE_REG_LIFETIME;	//This is just to update the lifetime
				

					//Register the Service with the DA
					location_entry.lifetime=SERVICE_REG_LIFETIME;
					location_entry.LT=URL_ADDR;
					location_entry.length_url=stringlength(sa_services[i].url);
					memcpy(&location_entry.url,sa_services[i].url,stringlength(sa_services[i].url));
			
			call ServiceLocation.registerService(&location_entry,sa_services[i].service,sa_services[i].scope,RENEW);
	
				}	

			}
		}		

		
	}
	#endif
	

}
