

/*******************************************\
Pololu Micro Serial Servo Controller code
 
Control a Pololu Micro SSC using the simple
SSC Protocol with a Jeenode and a Parallax Servo 
with continuous rotation
 
Paolo@ Robomotic Labs
http://lab.robomotic.com
\********************************************/
 
// Make sure the mode blue jumper is ON

//#include <NewSoftSerial.h>
#include <RF12.h>
#include <Ports.h>

// The TX PIN is DIO2 on Port 1 and Pin 5 of Arduino
// The RX PIN is DIO3 on Port 3 and Pin 6 of Arduino
#define TXPIN 4
#define RXPIN 7
byte pwm_value=0;
byte last_pwm_value=0;
byte last_cmd[3];
byte ack[3];
NewSoftSerial pololu(RXPIN, TXPIN);
 
void setup()
{
  //We set the IO pins correctly
  pinMode(TXPIN, OUTPUT);
  pinMode(RXPIN, INPUT);
  //we set the TXPIN HIGH
  digitalWrite(TXPIN, HIGH);
  
  //We don't need all this connections is just a way to experiment
  //Serial HOST connection
  Serial.begin(9600);
  
  //Pololu connection
  //pololu.begin(4200);
  
}
 
 boolean wait_ack()
 {
    byte k=0;
    while(1)
    {
      k+=pololu.available();
      ack[k]=pololu.read();
      if(k>=3) break;
      if(k>0) Serial.println(k);
    } 
   if(ack[0]==last_cmd[0])
    return true;
   else return false; 
   
 }
 
 void print_ack()
 {
   Serial.print(ack[0],'HEX');
   Serial.print(ack[1],'HEX');
   Serial.println(ack[2],'HEX');
 }
 
 void calibration()
 {
   Serial.print("Starting calibration");
   SetServo(0,127);
   delay(4000);
   SetServo(1,127);
   delay(4000);
   Serial.print("Finished");
 }
 
void loop()
{  
  
  calibration();
  uint16_t ten = millis() / 10;
  
  if (Serial.available())
  {
    pwm_value=(byte)Serial.read();
    pwm_value = constrain(pwm_value, 0, 127);
  }    
      
  if(pwm_value!=last_pwm_value)  
  {
    Serial.print("Setting ");
    Serial.println(pwm_value);
    SetServo(0,pwm_value);
    SetServo(1,pwm_value);
    last_pwm_value=pwm_value;
  }
  
    //every 2 seconds maybe send to RF
    if ((millis() / 10000) % 2 == 0)
    {
     //do something 
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
  pololu.print(255, BYTE);
  pololu.print(servo, BYTE);
  pololu.println(pulse, BYTE);
  
  wait_ack();
  print_ack();
}
