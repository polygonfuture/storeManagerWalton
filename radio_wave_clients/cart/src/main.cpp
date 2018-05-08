#include "RF24.h"
#include "RF24Network.h"
#include "RF24Mesh.h"
#include <SPI.h>

#if defined(LEO)
RF24 radio(7, 8);
#else
RF24 radio(9, 10);
#endif
RF24Network network(radio);
RF24Mesh mesh(radio, network);

#define nodeID 22

int motorPin = 3;
//int led = 13;
uint32_t displayTimer = 0;

struct payload_t {
  unsigned long value;
};

/**
  SET UP TIMER VAR FOR FOG MACHINE 
**/

const int fogPin = 7;
bool fogIsOn = true;

int fogTimeOn = 1000 * 60 * 1.5;
int fogTimeOff = 1000 * 60 * 3;

elapsedMillis sinceFogOn;
elapsedMillis sinceFogOff;


void fogOn() {
  fogIsOn = true;
  digitalWrite(fogPin, HIGH);
  Serial.println("FOG IS ON");
}

void fogOff() {
  fogIsOn = false;
  digitalWrite(fogPin, LOW);
  Serial.println("FOG IS OFF");
}

void setup() {
  Serial.begin(115200);
  delay(5000);

  mesh.setNodeID(nodeID);
  Serial.println(F("Connecting to the mesh..."));
  
  mesh.begin(
    MESH_DEFAULT_CHANNEL,     // channel
    RF24_1MBPS,               // data_rate
    1000*5                    // timeout
  );


  Serial.println("Motor PIN");  
  pinMode(motorPin, OUTPUT);
  pinMode(fogPin, OUTPUT);
  

//  fogOn();

//  sinceFogOn = 0;
//  sinceFogOff = 0;

}

void loop() {
  
 // if (!fogIsOn && sinceFogOn >= fogTimeOff) {
 //  fogOn();
 //  sinceFogOff = 0;
 //  sinceFogOn = 0;
 //  Serial.println("Fog On for 1.5 minutes");  
 // }

 // if (fogIsOn && sinceFogOff >= fogTimeOn) {
 //   fogOff();
 //   sinceFogOn = 0;
 //   sinceFogOff = 0;
 //   Serial.println("Fog off for 3 minutes");
 // }

  mesh.update();

  // Send to the master node every second
  if (millis() - displayTimer >= 1000) {
    displayTimer = millis();
    // Send an 'M' type message containing the current millis()
    if (!mesh.write(&displayTimer, 'M', sizeof(displayTimer))) {

      // If a write fails, check connectivity to the mesh network
      if ( ! mesh.checkConnection() ) {
        //refresh the network address
        Serial.println("Renewing Address");
        mesh.renewAddress();
      } else {
        Serial.println("Send fail, Test OK");
      }
    } else {
      Serial.print("Send OK: "); Serial.println(displayTimer);
    }
  }

  while (network.available()) {
    RF24NetworkHeader header;
    payload_t payload;
    network.read(header, &payload, sizeof(payload));
    Serial.print("Received value #");
    Serial.println(payload.value);
    if (payload.value == 0) {
      Serial.println("LOOOWWW");
      digitalWrite(motorPin, LOW);
    } else {
      Serial.println("HIIIIGGGHHHH");
      digitalWrite(motorPin, HIGH);
    }
  }

}

