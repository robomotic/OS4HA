// Ports library demo, blinks leds on all 4 ports in slightly different ways
// 2009-02-13 <jcw@equi4.com> http://opensource.org/licenses/mit-license.php
// $Id: blink_ports.pde 5402 2010-04-30 19:24:52Z jcw $

#include <Ports.h>
#include <RF12.h> // needed to avoid a linker error :(

Port one (1);
Port two (2);
Port three (3);
Port four (4);

// leds are connected to pins 2 (DIO) and 3 (GND) with a series resistor

void setup() {
	two.mode(OUTPUT);
	three.mode(OUTPUT);

}

void loop() {
	uint16_t ten = millis() / 10;
	
	// ports 2 and 3 have support for PWM output
	// use bits 0..7 of ten as PWM output level
	// use 8 for up/down choice, i.e. make level ramp up and then down
	uint8_t level = ten;
	if (ten & 0x100)
		level = ~level;
		
	// leds 2 and 3 light up/down in opposite ways every 2x 2.56 sec
	two.anaWrite(level);
	three.anaWrite(~level);
}