
interface BootImage {
  command void reboot();
  command error_t boot(uint8_t img_num);
  
  // Added by Jaein Jeong
  command error_t erase(uint8_t img_num);
}
