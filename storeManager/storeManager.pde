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
Toggle camera;
Toggle heart;

PrintWriter output;

int col = color(255);
boolean isConnected = false;

color okBgColor;
color disabledBgColor = color(0, 100, 0);

int Extinguisher = 0;

Client c;

//void draw() {
//  if (c.available() > 0) { // If there's incoming data from the client...
//    data = c.readString(); // ...then grab it and print it
//    println(data);
//  }
//}

enum Thing
{
  TIRE, CART, FRIDGE, EXTINGUISHER, CAMERA, HEART;
}



// https://docs.oracle.com/javase/6/docs/api/java/util/EnumMap.html
EnumMap<Thing, Byte> state = new EnumMap<Thing, Byte>(Thing.class);

void connect(){
  try{
    c = new Client(this, "127.0.0.1", 11999); // Connect to server on port 80
    //isConnected = true;
    //c.write("poop\r\n"); // Use the HTTP "GET" command to ask for a Web page
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
  state.put(Thing.CAMERA, byte(0));
  state.put(Thing.HEART, byte(0));

}


void createUI(){
  cp5 = new ControlP5(this);
  
  server = cp5.addToggle("Server");
   server.setPosition(380,80)
   .setSize(50,20)
   .setValue(c.active());

  tireSwitch = cp5.addToggle("TireSwitch");
   tireSwitch.setPosition(190,80)
   .setSize(100,40);
     

  tire = cp5.addSlider("Tire");
   tire.setPosition(190,160)
   .setSize(100,40)
   .setRange(0, 100);
     
  cart = cp5.addToggle("Cart");
   cart.setPosition(380,160)
   .setSize(100,40)
     ;
     
  fridge = cp5.addToggle("Fridge");
   fridge.setPosition(570,160)
   .setSize(100,40)
     ;
     
  extinguisher = cp5.addSlider("Extinguisher");
   extinguisher.setPosition(190,320)
   .setSize(100,40)
  .setRange(-10, 300)
     ;
     
  camera = cp5.addToggle("Camera");
   camera.setPosition(380,320)
   .setSize(100,40)
     ;
     
  heart = cp5.addToggle("Heart");
   heart.setPosition(570,320)
   .setSize(100,40)
     ;
     
  okBgColor = color(cp5.getController("Heart").getColor().getBackground());
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
          setLock(controllerName,alive);
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


void setup() {
  size(760,480);
  smooth();
  

  connect();
  initializeState();
  createUI();
  updateUI();

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
    case("CAMERA"):setLock(camera, theValue);break;
    case("HEART"):setLock(heart, theValue);break;
  }

}

  
  // Create a new file in the sketch directory
  // output = createWriter("positions.txt"); 
  int switchOn = 0;

int time = millis();


void draw() {
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
  if (theEvent.getController().equals(fridge)) {
    switch(theEvent.getAction()) {
      case(ControlP5.ACTION_RELEASED): 
      if(c.active()){
        String s="{\"FRIDGE\":"+theEvent.getController().getValue()+"}\r\n";
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
        // delay(200);
        // if (c.available() > 0) { // If there's incoming data from the client...
        //   String response = c.readString();
        //   // println(response);
        //   // println(response == "OK\r");
        // }
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

// public void Extinguisher(int value) {
//   // presumably this takes a boolean
//   // state.put(Thing.EXTINGUISHER, byte(value));
  
//   if(boolean(value)) {
//    println("Extinguisher is On");
//   }
//   else {
//    println("Extinguisher is Off");
//   }   

//}

public void Camera(int value) {
  // presumably this takes a boolean
  // state.put(Thing.CAMERA, byte(value));
  
  if(boolean(value)) {
   println("Camera is On");
  }
  else {
   println("Camera is Off");
  }   

}

public void Heart(int value) {
  // presumably this takes a boolean
  // state.put(Thing.HEART, byte(value));
  
  if(boolean(value)) {
   println("Heart is On");
  }
  else {
   println("Heart is Off");
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