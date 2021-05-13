
#include "Timer.h"
generic configuration MinuteTimerC()
{
	provides interface MinuteTimer[uint8_t id];

}

implementation
{

	components MinuteConfigurationC;
	MinuteTimer=MinuteConfigurationC;
}
