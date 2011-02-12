interface LedsIntensity
{
  command void set( uint8_t ledNum, uint8_t intensity );
  command void glow(uint8_t a, uint8_t b);
}
