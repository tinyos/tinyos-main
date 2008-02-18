interface PacketMaker {

  command uint16_t getSize(message_t * msg);

  command void createRM(message_t * msg, dymo_msg_t msg_type, 
			const rt_info_t * origin, const rt_info_t * target);

  command error_t addInfo(message_t * msg, const rt_info_t * info);

}
