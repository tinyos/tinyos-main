/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */
 
#define BEFORE_BI_INTERVAL 100
#define BEFORE_BB_INTERVAL 5

#define SO_EQUAL_BO_DIFFERENCE 2

//#define SYMBOL_DIVISION 4

//temporary
#define NUMBER_TIME_SLOTS 16

//TDBS Implementation
#define BEFORE_TRACK_BEACON 40
 
module TimerAsyncM {

	provides interface TimerAsync;
	
	uses interface Leds;

	uses interface Alarm<T32khz,uint32_t> as AsyncTimer;
  
	
  
}
implementation
{

uint32_t ticks_counter;

//BEACON INTERVAL VARIABLES
uint32_t bi_ticks;
uint32_t bi_backoff_periods;
uint32_t before_bi_ticks;
uint32_t sd_ticks;

//number of backoff periods
uint32_t time_slot_backoff_periods;

//number of ticks in the timeslot
uint32_t time_slot_ticks;
uint32_t before_time_slot_ticks;
uint32_t time_slot_tick_next_fire;

//BACKOFF VARIABLES
uint32_t backoff_symbols;

//number of ticks in the backoff
uint32_t backoff_ticks = 5;

//COUNTER VARIABLES
uint32_t backoff_ticks_counter=0;

//give the current time slot number
uint8_t current_time_slot=0;
//counts the current number of time slots of each time slot
uint32_t current_number_backoff_on_time_slot=0;
//count the total number of backoffs
uint32_t current_number_backoff = 0;

//OTHER
bool backoffs=0;
bool enable_backoffs=0;

uint8_t previous_sfd=0;
uint8_t current_sfd = 0;

uint32_t process_frame_tick_counter=0;

uint32_t total_tick_counter=0;

uint8_t timers_enable=0x01;


//TDBS Implementation

uint32_t start_track_beacon_ticks=0;
uint32_t end_track_beacon_ticks=0;

uint8_t track_beacon=0;

  
async command error_t TimerAsync.start()
{

call AsyncTimer.start(10);

return SUCCESS;

}
	
async command error_t TimerAsync.stop()
{

return SUCCESS;

}
  
/*RESET the tick counter, */
async command error_t TimerAsync.reset()
{
	atomic ticks_counter = 0;
	call AsyncTimer.start(10);
	return SUCCESS;
}

async command error_t TimerAsync.set_bi_sd(uint32_t bi_symbols,uint32_t sd_symbols)
{

atomic{
		time_slot_backoff_periods = (sd_symbols / NUMBER_TIME_SLOTS) / backoff_symbols;
		time_slot_ticks = time_slot_backoff_periods * backoff_ticks;
		time_slot_tick_next_fire = time_slot_ticks;
		before_time_slot_ticks = time_slot_ticks - BEFORE_BB_INTERVAL;
		sd_ticks = time_slot_ticks * NUMBER_TIME_SLOTS;

		if (bi_symbols == sd_symbols )
		{
			//in order not to have the same time for both BI and SI
			sd_ticks = sd_ticks - SO_EQUAL_BO_DIFFERENCE;
		}
		
		bi_backoff_periods = bi_symbols/ backoff_symbols;
		bi_ticks = bi_backoff_periods * backoff_ticks;
		
		before_bi_ticks = bi_ticks - BEFORE_BI_INTERVAL;
		
		/*
		printfUART("bi_ticks %i\n", bi_ticks);
		printfUART("sd_ticks %i\n", sd_ticks);
		printfUART("time_slot_ticks %i\n", time_slot_ticks);
			*/
	}
return SUCCESS;
}
  
  
async command error_t TimerAsync.set_backoff_symbols(uint8_t Backoff_Duration_Symbols)
{
	
	atomic
	{
		backoff_symbols = Backoff_Duration_Symbols;
		backoff_ticks =  1;
	}

	return SUCCESS;
} 


async command error_t TimerAsync.set_enable_backoffs(bool enable)
{
	atomic enable_backoffs = enable;
	return SUCCESS;
}
  
   
  
async event void AsyncTimer.fired() {

atomic{

		if(timers_enable==0x01)
		{
			
			ticks_counter++;
			process_frame_tick_counter++;
			
			total_tick_counter++;
			
			if (ticks_counter == before_bi_ticks)
			{
				signal TimerAsync.before_bi_fired();	
			} 
			
			if (ticks_counter == bi_ticks)
			{
				//printfUART("bi%d\n", ticks_counter);
				ticks_counter = 0;
				current_time_slot=0;
				backoff_ticks_counter=0;
				time_slot_tick_next_fire=time_slot_ticks;
				backoffs=1;
				enable_backoffs = 1;
				current_number_backoff =0;
				signal TimerAsync.bi_fired();
			}
			
			if(ticks_counter == sd_ticks)
			{
				backoffs=0;
				signal TimerAsync.sd_fired();
			}
	
			if ((enable_backoffs == 1) && (backoffs == 1))
			{	
				backoff_ticks_counter++;
				
				if (backoff_ticks_counter == backoff_ticks)
				{
					
					backoff_ticks_counter=0;
					current_number_backoff ++;
					current_number_backoff_on_time_slot++;
					signal TimerAsync.backoff_fired();
				}
				
				//before time slot boundary
				if(ticks_counter == before_time_slot_ticks)
				{
					signal TimerAsync.before_time_slot_fired();
				}
				
				//time slot fired
				if (ticks_counter == time_slot_tick_next_fire)
				{
					time_slot_tick_next_fire = time_slot_tick_next_fire + time_slot_ticks;
					before_time_slot_ticks = time_slot_tick_next_fire - BEFORE_BB_INTERVAL;
					backoff_ticks_counter=0;
					current_number_backoff_on_time_slot=0;
					current_time_slot++;
					
					if ((current_time_slot > 0) && (current_time_slot < 16) )
						signal TimerAsync.time_slot_fired();
					
						
						
				}
			}
			
			
			//will only fires when the node is in the inactive period(backoffs==0) and is tracking the beacon
			//TDBS Implementation
			if(track_beacon == 1)
			{
			
				if(ticks_counter == (start_track_beacon_ticks - BEFORE_TRACK_BEACON))
				{
					//backoff_ticks_counter=0;
					signal TimerAsync.before_start_track_beacon_fired();
				}
				
				if(ticks_counter == start_track_beacon_ticks)
				{
					//backoff_ticks_counter=0;
					signal TimerAsync.start_track_beacon_fired();
				}
				
				backoff_ticks_counter++;
				if(backoff_ticks_counter==backoff_ticks)
				{
					backoff_ticks_counter=0;
					signal TimerAsync.backoff_fired();
				}
				
				if(ticks_counter == end_track_beacon_ticks)
				{
					signal TimerAsync.end_track_beacon_fired();
				}
			}
	}

   call AsyncTimer.start(10);
   
  }
}
    

async command error_t TimerAsync.set_timers_enable(uint8_t timer)
{

	atomic timers_enable = timer;
	//printfUART("te%i\n", timers_enable);

	
return SUCCESS;
}

async command error_t TimerAsync.reset_process_frame_tick_counter()
{
atomic process_frame_tick_counter=0;

return SUCCESS;
}



/*RESET the tick counter, to the start ticks */

async command uint8_t TimerAsync.reset_start(uint32_t start_ticks)
{
			//ticks_counter =0;
			//ticks_counter = start_ticks;
			
			current_time_slot = start_ticks / time_slot_ticks;
			
			if (current_time_slot == 0)
			{
				time_slot_tick_next_fire= time_slot_ticks;
				current_number_backoff = start_ticks / backoff_ticks;
				current_number_backoff_on_time_slot = current_number_backoff;
			}
			else
			{
				time_slot_tick_next_fire=  ((current_time_slot+1) * time_slot_ticks);
				current_number_backoff = start_ticks / backoff_ticks;
				current_number_backoff_on_time_slot = current_number_backoff - (current_time_slot * time_slot_backoff_periods);
			}
			
			backoff_ticks_counter=0;
			backoffs=1;
			//on_sync = 1;
			
		total_tick_counter = total_tick_counter + start_ticks;
		ticks_counter = start_ticks;

/*
		printfUART("bi_ticks %i\n", bi_ticks);
		printfUART("sd_ticks %i\n", sd_ticks);
		printfUART("time_slot_ticks %i\n", time_slot_ticks);
		printfUART("total_tick_counter %i\n", total_tick_counter);
		printfUART("ticks_counter %i\n", ticks_counter);
		printfUART("current_time_slot %i\n", current_time_slot);
*/



		return current_time_slot;
		
	}

/***********************************SET COMMANDS******************************/

/***********************************GET COMMANDS******************************/
/*get current clock ticks*/

async command uint32_t TimerAsync.get_current_ticks()
{
	return ticks_counter;
}
/*get current sd ticks*/  
async command uint32_t TimerAsync.get_sd_ticks()
{
	return time_slot_ticks * NUMBER_TIME_SLOTS;
}	
/*get current clock ticks*/
async command uint32_t TimerAsync.get_bi_ticks()
{
	return bi_ticks;
}	
/*get current backoff ticks*/
async command uint32_t TimerAsync.get_backoff_ticks()
{
	return backoff_ticks;
}	
/*get current time slot ticks*/
async command uint32_t TimerAsync.get_time_slot_ticks()
{
	return time_slot_ticks;
}	

/*get current backoff ticks*/
async command uint32_t TimerAsync.get_current_number_backoff()
{
return current_number_backoff;
}	

async command uint32_t TimerAsync.get_time_slot_backoff_periods()
{
return time_slot_backoff_periods;
}

async command uint32_t TimerAsync.get_current_time_slot()
{
return current_time_slot;
}


async command uint32_t TimerAsync.get_current_number_backoff_on_time_slot()
{

return current_number_backoff_on_time_slot;

}

async command uint32_t TimerAsync.get_total_tick_counter()
{
return total_tick_counter;
}
async command uint32_t TimerAsync.get_process_frame_tick_counter()
{
		//printfUART("%d\n", process_frame_tick_counter);
		
return process_frame_tick_counter;
}
 
 
//TDBS Implementation
async command error_t TimerAsync.set_track_beacon(uint8_t track)
{
	atomic track_beacon = track;

return SUCCESS;
}

async command error_t TimerAsync.set_track_beacon_start_ticks(uint32_t parent_offset_symbols,uint32_t duration_symbols,uint32_t transmission_delay)
{

atomic{
	
	start_track_beacon_ticks = bi_ticks - ((parent_offset_symbols / backoff_symbols)*backoff_ticks);
	
	end_track_beacon_ticks = start_track_beacon_ticks + ((duration_symbols / backoff_symbols)*backoff_ticks);

	//verify, the node must synchronyze with the parent beacon offset
	ticks_counter = (start_track_beacon_ticks - transmission_delay);
	
	
	//printfUART("start_track_beacon_ticks %i\n", start_track_beacon_ticks);
	//printfUART("end_track_beacon_ticks %i\n", end_track_beacon_ticks);
	
	
	}
return SUCCESS;
}


  
  
  
}
