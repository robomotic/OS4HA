// Demo of the Gravity Plug, based on the GravityPlug class in the Ports library
// 2010-03-19 <jcw@equi4.com> http://opensource.org/licenses/mit-license.php
// $Id: gravity_demo.pde 4884 2010-03-19 02:34:43Z jcw $

#include <Ports.h>
#include <RF12.h> // needed to avoid a linker error :(
#include <avr/sleep.h>

BlinkPlug buttons (3);

PortI2C myBus (4);
GravityPlug sensor (myBus);

byte radioIsOn;
MilliTimer readoutTimer, aliveTimer;

#define ALARM 0x01
#define TELEMETRY 0x02

#define START 0x01
#define STOP  0x02
#define FALL 0x03
struct {
    byte type;     // light sensor
    byte value;  // motion detector
    byte lobat;  // supply voltage dropped under 3.1V
} payload;

static void lowPower (byte mode) {
    // disable the ADC
    byte prrSave = PRR, adcsraSave = ADCSRA;
    ADCSRA &= ~ bit(ADEN);
    PRR &= ~ bit(PRADC);
    // go into power down mode
    set_sleep_mode(mode);
    sleep_mode();
    // re-enable the ADC
    PRR = prrSave;
    ADCSRA = adcsraSave;
}

static void loseSomeTime (word ms) {
    // only slow down for longer periods of time, as this is a bit inaccurate
    if (ms > 100) {
        word ticks = ms / 32 - 1;
        if (ticks > 127)    // careful about not overflowing as a signed byte
            ticks = 127;
        rf12_sleep(ticks);  // use the radio watchdog to bring us back to life
        lowPower(SLEEP_MODE_PWR_DOWN); // now we'll completely power down
        rf12_sleep(0);      // stop the radio watchdog again
        // adjust the milli ticks, since we've just missed lots of them
        extern volatile unsigned long timer0_millis;
        timer0_millis += 32U * ticks;
    }
}


void setup () {
    Serial.begin(57600);
    Serial.println("\EMMA node");
    sensor.begin();
    
    rf12_config();
    // set up easy transmissions at maximum rate
    rf12_easyInit(0);
    // start with the radio on
    radioIsOn = 1;

}

void loop () {
 
  
      // switch to idle mode while waiting for the next event
    lowPower(SLEEP_MODE_IDLE);
    // keep the easy tranmission mechanism going
    if (radioIsOn && rf12_easyPoll() == 0) {
        rf12_sleep(0); // turn the radio off
        radioIsOn = 0;
    }
    // if we will wait for quite some time, go into total power down mode
    if (!radioIsOn)
        loseSomeTime(readoutTimer.remaining());
    // only take an accelerometer reading 10 Hz
    byte pushed = buttons.pushed();
    if (readoutTimer.poll(100) || pushed) {
          //check the bloody battery
          payload.lobat = rf12_lowbat();
          
          const double* g = sensor.getGvals();

          
          if(pushed & 1)
          {
             payload.type=ALARM;
             payload.value=START;
          }
          else if (pushed & 2)
          {
             payload.type=ALARM;
             payload.value=STOP;
          }
          else
          {
            if(sensor.getAbsG(1.5))
            { 
              payload.type=ALARM;
              payload.value=FALL;
            }
            else
            {
              payload.type=TELEMETRY;
              payload.value=0;
            }
            
          }
        // send measurement data, but only when it changes
        char sending = rf12_easySend(&payload, sizeof payload);
        
        // force a "sign of life" packet out every 60 seconds
        if (aliveTimer.poll(60000))
            sending = rf12_easySend(0, 0); // always returns 1
        if (sending) {
            // make sure the radio is on again
            if (!radioIsOn)
                rf12_sleep(-1); // turn the radio back on
            radioIsOn = 1;
        }
    }
    

}
