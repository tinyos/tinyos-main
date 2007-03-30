module AntiTheftRootC
{
  uses
  {
    interface Boot;
    interface SplitControl as SerialControl;
    interface SplitControl as RadioControl;
    interface LowPowerListening;

    interface DisseminationUpdate<settings_t> as SettingsUpdate;
    interface Receive as SettingsReceive;

    interface StdControl as CollectionControl;
    interface RootControl;
    interface Receive as AlertsReceive;
    interface AMSend as AlertsForward;

    interface Leds;
  }
}
implementation
{
  event void Boot.booted()
  {
    call SerialControl.start();
    call RadioControl.start();
  }

  event void SerialControl.startDone(error_t error) { }
  event void SerialControl.stopDone(error_t error) { }
  event void RadioControl.startDone(error_t error) { 
    if (error == SUCCESS)
      {
	call LowPowerListening.setLocalDutyCycle(200);
	call CollectionControl.start();
	call RootControl.setRoot();
      }
  }
  event void RadioControl.stopDone(error_t error) { }

  event message_t *SettingsReceive.receive(message_t* msg, void* payload, uint8_t len)
  {
    settings_t *newSettings = payload;

    if (len == sizeof(*newSettings))
      {
	call Leds.led2Toggle();
	call SettingsUpdate.change(newSettings);
      }
    return msg;
  }

  message_t fwdMsg;
  bool fwdBusy;

  event message_t *AlertsReceive.receive(message_t* msg, void* payload, uint8_t len)
  {
    alert_t *newAlert = payload;

    call Leds.led0Toggle();

    if (len == sizeof(*newAlert) && !fwdBusy)
      {
	alert_t *fwdAlert = call AlertsForward.getPayload(&fwdMsg);

	*fwdAlert = *newAlert;
	if (call AlertsForward.send(AM_BROADCAST_ADDR, &fwdMsg, sizeof *fwdAlert) == SUCCESS)
	  fwdBusy = TRUE;
      }
    return msg;
  }

  event void AlertsForward.sendDone(message_t *msg, error_t error) {
    if (msg == &fwdMsg)
      fwdBusy = FALSE;
  }

}
