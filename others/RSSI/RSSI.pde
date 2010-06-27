#include <RF12.h>
#include <Ports.h>

#define SPI_SS 10

static uint16_t rf12_xfer(uint16_t cmd)
{
 uint16_t reply;
 digitalWrite(SPI_SS,0);
 SPDR=cmd>>8;
 while(!(SPSR & _BV(SPIF)))
   ;
 reply=SPDR<<8;

 SPDR=cmd;
 while(!(SPSR & _BV(SPIF)))
   ;
   
   reply |= SPDR;
   digitalWrite(SPI_SS,1);
   return reply;
  
}

void setup()
{
  Serial.begin(57600);
  Serial.println("\n[RSSI]");
  
  rf12_initialize(1,RF12_868MHZ,2);
  rf12_easyInit(0);
  rf12_xfer(0x94A2);
  
  rf12_recvDone();
  cli();
 
}

void loop()
{
  byte v=(rf12_xfer(0)>>8)&1;
  Serial.println("RSSI ");
  Serial.println(v);

}
  
 
