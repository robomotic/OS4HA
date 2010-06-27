
#define ALARM 0x01
#define TELEMETRY 0x02

#define START 0x01
#define STOP  0x02
#define FALL 0x03

struct PayloadEmma{
    byte type;     // light sensor
    byte value;  // motion detector
    byte lobat;  // supply voltage dropped under 3.1V
} ;

struct PayloadRoom{
    byte light;     // light sensor
    byte moved :1;  // motion detector
    byte humi  :7;  // humidity
    int temp   :10; // temperature
    byte lobat :1;  // supply voltage dropped under 3.1V
};


