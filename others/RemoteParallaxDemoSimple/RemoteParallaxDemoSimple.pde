

/*******************************************\
Pololu Micro Serial Servo Controller code
 
Control a Pololu Micro SSC using the simple
SSC Protocol with a Jeenode and a Parallax Servo 
with continuous rotation
 
Paolo@ Robomotic Labs
http://lab.robomotic.com
\********************************************/
 
// Make sure the mode blue jumper is ON

#include <RF12.h>
#include <Ports.h>

Port one (1);
//we can control 8 servos in parallel!
byte pwm_value[8]={0,0,0,0,0,0,0,0};
byte last_pwm_value[8]={0,0,0,0,0,0,0,0};
byte last_cmd[3];
byte ack[3];
MilliTimer timer;
char msgCalib[] ="Calibration";
char msgError[]="Error";
char msgReset[]="Reset";
boolean calibrated=false;
void setup()
{
  one.mode(OUTPUT);
  one.digiWrite(0);
  //We don't need all this connections is just a way to experiment
  //Serial HOST connection
  Serial.begin(4200);

  //we use initialize because we don't want serial garbage
  rf12_initialize(2, RF12_868MHZ, 1);
  rf12_easyInit(0);
  timer.set(1);

}
 
 boolean wait_ack()
 {
    byte k=0;
    while(1)
    {
      if(k>=2) break;
      if(Serial.available()==1)
      { 
        ack[k]=Serial.read();
        k++;
      }

    } 

   if(ack[0]==last_cmd[0])
     return true;
   else 
    return false; 
   
 }
 
 void test_speed()
 {
   for(byte s=120;s<220;s++)
   {
   SetServo(1,s);
   delay(1500);
   }
 }
 
 void calibration()
 {
   rf12_easyPoll() ;
  
   //First we reset the Pololu Controller
   one.digiWrite(1);
   delay(100);
   one.digiWrite(0);
   delay(100);
  if(rf12_canSend())
   rf12_easySend(msgReset,5);
   
   //we say that we are calibrating
   if(rf12_canSend())
   rf12_easySend(msgCalib,5);
   SetServo(1,127);
   delay(1000);
   SetServo(0,127);
   delay(1000);
   
   test_speed();
   calibrated=true;
  
 }
 
void loop()
{  

  //now is time to calibrate
  if(!calibrated)
      calibration();
  
  if (rf12_easyPoll() > 0)
  {
    //because we have only 8 servos in this configuration
    byte n = constrain(rf12_len, 1, 8);
    for (byte i = 0; i < n; ++i) {
           //the user choses 10 types of speed [0,9]
           pwm_value[i] = constrain(rf12_data[i], 0, 9);
           //if the speed is more than 0 an offset is added 
           if(pwm_value[i]>0)
           SetServo(i,pwm_value[i]+120); 
    }
    if(rf12_canSend())
      rf12_easySend(last_cmd, 3); // force packet send, no data
  }    
      
}
 
// Sets a given servo to a position.
// Position should be between 0 and 255
// Defaults to 90 degrees of motion
// Add 8 to the servo number for 180 degrees of motion
// (for example, use servo 9 to make servo 1 move 180 degrees)
void SetServo(int servo, byte pulse)
{
  pulse = constrain(pulse, 0, 254);
  servo = constrain (servo, 0, 15);
  last_cmd[0]=255;
  last_cmd[1]=servo;
  last_cmd[2]=pulse;
  Serial.print(255, BYTE);
  Serial.print(servo, BYTE);
  Serial.println(pulse, BYTE);


}
