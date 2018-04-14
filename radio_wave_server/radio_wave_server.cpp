/** RF24Mesh_Example_Master.ino by TMRh20
* 
* Note: This sketch only functions on -Arduino Due-
*
* This example sketch shows how to manually configure a node via RF24Mesh as a master node, which
* will receive all data from sensor nodes.
*
* The nodes can change physical or logical position in the network, and reconnect through different
* routing nodes as required. The master node manages the address assignments for the individual nodes
* in a manner similar to DHCP.
*
*/
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <iostream>

#include "TCPServer.h"

#include "RF24Mesh/RF24Mesh.h"  
#include <RF24/RF24.h>
#include <RF24Network/RF24Network.h>

#include "nlohmann/json.hpp"
#include "TCPServer.h"
#include <mutex>

using json = nlohmann::json;
std::mutex myMutex;

json j;

unsigned int NAPPLIANCES = 5;
static const char* Appliances[] = { "TIRE", "CART", "FRIDGE", "EXTINGUISHER", "CAMERA", "HEART" };
std::array<unsigned long, 6> lastUpdated{ 0, 0, 0, 0, 0, 0};

const unsigned int BrainsLuts[6] = {11,22,33,44,55,66};
enum Brains
{
  TIRE = 11,
  CART = 22,
  FRIDGE = 33,
  EXTINGUISHER = 44,
  CAMERA = 55,
  HEART = 66,
};

int indexFromAddress(unsigned int address){
  for (int i = 0; i < NAPPLIANCES; ++i)
  {
    if (address == BrainsLuts[i])return i;
  }
  return -1;
}
void isAlive(unsigned int address, unsigned long time){
  int index = indexFromAddress(address);
  if (index != -1)lastUpdated[index] = time;
}
void setAlivialitility(std::string target, bool alive){
    std::lock_guard<std::mutex> guard(myMutex);
    j[target]["alive"] = alive;
}

void setValue(std::string target, float value){
    std::lock_guard<std::mutex> guard(myMutex);
    j[target]["value"] = value;
}

bool updateValue(std::string target, float &val){
  std::lock_guard<std::mutex> guard(myMutex);
  for (json::iterator it = j[target].begin(); it != j[target].end(); ++it) {
      if(it.key() == "value"){
          val = it.value();
          j[target]["lastValue"] = it.value();
          j[target].erase("value");
          return true;
      }
  }
  return false;
}

std::string getData(){
    std::lock_guard<std::mutex> guard(myMutex);
    return j.dump();
}


RF24 radio(RPI_V2_GPIO_P1_15, BCM2835_SPI_CS0, BCM2835_SPI_SPEED_8MHZ);  
RF24Network network(radio);
RF24Mesh mesh(radio,network);

unsigned long packets_sent;          // How many have we sent already

unsigned int addressFromName(std::string name){
  unsigned int address = 0;
  if (name == "TIRE") {
    address = Brains::TIRE;
  }
  else if(name == "CART"){
    address = Brains::CART;
  }
  else if(name == "FRIDGE"){
    address = Brains::FRIDGE;
  }
  else if(name == "EXTINGUISHER"){
    address = Brains::EXTINGUISHER;
  }
  else if(name == "CAMERA"){
    address = Brains::CAMERA;
  }
  else if(name == "HEART"){
    address = Brains::HEART;
  }
  return address;
}


struct payload_t {                  // Structure of our payload
  unsigned long value;
};

uint32_t displayTimer = 0;
TCPServer tcp;
void *srerver(void *  argument)
{
  pthread_detach(pthread_self());
  while(1)
  {
      srand(time(NULL));
      char ch = 'a' + rand() % 26;
      string s(1,ch);
      string str = tcp.getMessage();
      if( str == "QUERY\r\n" )
      {
          for (int i = 0; i < NAPPLIANCES; ++i)
          {
            if(millis() - lastUpdated[i] > 3000){
              setAlivialitility(Appliances[i], false);
            }
            else{
              setAlivialitility(Appliances[i], true);
            }
          }
          tcp.Send(getData());
          tcp.clean();
      }
      else if( str != "" )
      {
          try {
              std::cout << str << std::endl;
              json r = json::parse(str);
              std::cout << r.dump(4) << std::endl;

              for (json::iterator it = r.begin(); it != r.end(); ++it) {
                  float val = it.value();
                  std::string name = it.key();
                  setValue(name, val);
                  updateValue(name, val);
                  payload_t payload = {val};
                  int address = addressFromName(name);
                  printf("address %i\n", address);
                  printf("mesh address %i\n", mesh.getAddress(address));
                  RF24NetworkHeader header(mesh.getAddress(address));
                  if (!network.write(header, &payload, sizeof(payload))) {
                    printf("Message failed :_(\n");
                    std::string failed = "0\n";
                    tcp.Send(failed);
                    // tcp.clean();
                  } else {
                    std::string success = "1\n";
                    printf("Message OK :)\n");
                    tcp.Send(success);
                    // tcp.clean();
                  }
              }
          } catch (const std::exception& e) {
              std::cout << e.what() << std::endl;
          }
          tcp.clean();
      }
      usleep(1000);
  }
  tcp.detach();
}

void * radiowaves(void * argument) {
  
  // Set the nodeID to 0 for the master node
  mesh.setNodeID(0);
  mesh.begin();
  printf("Starting radiowaves\n");
  radio.printDetails();

  while(1)
  {
    // Call network.update as usual to keep the network updated
    mesh.update();

    // In addition, keep the 'DHCP service' running on the master node so addresses will
    // be assigned to the sensor nodes
    mesh.DHCP();
    
    // Check for incoming data from the sensors
    if (network.available()) {
      RF24NetworkHeader header;
      network.peek(header);
      printf("Got ");
      uint32_t dat = 0;
      switch (header.type) {
        // Display the incoming millis() values from the sensor nodes
        case 'M':
          network.read(header, &dat, sizeof(dat));
          isAlive(mesh.getNodeID(header.from_node), millis());
          
          printf("%u", dat);
          printf(" from RF24Network address 0 ");
          printf("%u\n", header.from_node);
          break;
        default:
          network.read(header, 0, 0);
          printf("%u\n", header.type);
          break;
      }
    }
    
    if(millis() - displayTimer > 5000){
      displayTimer = millis();
      printf(" \n");
      printf("********Assigned Addresses********\n");
       for(int i=0; i<mesh.addrListTop; i++){
         printf("NodeID: %u  RF24Network Address: 0 %u\n", mesh.addrList[i].nodeID, mesh.addrList[i].address);
       }
      printf("**********************************\n");
    }
  }
}

int main(){
    j["TIRE"] = { {"alive", false}, {"lastValue", 0.0} };
    j["CART"] = { {"alive", false}, {"lastValue", 0.0} };
    j["FRIDGE"] = { {"alive", false}, {"lastValue", 0.0} };
    j["EXTINGUISHER"] = { {"alive", false}, {"lastValue", 0.0} };
    j["CAMERA"] = { {"alive", false}, {"lastValue", 0.0} };
    j["HEART"] = { {"alive", false}, {"lastValue", 0.0} };

    pthread_t thread1, thread2;
    bool radios_ok = pthread_create( &thread1, NULL, radiowaves, (void *) "radios") == 0;
    bool srerver_ok = pthread_create(&thread2, NULL, srerver, (void *)0) == 0;
    tcp.setup(11999);
    if( radios_ok && srerver_ok)
    {
      tcp.receive();
      pthread_join(thread1,NULL);
    }
    return 0;

}
      
      
      
