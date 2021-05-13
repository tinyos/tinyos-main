

/*Header file for Simple Service Location Protocol

@author Md.Jamal <mjmohiuddin@cdac.in>
@version $Revision: 1.0

*/

#ifndef SSLP_H
#define SSLP_H

#include <lib6lowpan/ip.h>

struct sslp_hdr{
	uint8_t version:4;			//contains the version of the sslp being used
	uint8_t msgid:6;			//determines the message type
	uint8_t O_flag:1;			//O(Overflow) flag is set when the message length exceeds what can fit into the datagram
	uint8_t F_flag:1;			//F(Fresh) flag is set on every SREG
	uint8_t rsv:4;				//reserved
	uint16_t seq_no;			//set to a unique value for each unique SREQ message.If the request message is retransmitted,the same sequence number is used.Replies set the sequence number to the same value as the sequence number in  the SREQ message.
}__attribute__((packed));


//service request message
/*Service Request Messages are sent by UA to SA to get the location of service specified in the service type*/
typedef struct service_request_msg{
	struct sslp_hdr sslp_header;		//header with message-id=1
	uint8_t AM:2;				//addressing mode specifies the size of the source address
	uint8_t reserved:6;
	//uint8_t reserved1;
	struct in6_addr ip_address;		//we are fixing the AM mode to IP Address here
	uint16_t length_service_type;
	char service_type[24];			//services should be defined according to the service template
	uint16_t length_scope_list;
	char scope[16];
}__attribute__((packed))service_request_msg;


//sslp -draft



typedef struct servicelocation_entry{
	uint16_t lifetime;
	uint8_t  LT:2;
	uint8_t reserved:6;
	uint16_t length_url;
	char url[80];	//TODO:CHANGE at pc to 24 from 48	//make sure while sending from pc u have to append "*" so that overwritten of data does not takes place..A service of a particular type announces its availability with a service:url that includes a domain name or ip address,and possibly its port number and optionally basic configuration parameters
}__attribute__((packed))servicelocation_entry;

//service Reply Message

typedef struct service_reply_msg{
	struct sslp_hdr sslp_header;		//header with message-id=2
	uint16_t error_code;
	uint16_t location_entry_count;
	servicelocation_entry location_entry;
}__attribute__((packed))service_reply_msg;

//Service Registration Message

typedef struct serviceregistration{
	struct sslp_hdr sslp_header;

	servicelocation_entry location_entry;
	
	uint16_t length_service_type;
	char service_type[24];	
	uint16_t length_scope_type;
	char scope[16];
}__attribute__((packed))serviceregistration;


//Service Deregistration Message
//Used for deregistering a service present
typedef struct servicederegistration {
	struct sslp_hdr sslp_header;		//header with message id is 9
	
	servicelocation_entry location_entry;
	uint16_t length_service_type;
	char service_type[24];
	uint16_t length_scope_type;
	char scope[12];
}__attribute__((packed))servicederegistration;



//service type request message is used by UA to get all the services present in the network
typedef struct servicetype_request_msg{
	struct sslp_hdr sslp_header;		//header with message id=7
	uint8_t AM:2;
	uint8_t reserved:6;
	//uint8_t reserved1;			//for padding
	struct in6_addr ip_address;		//we are fixing the AM mode to IP Address here
	uint16_t length_scope_list;
	char scope[16];
}__attribute__((packed))servicetype_request_msg;


//service Type Reply Message
//message send in response to Service Type Request

typedef struct servicetype_reply_msg {
	struct sslp_hdr sslp_header;
	uint16_t error_code;
	uint16_t length_servicetype;
	char servicetype[60];
}__attribute__((packed))servicetype_reply_msg;


//Directory Advertisement Message
//Message sent by DA in response to a Service Request Message with service type:service:directory-agent or periodically it sends a unsolicited message to inform that he is present in the network

typedef struct Directory_Advt_msg {
	struct sslp_hdr sslp_header;
	uint16_t error_code;			//error_code should be sent to zero when DA broadcasts
	servicelocation_entry location_entry;	//url should contain service:directory-agent://"<addr> of the DA"
	uint16_t length_scope_list;
	char scope[8];			//the scope list of the DA must not be null
}__attribute__((packed))directory_advt_msg;




//Service Acknowledgement Messages

typedef struct service_ack_msg{
	struct sslp_hdr sslp_header;
	uint16_t error_code;
}__attribute__((packed))service_ack_msg;



//Service Acknowledgement Messages(SACK) are received in response to the SREG messages
typedef struct {
	char service[16];
	char url[100];
	char scope[16];
	uint16_t lifetime;
}__attribute__((packed))services_available;

//Storing the registered services in the datastructure

typedef struct reg_services{
	char servicetype[24];
	uint16_t lifetime;
	char url[100];
	char scope[16];
}__attribute__((packed))reg_services;


typedef struct {
	char service[16];
	char scope[16];
	uint8_t sequence_no;
}__attribute__((packed))sequencer;

enum{

	NO,
	YES,
};

enum {
RETRANSMIT
};

//error types

enum{
	NO_ERROR=0,
	PARSING_ERROR=1,
	SCOPE_ERROR=2,
	INTERNAL_ERROR=3,
	MSG_NOT_SUPPORTED=4,
	ILLEGAL_REGISTRATION=5,
	DA_BUSY=6,
};
//Addressing Mode Types

enum{
	
	SHORT_ADDR=1,
	EXTENDED_ADDR=2,
	IP_ADDR=3,
	URL_ADDR=3,
};

//Return Types

enum{
	SERV_SCOPE=1,	//Both service and Scope Matches
	SERV=2,		//Only Service Matches
	NONE=3,		//None Matches
};
//Message Types


enum{
	SERVICE_REQUEST=1,
	SERVICE_REPLY=2,
	SERVICE_REGISTRATION=3,
	SERVICE_ACKNOWLEDGE=4,
	DA_ADVERTISEMENT=5,
	SA_ADVERTISEMENT=6,
	SERVICE_TYPE_REQUEST=7,
	SERVICE_TYPE_REPLY=8,
	SERVICE_DEREGISTRATION=9,
};

#define SSLP_VERSION 2
/*(Section 5.3 of RFC2608)Request which fails to give a response are retransmitted. The initial retransmissions occurs	after a CONFIG_RETRY wait period.Retransmissions must be made with exponentially increasing wait intervals(doubling the wait each time)
Multicast requests should be reissued over CONFIG_MC_MAX seconds untill a result has been obtained
*/


#define CONFIG_DA_BEAT 10800000U //3 Hours
//CONFIG_DA_BEAT is the interval after which DA sends unsolicited Directory Advertisements Messages so that SA and UA can recognize that there is a  DA in the network
#define CONFIG_RETRY 2000U	//2 Seconds
#define CONFIG_MC_MAX 15000U	//15 Seconds

#define STORE_MAX_SERVICES 5	//Maximum amount of services we can store
#define STORE_MAX_SEQUENCES 5	//Maximum amount of sequencese we can store
#define WAIT_PERIOD_SREPLY	10000U	//Maximum amount of time we will wait for service reply if messages received after this will be discarded
#define PRINTTIMER_PERIOD	5000U	//delay between each print
#define MAX_SERVICE_ADVERTISE	2	//Maximum services the SA can advertise

#define SSLP_LISTENING_PORT 	4270	//According to RFC 2608(Section 6.1)
#define SSLP_TRANSMIT_PORT	441	//This can be anything
#define MAX_DA_ADDR 		3	//Maximum number of DA Addresses that can be stored
#define CONFIG_REG_ACTIVE 	3000	//Wait to register services on passive DA discovery

#endif
