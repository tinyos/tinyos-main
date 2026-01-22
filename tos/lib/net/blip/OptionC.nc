
module OptionC{

provides interface Option;

}


implementation
{
  	command int Option.length_opt(uint8_t search_type)
  	{
		if(search_type==SLLAO||search_type==TLLAO)
			return sizeof(stlla_opt);
		else if(search_type==PREFIX_INFORMATION)
			return sizeof(prefix_opt);
		else if(search_type==ARO)
			return sizeof(aro_opt);
		else if(search_type==CONTEXT_0PTION)
			return sizeof(context_opt);
		else if(search_type==ABRO)
			return sizeof(abro_opt);
		return 0;


  	}	



	  command uint8_t * Option.findoption(void *payload,uint8_t first_type,uint8_t search_type)
	  {	//first_type contains the length of the message in which option is present
		uint8_t *ptr=(uint8_t *)payload+first_type+LENGTH_ICMPHEADER;
			
		first_type=*ptr;
		while(search_type!=first_type)
		{
			uint8_t length=call Option.length_opt(first_type);
			if(length==0)
				break;
			ptr=ptr+length;
			first_type=*ptr;
	
		}
		if(search_type==*ptr)
		{	
			payload=ptr;
			return ptr;
		}
		else
			return 0;
	
	  }

	command uint8_t * Option.ptrMsg(void *payload)
	{
		uint8_t *ptr=(uint8_t *)payload;//+LENGTH_ICMPHEADER;
		return ptr;
	}
 }
 
