README for Mts400Tester
Author/Contact: Zoltán Kincses, kincsesz@inf.u-szeged.hu

Description:

This is a demo application for the mts400 sensor board. This board contains a 2-Axis accelerometer (Analog Devices ADXL202JE), a barometric pressure and temperature sensor (Intersema MS5534), a humidity and temperature sensor (Sensirion SHT11), and a light sensor (Taos TSL2550). You can find detailed description about the board at the http://courses.ece.ubc.ca/494/files/MTS-MDA_Series_Users_Manual_7430-0020-04_B.pdf website. In this application, the Accel202C sensor is sampled first in the X and then in the Y direction. In the next step, the Intersema5534C sensor is sampled, and the read values are stored in an array. The first element is the temperature and the second is the pressure. After this, the SensirionSht11C sensor is sampled, where the raw temperature and then humidity data is read. Finally, the Taos255C sensor is sampled, where the raw visible and then infrared light data is read. The read values are sent to the basestation, and the sampling process starts again. The raw data read from the SensirionSht11C and Taos2550C sensors have to be converted, according to the datasheets of the sensors. The required conversions are done in the example java code. To compile the application, two include directories are required, which can be found in the Makefile of the application. The output normally looks like the following:

Accelerometer X axis:  the measured value (in g)
Accelerometer Y axis:  the measured value (in g)
Intersema temperature: the measured value (in degree centigrade)
Intersema pressure:    the measured value (in mbar)
Sensirion temperature: the converted value (in degree centigrade)
Sensirion humidity:    the converted value (in %RH)
Taos visible light:    the converted value (in Lux)
Taos infrared light:   the converted value (in Lux)

The displayed Intersema temperature and pressure values always contain one decimal digit. For example, if the measured temperature value is 262, it means that the temperature is 26.2 degree centigrade. Similarly if the measured pressure value is 9922, it means the pressure is 992.2 mbar.
During the operation of the application, the led0 indicates that the mote is on, and the led1 indicates the mote sent the measured data to the basestation.

Tools:
The Mts400Tester.java is the example java code.

Known bugs/limitations:
None.

$Id: README.txt,v 1.1 2010-06-21 22:56:11 mmaroti Exp $

