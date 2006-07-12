README for TestAdc
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

TestAdc is an application for testing the ADC subsystem. It requires a generic
platform dependent DemoSensorC, DemoSensorNowC and DemoSensorStreamC components
that provide the following interfaces: Read<uint16_t> (DemoSensorC),
ReadStream<uint16_t> (DemoSensorStreamC) and ReadNow<uint16_t> and Resource (DemoSensorNowC).
It requests data via the three data collection interfaces and switches on
leds 0, 1 and 2 when the conversion results are signalled from the ADC subsystem:

 LED0 denotes a successful Read operation,
 LED1 denotes a successful ReadNow operation,
 LED2 denotes a successful ReadStream operation.

Please refer to TEP 101 for more information on the ADC abstraction.

