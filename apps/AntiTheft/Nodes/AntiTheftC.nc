module AntiTheftC
{
  uses {
    interface Timer<TMilli> as Check;
    interface Read<uint16_t>;
    interface ReadStream<uint16_t>;
    interface Leds;
    interface Boot;
    interface Mts300Sounder;
    interface DisseminationValue<settings_t> as SettingsValue;
    interface Send as AlertRoot;
    interface StdControl as CollectionControl;
    interface SplitControl as RadioControl;
    interface LowPowerListening;
    interface AMSend as TheftSend;
    interface Receive as TheftReceive;
  }
}
implementation
{
  enum {
    DARK_THRESHOLD = 200,
    WARNING_TIME = 3,
    ACCEL_SAMPLES = 10
  };

  settings_t settings;
  message_t alertMsg, theftMsg;
  uint16_t ledTime;
  uint16_t accelSamples[ACCEL_SAMPLES];

  void errorLed() {
    ledTime = WARNING_TIME;
    call Leds.led2On();
  }

  void settingsLed() {
    ledTime = WARNING_TIME;
    call Leds.led1On();
  }

  void theftLed() {
    ledTime = WARNING_TIME;
    call Leds.led0On();
  }

  void updateLeds() {
    if (ledTime && !--ledTime)
      {
	call Leds.led0Off();
	call Leds.led1Off();
	call Leds.led2Off();
      }
  }

  void check(error_t ok) {
    if (ok != SUCCESS)
      errorLed();
  }

  void theft() {
    if (settings.alert & ALERT_LEDS)
      theftLed();
    if (settings.alert & ALERT_SOUND)
      call Mts300Sounder.beep(100);
    if (settings.alert & ALERT_RADIO)
      check(call TheftSend.send(AM_BROADCAST_ADDR, &theftMsg, 0));
    if (settings.alert & ALERT_ROOT)
      {
	alert_t *newAlert = call AlertRoot.getPayload(&alertMsg);
	newAlert->stolenId = TOS_NODE_ID;
	check(call AlertRoot.send(&alertMsg, sizeof *newAlert));
      }
  }

  event void AlertRoot.sendDone(message_t *msg, error_t ok) { }
  event void TheftSend.sendDone(message_t *msg, error_t ok) { }

  event message_t *TheftReceive.receive(message_t* msg, void* payload, uint8_t len) {
    theftLed();
    return msg;
  }
  
  void resetTimer() {
    call Check.startPeriodic(settings.checkInterval);
  }
  
  event void Boot.booted() {
    errorLed();
    settings.alert = DEFAULT_ALERT;
    settings.detect = DEFAULT_DETECT;

    call Check.startPeriodic(DEFAULT_CHECK_INTERVAL);
    call RadioControl.start();
  }

  event void RadioControl.startDone(error_t ok) {
    if (ok == SUCCESS)
      {
	call CollectionControl.start();
	call LowPowerListening.setLocalDutyCycle(200);
      }
    else
      errorLed();
  }

  event void RadioControl.stopDone(error_t ok) { }

  event void SettingsValue.changed() {
    const settings_t *newSettings = call SettingsValue.get();

    settingsLed();
    settings = *newSettings;
    call Check.startPeriodic(newSettings->checkInterval);
  }

  event void Check.fired() {
    updateLeds();

    if (settings.detect & DETECT_DARK)
      call Read.read();
    if (settings.detect & DETECT_ACCEL)
      {
	call ReadStream.postBuffer(accelSamples, ACCEL_SAMPLES);
	call ReadStream.read(10000);
      }
  }

  event void Read.readDone(error_t ok, uint16_t val) {
    if (ok == SUCCESS && val < DARK_THRESHOLD)
      theft();
  }

  task void checkAcceleration() {
    uint8_t i;
    uint16_t avg;
    uint32_t var;

    for (avg = 0, i = 0; i < ACCEL_SAMPLES; i++)
      avg += accelSamples[i];
    avg /= ACCEL_SAMPLES;

    for (var = 0, i = 0; i < ACCEL_SAMPLES; i++)
      {
	int16_t diff = accelSamples[i] - avg;
	var += diff * diff;
      }

    if (var > 4 * ACCEL_SAMPLES)
      theft();
  }

  event void ReadStream.readDone(error_t ok, uint32_t usActualPeriod) {
    if (ok == SUCCESS)
      post checkAcceleration();
    else
      errorLed();
  }

  event void ReadStream.bufferDone(error_t ok, uint16_t *buf, uint16_t count) { }
}
