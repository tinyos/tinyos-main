uint8_t var;
uint16_t lasterr;

void xe1205error(uint8_t loc, uint8_t value_)  __attribute__ ((noinline)) {
  // this is just to make sure the compiler doesn't optimize 
  // out calls to this function, since we use it as a gdb breakpoint
  atomic var += value_ + loc;
}


void xe1205check(uint8_t loc, error_t err)   __attribute__ ((noinline)) {
  if (err != SUCCESS) {
    atomic lasterr = loc;
    xe1205error(loc, err);
  }
}

