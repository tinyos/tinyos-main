

interface RouterList
{


	/* Add an entry into the Router List*/
	command error_t add(struct in6_addr ip);

	command error_t remove(struct in6_addr ip);

	command error_t getRouterIP(struct in6_addr *ip);

	command error_t removeAll();



}
