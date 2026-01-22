
#include "Neighbr.h"
interface NeighbrCache
{

	command error_t init();


	command error_t getLBRAddress(struct in6_addr *lbr);

	command error_t storeCtx(struct in6_addr prefix,uint8_t cid,uint16_t lifetime);

	command int getContext(uint8_t context,struct in6_addr *ctx);

	command int matchContext(struct in6_addr *ctx,uint8_t *context);

	command error_t addentry(struct in6_addr ip,ieee_eui64_t lladdr,neighbr_info info);

	command error_t removeentry(struct in6_addr ip);

	command error_t delEntry(uint8_t i);

	command error_t resolveIP(struct in6_addr *ip,ieee154_addr_t * linkaddr);

	command neighbr_cache * findEntry(struct in6_addr ip);

   	command neighbr_cache * getEntryLL(ieee_eui64_t link_addr);

	
	command int findIPEUI64(struct in6_addr ip,ieee_eui64_t link_addr);

	command void PrintTable();

	command void PrintDADTable();

	command error_t updateEntry(struct in6_addr ip,ieee_eui64_t lladdr,neighbr_info info);

 	command neighbr_cache * getEntry(uint8_t index);

	command error_t DADaddEntry(struct in6_addr ip,ieee_eui64_t lladdr,uint16_t reg_lifetime);

	command error_t DADremoveEntry(struct in6_addr ip);

	command int DADfindEntry(struct in6_addr ip);
	
	command int DADfindIPEUI64(struct in6_addr ip,ieee_eui64_t link_addr);

	command dad_cache * getDADEntry(uint8_t index);

	command error_t checkPrefix(struct in6_addr prefix,struct in6_addr lbr_addr,uint16_t ver_high,uint16_t ver_low);

	command error_t addPrefix(prefix_info prefix_information,abro_info info);

	command error_t removePrefix(struct in6_addr prefix);

	event void prefixReg();

	command uint8_t prefixes_count();
	
	command prefix_list * getPrefixIndex(uint8_t index);



	event void default_rtrlistempty();

	event void NUD_reminder(struct in6_addr ip_address);

	command error_t startNUD();
	


}

