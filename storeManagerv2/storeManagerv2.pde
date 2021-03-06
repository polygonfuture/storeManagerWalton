import controlP5.*;
import java.util.EnumMap;

import processing.net.*;
ControlP5 cp5;
Toggle server;
Slider tire;
Toggle tireSwitch;
Toggle cart;
Toggle fridge;
Slider extinguisher;
Toggle extinguisherSwitch;
Toggle all;
Toggle timer;

boolean TIMER_MODE = false;
boolean everythingIsOn = false;

int STAY_OFF_FOR_TEN_MINUTES = 30 * 1000;//60 * 10;
int STAY_ON_FOR_ONE_MINUTE = 20 * 1000;//60;

PrintWriter output;

int col = color(255);

color okBgColor;
color disabledBgColor = color(0, 100, 0);

int Extinguisher = 0;
int Tire = 0;

Client c;

enum Thing
{
  TIRE, CART, FRIDGE, EXTINGUISHER;
}



// https://docs.oracle.com/javase/6/docs/api/java/util/EnumMap.html
EnumMap<Thing, Byte> state = new EnumMap<Thing, Byte>(Thing.class);

void connect(){
  try{
    c = new Client(this, "127.0.0.1", 11999);
  }
  catch (Exception e) {
    System.err.println("Something went wrong...");
    e.printStackTrace();
  }
}

void initializeState(){
  state.put(Thing.TIRE, byte(0)); 
  state.put(Thing.CART, byte(0));
  state.put(Thing.FRIDGE, byte(0));
  state.put(Thing.EXTINGUISHER, byte(0));

}


void createUI(){
  cp5 = new ControlP5(this);
  
  server = cp5.addToggle("Server");
   server.setPosition(650,30)
   .setSize(100,40)
   .setValue(c.active())
    ;


  tireSwitch = cp5.addToggle("TireSwitch");
   tireSwitch.setPosition(50,160) 
   .setSize(80,80)
    ;

  tire = cp5.addSlider("Tire");
   tire.setPosition(50,280)
   .setSize(80,160)
   .setRange(-10, 150)
   ;
   
   
  extinguisherSwitch = cp5.addToggle("ExtinguisherSwitch");
   extinguisherSwitch.setPosition(260,160)
   .setSize(80,80)
     ;
     
  extinguisher = cp5.addSlider("Extinguisher");
   extinguisher.setPosition(260,280)
   .setSize(80,160)
    .setRange(-10, 300)
     ;
     
  cart = cp5.addToggle("Cart");
   cart.setPosition(470,240)
   .setSize(80,200)
     ;
     
  fridge = cp5.addToggle("Fridge");
   fridge.setPosition(660,240)
   .setSize(80,200)
     ;
     
  all = cp5.addToggle("ALL ON");
   all.setPosition(50,30)
   .setSize(160,40)
     ;
     
  timer = cp5.addToggle("TIMER");
   timer.setPosition(300,30)
   .setSize(160,40)
     ;
  okBgColor = color(cp5.getController("Fridge").getColor().getBackground());
}


void updateUI(){
  c.write("QUERY\r\n");
  delay(100);
  if (c.available() > 0) {
    String d = c.readString();
    try {
      d = d.replace("\r", "");
      d = d.replace("\n", "");
      JSONObject json = parseJSONObject(d);
      for(Thing thing : state.keySet()) {
        String controllerName = thing.name();
        if(json.hasKey(controllerName)){
          boolean alive = json.getJSONObject(controllerName).getBoolean("alive");
          int lastValue = json.getJSONObject(controllerName).getInt("lastValue");
          setLock(controllerName, alive);
          // println("Server says that "+ controllerName + " alive status is: " + alive);
          println("Server says that "+ controllerName + " last value status is: " + lastValue);
        }
      }
    } catch (java.lang.RuntimeException e) {
      println("Error receiving response from server.");
      println(d);
      println("Stacktrace below:");
      e.printStackTrace();
    }
  }
}

void setLock(Controller theController, boolean theValue) {
  theController.setLock(!theValue);
  if(theValue) {
    theController.setColorBackground(okBgColor);
  } else {
    theController.setColorBackground(disabledBgColor);
  }
}

void setLock(String controllerName, boolean theValue) {
  switch(controllerName) {
    case("TIRE"):setLock(tire, theValue);break;
    case("CART"):setLock(cart, theValue);break;
    case("FRIDGE"):setLock(fridge, theValue);break;
    case("EXTINGUISHER"):setLock(extinguisher, theValue);break;
  }
}

  
  // Create a new file in the sketch directory
  // output = createWriter("positions.txt"); 
int switchOn = 0;

int time = millis();
int timed = millis();


int sinceEverythingOn;
int sinceEverythingOff;

void setup() {
  //fullScreen();
  size(800,480);
  smooth();

  connect();
  initializeState();
  createUI();
  updateUI();
  sinceEverythingOff = millis();
  sinceEverythingOn = millis();
}

void turnEverythin(float value){
  float extinsuisherValue = (value) == 0.0 ? 0.0 : 128.0;
  tireSwitch.setValue(value);
  tire.setValue(value);
  cart.setValue(value);
  fridge.setValue(value);
  extinguisherSwitch.setValue(value);
  extinguisher.setValue(extinsuisherValue);
  if(c.active()){
    String s="{\"FRIDGE\":"+value+","+
    "\"TIRE\":"+value+","+
    "\"EXTINGUISHER\":"+extinsuisherValue+","+
    "\"CART\":"+value+"}\r\n";
    c.write(s);
    delay(300);
    if (c.available() > 0) { // If there's incoming data from the client...
      String response = c.readString();
      if(response.charAt(0) == '0'){
        all.setValue(value);
      }
    }
    else{
      all.setValue(value);
    }
  }
}
void turnEverythingOnTimer(){
  turnEverythin(1.0);
  everythingIsOn = true;
  sinceEverythingOff = millis();
  sinceEverythingOn = millis();
  println("EVerything On for 1 minutes");  
}

void turnEverythingOffTimer(){
  turnEverythin(0.0);
  everythingIsOn = false;
  sinceEverythingOn = millis();
  sinceEverythingOff = millis();
  println("EVerything off for 10 minutes");
}

void draw() {
  if (millis() > timed + 1000)
  {
    timed = millis();
    println("millis(): " + millis());
    // println("sinceEverythingOn: " + sinceEverythingOn);
    println("sinceEverythingOn + STAY_OFF_FOR_TEN_MINUTES: " + (sinceEverythingOn + STAY_OFF_FOR_TEN_MINUTES));
    // println("sinceEverythingOff: " + sinceEverythingOff);
    println("sinceEverythingOff + STAY_ON_FOR_ONE_MINUTE: " + (sinceEverythingOff + STAY_ON_FOR_ONE_MINUTE));

  }
  if(TIMER_MODE){
    if (!everythingIsOn && millis() > sinceEverythingOn + STAY_OFF_FOR_TEN_MINUTES) {
      println(sinceEverythingOn);
      turnEverythingOnTimer();
    }
    if (everythingIsOn && millis() > sinceEverythingOff + STAY_ON_FOR_ONE_MINUTE) {
      println(sinceEverythingOff);
      turnEverythingOffTimer();
    }
    // sinceEverythingOn += millis();
    // sinceEverythingOff += millis();
  }

  background(0);
  if(c.active()){
    if (millis() > time + 5000)
    {
      time = millis();
      updateUI();
    }
  }
  pushMatrix();
  popMatrix();
}

void controlEvent(CallbackEvent theEvent) {
  if (theEvent.getController().equals(timer)) {
    switch(theEvent.getAction()) {
      case(ControlP5.ACTION_RELEASED):
        boolean timerIsOn = theEvent.getController().getValue()>0.0;
        setLock(tire, !timerIsOn);
        setLock(cart, !timerIsOn);
        setLock(fridge, !timerIsOn);
        setLock(extinguisher, !timerIsOn);
        setLock(tireSwitch, !timerIsOn);
        setLock(extinguisherSwitch, !timerIsOn);
        setLock(all, !timerIsOn);
        TIMER_MODE = timerIsOn;
        if(timerIsOn){
          turnEverythingOnTimer();
        }
      break;
    }
  }
  else if (theEvent.getController().equals(all)) {
    switch(theEvent.getAction()) {
      case(ControlP5.ACTION_RELEASED): 
        turnEverythin(theEvent.getController().getValue());
      break;
    }
  }
  else if(
    theEvent.getAction() == ControlP5.ACTION_RELEASED &&
    all.getValue() == 1.0
  ){
    all.setValue(0.0);
  }


  if (theEvent.getController().equals(fridge)) {
    switch(theEvent.getAction()) {
      case(ControlP5.ACTION_RELEASED): 
      if(c.active()){
        String s="{\"FRIDGE\":"+theEvent.getController().getValue()+"}\r\n";
        c.write(s);
        delay(300);
        if (c.available() > 0) { // If there's incoming data from the client...
          String response = c.readString();
          if(response.charAt(0) == '0'){
            fridge.setValue(1.0-theEvent.getController().getValue());
          }
        }
        else{
            fridge.setValue(1.0-theEvent.getController().getValue());
        }
      }
      break;
    }
  }
  else if (theEvent.getController().equals(tireSwitch)) {
    switch(theEvent.getAction()) {
      case(ControlP5.ACTION_RELEASED): 
      if(c.active()){
        String s="{\"TIRE\":"+int(theEvent.getController().getValue())+"}\r\n";
        c.write(s);
      }
      break;
    }
  }
    else if (theEvent.getController().equals(extinguisherSwitch)) {
    switch(theEvent.getAction()) {
      case(ControlP5.ACTION_RELEASED): 
      if(c.active()){
        float extinsuisherValue = (theEvent.getController().getValue()) == 0.0 ? 0.0 : 128.0;
        String s="{\"EXTINGUISHER\":"+extinsuisherValue+"}\r\n";
        c.write(s);
        if (c.available() > 0) { // If there's incoming data from the client...
          String response = c.readString();
          if(response.charAt(0) == '0'){
            extinguisher.setValue(extinsuisherValue);
          }
        }
        else{
          extinguisher.setValue(extinsuisherValue);
        }
      }
      break;
    }
  }
  else if (theEvent.getController().equals(tire)) {
    switch(theEvent.getAction()) {
      case(ControlP5.ACTION_RELEASED): 
      if(c.active()){
        int value = int(-1.0+theEvent.getController().getValue());
        String s="{\"TIRE\":"+value+"}\r\n";
        c.write(s);
      //   delay(200);
      //   if (c.available() > 0) { // If there's incoming data from the client...
      //     String response = c.readString();
      //     // println(response);
      //     // println(response == "OK\r");
      //   }
      }
      break;
    }
  }
  else if (theEvent.getController().equals(extinguisher)) {
    switch(theEvent.getAction()) {
      case(ControlP5.ACTION_RELEASED): 
      if(c.active()){
        int value = int(theEvent.getController().getValue());
        
        if (value<=0) {
          value = 0;
        }
        
        if (value>=256) {
          value = 256;
        }
        
        String s="{\"EXTINGUISHER\":"+int(value)+"}\r\n";
        c.write(s);
        delay(300);
       
       if (c.available() > 0) { // If there's incoming data from the client...
          String response = c.readString();
          if(response.charAt(0) == '0'){
              extinguisher.setValue(theEvent.getController().getValue());
          }
        }
        else{
            extinguisher.setValue(theEvent.getController().getValue());
        }
      }
      break;
      }
  }
  else if (theEvent.getController().equals(cart)) {
    switch(theEvent.getAction()) {
      case(ControlP5.ACTION_RELEASED): 
      if(c.active()){
        String s="{\"CART\":"+theEvent.getController().getValue()+"}\r\n";
        c.write(s);
        delay(300);
        if (c.available() > 0) { // If there's incoming data from the client...
          String response = c.readString();
          // println("");
          // println("");
          // println("RREEEAAADDDDHHHEEERRREE");
          // println(response);
          // println(response.charAt(0) == '1');
          // println("SSTTTOPPPP RREEEAAADDDDHHHEEERRREE");
          // println("");
          // println("");
          // if(response.charAt(0) == '1'){
            // fridge.setValue(1.0);
          // }
          if(response.charAt(0) == '0'){
            cart.setValue(1.0-theEvent.getController().getValue());
          }
        }
        else{
            cart.setValue(1.0-theEvent.getController().getValue());
        }
      }
      break;
    }
  }
}
// example unique-name function, dunno if you need the public or not
public void Server(int value) {
  //// presumably this takes a boolean
  //state.put(Thing.TIRE, boolean(value));
  
  if(boolean(value) && c.active())return;
  if(boolean(value)) {
    println("connecting!");
    connect();
    boolean deactivate = c.active();
    if(!deactivate)cp5.getController("Server").setValue(parseFloat(int(deactivate)));
  }
  else {
    println("disconnecting?");
    if(c.active())c.stop();
  }   

}


// // example unique-name function, dunno if you need the public or not
// public void Tire(float value) {
//   // presumably this takes a boolean
//   // state.put(Thing.TIRE, byte(value)); 
//      println(value);
//   // if(c.active()){
//     // c.write("TIRE\r\n");
//     // if (c.available() > 0) { // If there's incoming data from the client...
//     //   String response = c.readString();
//     //   if(response == "OK"){
//     //     c.write(value+"\r\n");
//     //     // setLock(cp5.getController("buttonC"),true);
//     //   }
//     //   // println(d);
//     // }
//   // }

//   // if(boolean(value)) {
//   //  println("Tire is On");
//   // }
//   // else {
//   //  println("Tire is Off");
//   // }   

// }

public void Cart(int value) {
  // presumably this takes a boolean
  // state.put(Thing.CART, byte(value));
  
  if(boolean(value)) {
   println("Cart is On");
  }
  else {
   println("Cart is Off");
  }   

}

public void Fridge(int value) {
  // presumably this takes a boolean
  // state.put(Thing.FRIDGE, byte(value));
  
  if(boolean(value)) {
   println("Fridge is On");
  }
  else {
   println("Fridge is Off");
  }   

}

public void TireSwitch(int value) {
  // presumably this takes a boolean
  // state.put(Thing.FRIDGE, byte(value));
  
  if(boolean(value)) {
   println("tire is On");
  }
  else {
   println("tire is Off");
  }   

}

public void ExtinguisherSwitch(int value) {
  // presumably this takes a boolean
  // state.put(Thing.FRIDGE, byte(value));
  
  if(boolean(value)) {
   println("extinguisher is On");
  }
  else {
   println("extinguisher is Off");
  }   

}







int dataIn;
// ClientEvent message is generated when a client disconnects.
void disconnectEvent(Client someClient) {
  int message = someClient.read();
  print("Server Says:  " + message);
  if( (message == -1 || message == 123) && cp5.getController("Server").getValue()>0.0){
    cp5.getController("Server").setValue(0.0);
  }
}