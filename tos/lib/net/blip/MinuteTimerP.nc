
module MinuteTimerP
{
	provides interface MinuteTimer[uint8_t id];
	uses interface Timer<TMilli> as Timer[uint8_t num];
	uses interface Leds;
}

implementation
{

	enum
	{
		RUNNING=1,
		STARTING=2,
		FIRED=3,
		COMPLETED=4,


	};

	uint8_t STATE[uniqueCount("Minute")];
	uint16_t period[uniqueCount("Minute")];
	uint16_t count[uniqueCount("Minute")];


	event void Timer.fired[uint8_t num]()
	{
		
		count[num]++;
		if(STATE[num]==FIRED)
		{
			if(count[num]==2*period[num])
			{
				STATE[num]=COMPLETED;	

			}
			else
			{
				call Timer.startOneShot[num](30720U); //30seconds=30*1024
			}
		}

		if(STATE[num]==COMPLETED)
		{
			
			signal MinuteTimer.fired[num]();	
			call Timer.stop[num]();		
			count[num]=0;
	
		}
		
			
	}

	command error_t MinuteTimer.startOneShot[uint8_t id](uint16_t minutes)
	{
		period[id]=minutes;
		call Timer.startOneShot[id](30720U); //30seconds=30*1024
		STATE[id]=FIRED;
		return SUCCESS;

	}

	default event void MinuteTimer.fired[uint8_t id](){	
	}


}
