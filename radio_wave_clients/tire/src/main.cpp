// #include <elapsedMillis.h>

/*
  IBT-2 Motor Control Board driven by Arduino.

  Speed and direction controlled by a potentiometer attached to analog input 0.
  One side pin of the potentiometer (either one) to ground; the other side pin to +5V

  Connection to the IBT-2 board:
  IBT-2 pin 1 (RPWM) to Arduino pin 5(PWM)
  IBT-2 pin 2 (LPWM) to Arduino pin 6(PWM)
  IBT-2 pins 3 (R_EN), 4 (L_EN), 7 (VCC) to Arduino 5V pin
  IBT-2 pin 8 (GND) to Arduino GND
  IBT-2 pins 5 (R_IS) and 6 (L_IS) not connected
*/

int SPEED_PIN = 14; // center pin of the potentiometer
int PID_P_PIN = 15; // P value (for pid)
int PID_I_PIN = 16;
int PID_D_PIN = 17;

int RPWM_Output = 5; // Arduino PWM output pin 5; connect to IBT-2 pin 1 (RPWM)
int LPWM_Output = 6; // Arduino PWM output pin 6; connect to IBT-2 pin 2 (LPWM)

int goReverse = RPWM_Output;
int goForward = LPWM_Output;


boolean startHasRun = 0;
boolean rampUpHasRun = 0;
boolean rampDownHasRun = 0;
boolean goHasRun = 0;
boolean pauseHasRun = 0;

elapsedMillis elapsedTime;
elapsedMillis elapsedBeepTime;
elapsedMillis elapsedBeepOff;


unsigned int delayInterval = 1000;
unsigned int rampSpeedInterval = 1000;
unsigned int goTime = 1000;


//declare beeper variables
int beepOnState = LOW;
IntervalTimer beepTimer;
const int ledPin = LED_BUILTIN;  // pin with LED


unsigned int startupSpeed = 255;
unsigned int maximumSpeed = 255;

int startupKnob = analogRead(SPEED_PIN);   //poteniometer speed setting

//Cast up to a float
float rampSpeedChange = (float)rampSpeedInterval / maximumSpeed;


void setup()
{

  Serial.begin(57600);
  pinMode(RPWM_Output, OUTPUT);
  pinMode(LPWM_Output, OUTPUT);
  pinMode(7, OUTPUT);
  pinMode(13, OUTPUT);
  

  startupKnob = map(startupKnob, 0, 1023, 0, 255);
  //int maximumSpeed = startupKnob;
  //float rampSpeedChange = rampSpeedInterval / maximumSpeed;

  //beepTimer.begin(beep, 500000);  //beep piezo every 500 miliseconds (0.5 seconds)
  int beepOnState = LOW;
}


void knobTest() {
    int sensorValue = analogRead(SPEED_PIN);

  // sensor value is in the range 0 to 1023
  // the lower half of it we use for reverse rotation; the upper half for forward rotation
  if (sensorValue < 512)
  {
    // reverse rotation
    int reversePWM = -(sensorValue - 511) / 2;
    analogWrite(LPWM_Output, 0);
    analogWrite(RPWM_Output, reversePWM);
    Serial.println("Reverse PWM: ");
    Serial.println(reversePWM);
  }
  else
  {
    //     forward rotation
    int forwardPWM = (sensorValue - 512) / 2;
    analogWrite(RPWM_Output, 0);
    analogWrite(LPWM_Output, forwardPWM);
  }
  Serial.println(sensorValue);
}


void startup() {
  int startupKnob = analogRead(SPEED_PIN);   //poteniometer speed setting
  startupKnob = map(startupKnob, 0, 1023, 0, 255);
  int startupSpeed = 64;
 
  if ( (startupKnob > 0) && (!startHasRun) )
  {
    // go reverse for 1 second
    // go forward for 1 second
    // go back to middle and wait
    delay(1000);

    //move forward
    analogWrite(goReverse, 0);
    analogWrite(goForward, startupSpeed);

    Serial.print("Moving Forward: ");
    Serial.println(startupSpeed);
    delay(1000);

    //pause
    analogWrite(goReverse, 0);
    analogWrite(goForward, 0);
    delay(1000);

    //move backwards
    analogWrite(goForward, 0);
    analogWrite(goReverse, startupSpeed);

    Serial.print("Moving Backwards: ");
    Serial.println(startupSpeed);
    delay(1000);  

    analogWrite(goForward, 0);
    analogWrite(goReverse, 0);
    delay(3000);
    
    startHasRun = 1;
  } else if (!startHasRun)
  {
   Serial.println("Speed is Zero!");
   Serial.println("Set speed higher than 0 and restart");
   startHasRun = 1;
  }    
}

void rampUp (int offPin, int onPin, unsigned int rampSpeedInterval) {
  startupKnob = analogRead(SPEED_PIN);   //poteniometer speed setting
  startupKnob = map(startupKnob, 0, 1023, 0, 255);
  maximumSpeed = startupKnob;
  rampSpeedChange = (float)rampSpeedInterval / maximumSpeed;
  
  elapsedTime = 0;
  int value;

  if (rampUpHasRun == 0) {
  Serial.println("Starting Ramp up.");
      do {
        // Cast down to unsigned int
        value = min((unsigned int)(elapsedTime / rampSpeedChange), maximumSpeed);
        analogWrite(offPin, 0);
        analogWrite(onPin, value);      
        Serial.println("RAMPING UP");
        Serial.print("RAMP SPEED IS: ");
        Serial.println(value);
        } while(elapsedTime <= rampSpeedInterval); 
        // Make sure that you finish at maximumSpeed
        analogWrite(offPin, 0);
        analogWrite(onPin, maximumSpeed);
        rampUpHasRun = 1; 
        Serial.println("Ramp State FINISHED ");
        Serial.println(maximumSpeed);
        Serial.println(value);
        Serial.println(elapsedTime);
  }
  rampUpHasRun = 0;
}



void walk(int offPin, int onPin, unsigned int rampSpeedInterval) {
  int startupKnob = analogRead(SPEED_PIN);   //poteniometer speed setting
  startupKnob = map(startupKnob, 0, 1023, 0, 255);
  maximumSpeed = startupKnob;
  
  if (goHasRun == 0) {
    elapsedTime = 0;
    while (elapsedTime < rampSpeedInterval) {
      analogWrite(offPin, 0);
      analogWrite(onPin, maximumSpeed);
      Serial.println("Driving");
      Serial.println("GO FINISHED");
    }
    goHasRun = 1;
    Serial.println(goHasRun);
  }
  goHasRun = 0;
  Serial.println(goHasRun);
}


void pause(unsigned int rampSpeedInterval) {
  if (pauseHasRun == 0) {
    elapsedTime = 0;
    while (elapsedTime < rampSpeedInterval) {
      analogWrite(goForward, 0);
      analogWrite(goReverse, 0);
      Serial.print("PAUSED");
      Serial.println(rampSpeedInterval);
    }
    pauseHasRun = 1;
  }
  pauseHasRun = 0;
}


void beep() {
          if (beepOnState == LOW) {
            beepOnState = HIGH;
            //beepCount = beepCount + 1;
        } else {
          beepOnState = LOW;
        }
        digitalWrite(7, beepOnState);
        digitalWrite(13, beepOnState);        
}


void rampDown (int offPin, int onPin, unsigned int rampSpeedInterval) {
  startupKnob = analogRead(SPEED_PIN);   //poteniometer speed setting
  startupKnob = map(startupKnob, 0, 1023, 0, 255);
  maximumSpeed = startupKnob;
  rampSpeedChange = (float)rampSpeedInterval / maximumSpeed;
  
  elapsedTime = 0;
  int value;

  if (rampDownHasRun == 0) {
  Serial.println("Starting Ramp Down.");
      do {
        // Cast down to unsigned int
        //OLD VALUES  value = min((unsigned int)(elapsedTime / rampSpeedChange), maximumSpeed);
        value = max(maximumSpeed - ((unsigned int)(elapsedTime / rampSpeedChange)), 0);
        analogWrite(offPin, 0);
        analogWrite(onPin, value);      
        Serial.println("RAMPING DOWN");
        Serial.print("RAMP SPEED IS: ");
        Serial.println(value);
        } while(elapsedTime <= rampSpeedInterval); 
        // Make sure that you finish at maximumSpeed
        analogWrite(offPin, 0);
        analogWrite(onPin, 0);
        rampDownHasRun = 1; 
        Serial.println("Ramp State FINISHED ");
        Serial.println(maximumSpeed);
        Serial.println(value);
        Serial.println(elapsedTime);
  }
  rampDownHasRun = 0;
}


void backAndForth() {
  startup();

  Serial.println("MOVING FORWARDS");
  rampUp(goReverse, goForward,1000);    // function(turnPinOff, turnPinOn, time);
  walk(goReverse, goForward, 1000);
  rampDown(goReverse, goForward, 2000);
  //delay(1000);
  //Serial.println("PAUSE");
  
  pause(3000);

  //move backwards
  Serial.println("MOVING BACKWARDS");
  //beepTimer.begin(beep, 500000);   //beep piezo every 500 miliseconds (0.5 seconds)
  rampUp(goForward, goReverse, 1000);
  walk(goForward, goReverse, 1000);
  rampDown(goForward, goReverse, 2000);
  //beepTimer.end();
}



void loop()
{
  //int startupKnob = analogRead(SPEED_PIN);   //poteniometer speed setting
  //startupKnob = map(startupKnob, 2, 96, 0, 255);
  //maximumSpeed = startupKnob;
  delay(300);

  Serial.println("MOVING FORWARDS");
  rampUp(goReverse, goForward,1000);    // function(turnPinOff, turnPinOn, time);
  walk(goReverse, goForward, 2500);
  rampDown(goReverse, goForward, 1000);
  delay(1000);
  Serial.println("PAUSE");
  
  //pause(3000);


  
}