/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */
 
 interface TimerAsync
 {
	
	async command error_t start();
	
	async command error_t stop();
	
	async command error_t reset();
 
	/***********************************FIRED EVENTS COMMANDS******************************/
	//time before BI
	async event error_t before_bi_fired();
	
	async event error_t sd_fired();
	
	async event error_t bi_fired();
	
	//backoff fired
	async event error_t backoff_fired();
	
	//backoff boundary fired
	async event error_t time_slot_fired();
	
	async event error_t before_time_slot_fired();
	
	async event error_t sfd_fired();
	
	/***********************************INIT/RESET COMMANDS******************************/
	
	async command error_t set_bi_sd(uint32_t bi_symbols,uint32_t sd_symbols);
	
	async command error_t set_backoff_symbols(uint8_t symbols);
	
	async command error_t set_enable_backoffs(bool enable_backoffs);
	
	async command uint8_t reset_start(uint32_t start_ticks);

	async command error_t reset_process_frame_tick_counter();
	
	/*****************************************************************************/
	
	async command error_t set_timers_enable(uint8_t timer);
	
	/***********************************GET COMMANDS******************************/
	async command uint32_t get_total_tick_counter();
	
	async command uint32_t get_current_number_backoff();
	
	async command uint32_t get_time_slot_backoff_periods();
	
	async command uint32_t get_current_time_slot();

	async command uint32_t get_current_number_backoff_on_time_slot();
	
	async command uint32_t get_process_frame_tick_counter();
	
	async command uint32_t get_time_slot_ticks();
	
	async command uint32_t get_current_ticks();
	
	async command uint32_t get_sd_ticks();
	
	async command uint32_t get_bi_ticks();
	
	async command uint32_t get_backoff_ticks();
	
	
	/*****************************************************************************/
	//TDBS IMPLEMENTATION
	/*****************************************************************************/
	
	//track beacon interfaces
	
	async command error_t set_track_beacon(uint8_t track);
	
	async command error_t set_track_beacon_start_ticks(uint32_t parent_offset_symbols,uint32_t duration_symbols,uint32_t transmission_delay);
	
	
	async event error_t before_start_track_beacon_fired();
	
	async event error_t start_track_beacon_fired();
	
	async event error_t end_track_beacon_fired();
 
 }

