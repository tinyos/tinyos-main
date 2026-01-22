/*Interface File*/


interface MinuteTimer
{

	command error_t startOneShot(uint16_t minutes);

	event void fired();

}

