// This example sends commands to wireless switches in the hs1527 format on 433 Mhz.
// 2009-02-21 <jcw@equi4.com> http://opensource.org/licenses/mit-license.php
// 2010-03-10 <poem.michael@oiu.ch> http://opensource.org/licenses/mit-license.php
// $Id$

// Note that 868 MHz RFM12B's can send 433 MHz just fine, even though the RF
// circuitry is presumably not optimized for that band. Maybe the range will
// be limited, or maybe it's just because 868 is nearly a multiple of 433 ?

// I've tested the code also with a RFM12B build for the 433MHz band and an 16.4mm
// whip antenna. It works quit over a distance.

// Devices tested: SITE - Model RCS-K08

#include <Ports.h>
#include <RF12.h>
#include <avr/eeprom.h>
#include <avr/pgmspace.h>

//min 270 - max 650 -> smaller intervall = less power usage therfore
#define pulseLength0 400
#define pulseLength1 1200 //pulseLength * 3
#define pulseLengthS 12400 //pulseLength * 31

static byte value, stack[RF12_MAXDATA],top;


char helpText[] PROGMEM = 
    "Flash storage (JeeLink v2 only):" "\n"
    "  d                                - dump all log markers" "\n"
    "  <sh>,<sl>,<t3>,<t2>,<t1>,<t0> r  - replay from specified marker" "\n"
    "  123,<bhi>,<blo> e                - erase 4K block" "\n"
    "  12,34 w                          - wipe entire flash memory" "\n"
;

static void showString(PGM_P s) {
    for (;;) {
        char c = pgm_read_byte(s++);
        if (c == 0)
            break;
        if (c == '\n')
            Serial.print('\r');
        Serial.print(c);
    }
}

// Turn transmitter on or off, but also apply asymmetric correction and account
// for 25 us SPI overhead to end up with the proper on-the-air pulse widths.
// With thanks to JGJ Veken for his help in getting these values right.
static void ookPulse(int on, int off) {
rf12_onOff(1);
delayMicroseconds(on+150);
rf12_onOff(0);
delayMicroseconds(off-200);
}

static void hs1527_train(long device_nr, int channel) {
  for(int a = 100; a > 0; a--) { // minimal 3 successive trams are required

  ookPulse(pulseLength0, pulseLengthS); //sync

  for(int b = 19; b > -1; b--)
    hs1527_bit((device_nr >> b) & 0b1); //device nr

  hs1527_bit(0); //on - off

  for(int b = 2; b > -1; b--)
    hs1527_bit((channel >> b) & 0b1); //channel
  }
}


// Sends a single bit in hs1527 definition
static void hs1527_bit(boolean data) {
if(data)
ookPulse(pulseLength0, pulseLength1);//1
else
ookPulse(pulseLength1, pulseLength0);//0
}

// Sends the whole bit tram in hs1527 definition
static void hs1527_tram(long device_nr, boolean on, int channel) {
for(int a = 5; a > 0; a--) { // minimal 3 successive trams are required

ookPulse(pulseLength0, pulseLengthS); //sync

for(int b = 19; b > -1; b--)
hs1527_bit((device_nr >> b) & 0b1); //device nr

hs1527_bit(on); //on - off

for(int b = 2; b > -1; b--)
hs1527_bit((channel >> b) & 0b1); //channel
}
}

static void showHelp () {
    showString(helpText);
}


static void handleInput (char c) {
    if ('0' <= c && c <= '9')
        value = 10 * value + c - '0';
    else if (c == ',') {
        if (top < sizeof stack)
            stack[top++] = value;
        value = 0;
    } else if ('a' <= c && c <='z') {
        Serial.print("> ");
        Serial.print((int) value);
        Serial.println(c);
        switch (c) {
            default:
                showHelp();
                break;
            case 'u': // set node id
                Serial.println("Channel UP");
                hs1527_tram(992363, 0, value); //channel 4 on
                delay(1000);
                break;
            case 'd': // set band: 4 = 433, 8 = 868, 9 = 915
                hs1527_tram(992363, 1, value); //channel 4 off
                 Serial.println("Channel DOWN");
                delay(1000);
                break;
            case 't': // set network group
                hs1527_train(992363, 3);
                Serial.println("Channel TRAINING");
                break;
        }
        value = top = 0;
        memset(stack, 0, sizeof stack);
    } else if (c > ' ')
        showHelp();
}


void setup() {
Serial.begin(57600);
Serial.println("\n[hs1527_demo]");
rf12_initialize(0, RF12_433MHZ);
}

void loop() {
if (Serial.available())
    handleInput(Serial.read());

}
