#include "RF24.h"
#include "RF24Network.h"
#include "RF24Mesh.h"
#include <SPI.h>
#include <elapsedMillis.h>

#if defined(LEO)
RF24 radio(7, 8);
#else
RF24 radio(9, 10);
#endif
RF24Network network(radio);
RF24Mesh mesh(radio, network);

#define nodeID 44

int led = 8;
uint32_t displayTimer = 0;

struct payload_t {
  unsigned long value;
};

/**
  SET UP TIMER VAR FOR EXTINGUISHER MACHINE 
**/

const int extinguisherPin = 7;
bool extinguisherIsOn = true;

int speedPin = 3;
int dirPin = 4;
int sleepPin = 2;
int breathSpeed = 0;

//  [FORWARD / BRAKE at speed PWM %] dirPin LOW && PWM %
//  [REVERSE / BRAKE at speed PWM%] dirPin HIGH && PWM %


int extinguisherTimeOn = 1000 * 15;
int extinguisherTimeOff = 1000 * 30;

elapsedMillis sinceExtinguisherOn;
elapsedMillis sinceExtinguisherOff;


void breath(int breathSpeed) {
  digitalWrite(dirPin, HIGH);
  analogWrite(speedPin, breathSpeed);
  Serial.println("Breathing at");
  Serial.print(breathSpeed);
}

void extinguisherOn() {
  extinguisherIsOn = true;
  digitalWrite(extinguisherPin, HIGH);
  Serial.println("EXTINGUISHER IS ON");
}

void extinguisherOff() {
  extinguisherIsOn = false;
  digitalWrite(extinguisherPin, LOW);
  Serial.println("EXTINGUISHER IS OFF");
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

  Serial.println("LED PIN");  
  pinMode(led, OUTPUT);
  pinMode(extinguisherPin, OUTPUT);
  
  pinMode(speedPin, OUTPUT);
  pinMode(dirPin, OUTPUT);
  pinMode(sleepPin, OUTPUT);
  digitalWrite(sleepPin, HIGH);  

 // extinguisherOn();

  sinceExtinguisherOn = 0;
  sinceExtinguisherOff = 0;

}

void loop() {
  
//  if (!extinguisherIsOn && sinceExtinguisherOn >= extinguisherTimeOff) {
//   extinguisherOn();
//   sinceExtinguisherOff = 0;
//   sinceExtinguisherOn = 0;
//   Serial.println("Extinguisher On for 15 seconds");  
//  }

//  if (extinguisherIsOn && sinceExtinguisherOff >= extinguisherTimeOn) {
  //  extinguisherOff();
  //  sinceExtinguisherOn = 0;
  //  sinceExtinguisherOff = 0;
  //  Serial.println("Extinguisher off for 30 seconds");
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

    breath(payload.value);

//    if (payload.value == 0) {
//      Serial.println("LOOOWWW");
//      digitalWrite(led, LOW);
//    } else {
//      Serial.println("HIIIIGGGHHHH");
//      digitalWrite(led, HIGH);
//    }
//  }

}
