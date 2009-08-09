
interface InternalIPExtension {

  command void addHeaders(struct split_ip_msg *msg, uint8_t nxt_hdr, uint16_t label);

  command void free();

}
