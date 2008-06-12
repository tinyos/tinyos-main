
/**
 * @author Jeongyeup Paek (jpaek@enl.usc.edu)
 **/
 
#ifndef TOSTHREAD_TENET_H
#define TOSTHREAD_TENET_H

extern error_t tenet_send(uint8_t len, uint8_t *data);
extern error_t tenet_sendto(uint16_t tid, uint16_t dst, uint8_t len, uint8_t *data);

extern uint16_t tenet_get_tid();
extern uint16_t tenet_get_src();
extern uint8_t tenet_get_numtasks();

extern void reboot();

extern uint16_t get_nodeid();
extern uint16_t get_nexthop();
extern uint32_t get_globaltime();
extern uint32_t get_localtime();
extern uint16_t get_rfpower();
extern uint16_t get_istimesync();
extern uint32_t get_globaltimems();
extern uint32_t get_localtimems();
extern uint16_t get_clockfreq();
extern uint16_t get_platform();
extern uint16_t get_hopcount();
extern uint16_t get_rfchannel();

extern uint16_t read_voltage();
extern uint16_t read_internal_temperature();
extern uint16_t read_tsr_sensor();
extern uint16_t read_par_sensor();
extern uint16_t read_temperature();
extern uint16_t read_humidity();

#endif //TOSTHREAD_TENET_H

