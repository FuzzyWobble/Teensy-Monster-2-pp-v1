//DIY Controller 
//fuzzywobble.com

//libraries
//#include <../encoderLib/Encoder.h> //Paul's encoder library
#include <Encoder.h>

// EDIT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 

//DEBUG 
//enable if you want to test your output in the serial monitor
boolean enableDebug = 1;  // 1 for enable, 0 for disable. **Remember to disable debug when running MIDI**. 

//CHANNEL
int channelNumber = 1; //each controller should have a unique channel number between 1 and 125 (126 & 127 are used by the encoders).

//SHIFT
//shift buttons offer dual functionality to your pushbuttons and encoders
int shiftPin = 0; //if using a shift button enter the pin number here, else put 0

//PUSHBUTTON 
//enter '1' for a pin which a pushbutton is connected 
//enter '0' for a pin which a pushbutton is not connected 
//pins with '8' are those which are encoders and should not be used as pushbuttons unless necessary
//pins with '9' are use for other purposes and can not be used as pushbuttons 
//do NOT include the SHIFT button here
//24 pusbuttons + 2 for each encoder not used
int toReadPushButton[38] = 
{           //Pin number are written below
8,8,8,8,0,  //0-4
0,9,0,0,0,  //5-9
0,0,0,0,0,  //10-14
0,0,9,8,8,  //15-19
9,9,9,9,0,  //20-24
0,0,0,0,0,  //25-29
0,0,1,1,0,  //30-34
0,8,8       //35-37
}; 
//pushbutton mode
//there are a few different modes in which you may wish for your pushbutton to behave
//'1' - standard mode - when pushbutton is engaged note is turned on, when pushbutton is released, note is turned off
//'2' - on mode - note is only turned on with each click
//'3' - off mode - note is only turned off with each click
//'4' - toggle mode - note is switched between on and off with each click
//pins with '9' are those which are encoders and should not be used as pushbuttons unless necessary
int pushbuttonMode[76] = 
{           //Pin number are written below
9,9,9,9,1,  //0-4
1,9,1,1,1,  //5-9
1,1,1,1,1,  //10-14
1,1,1,9,9,  //15-19
1,1,1,1,1,  //20-24
1,1,1,1,1,  //25-29
1,1,4,4,1,  //30-34
1,9,9,      //35-37
            //When shift button is held, the following pushbuttons are enabled
9,9,9,9,0,  //38-42 SHIFT
1,9,1,1,1,  //43-47 SHIFT
1,1,1,1,1,  //48-52 SHIFT
1,1,1,9,9,  //53-57 SHIFT
1,1,1,1,1,  //58-62 SHIFT
1,1,1,1,1,  //63-67 SHIFT
1,1,1,1,1,  //68-72 SHIFT
1,9,9       //73-75 SHIFT
}; 

//DEBOUNCE
//debounce is a measurement of the time in which a pushbutton is unresponsive after it is pressed
//this is important to prevent unwanted double clicks 
int pbBounce = 150; //150 millisecond debounce duration - you may want to change this value depending on the mechanics of your pushbuttons

//LEDs
//'1' for pins which have LEDs hooked up to them, else '0'
//pins with '8' are those which are encoders and should not be used as LEDs unless necessary
//pins with '9' are use for other purposes and can not be used as LEDs
//you cannot hook LEDs and pushbuttons up to the same pins
//note that pins 14,15,16,24,25,26 have PWM ability - this enables you to adjust the brightness of the LED
int toDisplayLED[] = 
{           //Pin number are written below
8,8,8,8,0,  //0-4
0,9,0,0,0,  //5-9
0,0,0,0,0,  //10-14
0,0,9,8,8,  //15-19
9,9,9,9,0,  //20-24
0,0,0,0,0,  //25-29
0,0,0,0,0,  //30-34
0,8,8       //35-37
}; 

//ROTARY ENCODER
//encoders require two digital pins
//encoders can be read in two modes: best performance, good performance 
//for best performance, two digital iterrupt pins are required
//for good performance, one digitial interrupt pin and one regular digital pin are required
//you can read three encoders in the best perfomance mode
//you can read six encoders in the good performance mode
//interrupt pins are 0,1,2,3,18,19
//{0,5} - example of good performance read (0 is an interrupt pin, and 5 is a regular digital pin)
//note that interrupt pin MUST come first - {5,0} would not work
//{18,19} - example of best performance read (both 18 and 19 are digital interrupt pins)
//enter the pin number if in use, else '99'
int encoderPins[6][2] = {
{0,34}, //encoder 1 
{2,35}, //encoder 2
{99,99}, //encoder 3
{99,99}, //encoder 4
{99,99}, //encoder 5
{99,99} //encoder 6
}; 

//ANALOG IN 
//there are two ways to do analog inputs - the multiplexer or direct Teensy
//(Muntiplexer)
//CD4067BE - http://www.ti.com/lit/ds/symlink/cd4067b.pdf
//analog inputs require three pins: power, ground, and input
//'1' for multiplexer analog inputs you want to read, else enter '0'
int toReadAnalogMux[16] = { //IC pin number are written below 
0,0,0,0, //0-3 
0,0,0,0, //4-7
0,0,0,0, //8-11
0,0,0,0  //12-15
}; 
//(Teensy)
//directly from Teensy analog pins
//analog inputs require three pins: power, ground, and input
//enter '1' for analog inputs you want to read, else enter '0'
int toReadAnalogTeensy[6] = {
0,0,0, //39,40,41
1,1,1 //42,43,44
}; 





// VARIABLES AND FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 

//PUSHBUTTONS
long timeHit[76]; //38*2 = 76 (shift button)
boolean buttonState[76]; //stored state: if the button was last turned on or off
int shiftChange;

//ENCODER
//int encoderIntPins[3][2] = {{0,1},{2,3},{18,19}}; //encoder pin numbers
Encoder *encoders[6];
boolean toReadEncoder[6];
long encPosition[6];
long tempEncPosition;

//ANALOG IN
int s0 = 20; //control pin A
int s1 = 21; //control pin B
int s2 = 22; //control pin C
int s3 = 23; //control pin D
int SIG_pin = 38; //analog read pin 
int analogInsPrev[16]; //array to hold previously read analog values - set all to zero for now
int tempAnalogIn = 0; //array to hold previously read analog values 
int tempAnalogInMap = 0;
int analogThreshold = 3; //threshold
int controlPin[] = {s0,s1,s2,s3}; //set contol pins in array
//control array 
int muxChannel[16][4]={ 
{0,0,0,0},{1,0,0,0},{0,1,0,0},{1,1,0,0},{0,0,1,0},{1,0,1,0},{0,1,1,0},{1,1,1,0},{0,0,0,1},{1,0,0,1},{0,1,0,1},{1,1,0,1},{0,0,1,1},{1,0,1,1},{0,1,1,1},{1,1,1,1}  
};
//function to read mux
int readMux(int channel){  
  //loop through the four control pins
  for(int i = 0; i < 4; i ++){ 
    //turn on/off the appropriate control pins according to what channel we are trying to read 
    digitalWrite(controlPin[i], muxChannel[channel][i]); 
  }
  //read the value of the pin
  int val = analogRead(SIG_pin); 
  //return the value
  return val; 
}
int analogPinsTeensy[6] = {39,40,41,42,43,44};
int analogInsPrevTeensy[6]; //array to hold previously read analog values 
int tempAnalogInTeensy = 0; 
int tempAnalogInMapTeensy = 0;
int analogThresholdTeensy = 3; //threshold - hmm we need to reduce the noise somehow








// SETUP ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
void setup(){ 

  
  //DEBUG
  if(enableDebug){
    Serial.begin(9600);//open serail port @ debug speed
    Serial.flush();
    Serial.println();
    Serial.println("~~~~~~~~~~ Pin Config ~~~~~~~~~~");
  }
  else{
    Serial.begin(31250);//open serail port @ midi speed
  }
  
   //SHIFT - pin config
  //we need enable the shift pin as an INPUT as well as turn on the pullup resistor 
  if(shiftPin!=0){
    pinMode(shiftPin,INPUT_PULLUP); //shift button
    if(enableDebug){  
      Serial.println("SHIFT button is enabled on pin ["+(String)shiftPin+"]"); 
    }
  }
  
  //PUSHBUTTON - pin config
  //we need enable each pushbutton pin as an INPUT as well as turn on the pullup resistor 
  for(int i=0;i<38;i++){
    if(toReadPushButton[i]==1){
      pinMode(i,INPUT_PULLUP); //pushbutton pullup
      if(enableDebug){
        Serial.println("Pushbutton on pin ["+(String)i+"] is enabled with pushbutton mode ["+(String)pushbuttonMode[i]+"]");  
      }
    }  

  }
  
  //LED - pin config
  //we need enable each LED pin as an OUTPUT
  for(int i=0;i<38;i++){
    if(toDisplayLED[i]==1){
      pinMode(i,OUTPUT); //pushbutton pullup
      if(enableDebug){
        Serial.println("LED on pin ["+(String)i+"] is enabled"); 
      }
    }  

  }   


  //ENCODER - pin config
  for(int i=0;i<6;i++){
    if(encoderPins[i][0]!=99 && encoderPins[i][1]!=99){
      encoders[i] = new Encoder(encoderPins[i][0],encoderPins[i][1]);
      toReadEncoder[i] = 1;
      if(enableDebug){
        Serial.println("Encoder on pins ["+(String)encoderPins[i][0]+","+(String)encoderPins[i][1]+"] is enabled"); 
      }
    }
    else{
      toReadEncoder[i] = 0;  
    }
  }
  
  //ANALOG IN - pin config
  for(int i=0;i<16;i++){
    if(toReadAnalogMux[i]==1 && enableDebug==1){
      Serial.println("Analog in on multiplexer pin ["+(String)i+"] is enabled");   
    }
  }
  for(int i=0;i<6;i++){
    if(toReadAnalogTeensy[i]==1 && enableDebug){
      int p = i+39;
      Serial.println("Analog in on teensy pin ["+(String)p+"] is enabled");   
    }
  }
  //set analog in reading
  pinMode(SIG_pin,INPUT);
  //pinMode(INH_pin,OUTPUT);
  //digitalWrite(INH_pin,LOW);
  //set our control pins to output
  pinMode(s0,OUTPUT);
  pinMode(s1,OUTPUT);
  pinMode(s2,OUTPUT);
  pinMode(s3,OUTPUT); 
  //turn all control pins off (for now)
  digitalWrite(s0,LOW);
  digitalWrite(s1,LOW);
  digitalWrite(s2,LOW);
  digitalWrite(s3,LOW);
  
    //DEBUG
  if(enableDebug){
    Serial.println("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
  }
}




// LOOPS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
void loop(){
  
  //SHIFT loop
  if(shiftPin!=0){
    if(digitalRead(shiftPin)==LOW){ //check if shift button was engaged
      shiftChange = 38;  //if enganged, the offset is 38
    }
    else{
      shiftChange = 0;  
    }
  }
  
  //PUSHBUTTONS loop
  boolean tempDigitalRead;
  for(int i=0;i<38;i++){ //loop through all 38 digital pins
  int j = i + shiftChange; //add the shift change
    if(toReadPushButton[i]==1){ //check if this a pin with a pushbutton hooked up to it
      tempDigitalRead = digitalRead(i);
      //NORMAL MODE (1)
      if(pushbuttonMode[j]==1 && tempDigitalRead!=buttonState[j]){ 
        delay(2); //just a delay for noise to ensure push button was actually hit
        if(digitalRead(i)==tempDigitalRead){ //check if pushbutton is still the same
          if(tempDigitalRead==LOW){ //button pressed, turn note on
            midiNoteOnOff('p',1,j); //call note on/off function
          }
          else{ //button released
            midiNoteOnOff('p',0,j);
          }
          buttonState[j] = tempDigitalRead; //update the state (on or off)           
        }
      }
      //ALL OTHER MODES (2,3,4)
      else{ 
        if(digitalRead(i)==LOW && (millis()-timeHit[j])>pbBounce){ //check bounce time  
          if(pushbuttonMode[j]==2){ //mode 2 - only note on
            midiNoteOnOff('p',1,j); 
          }
          else if(pushbuttonMode[j]==3){ //mode 3 - only note off
            midiNoteOnOff('p',0,j);          
          }
          else{ //mode 4 - toggle
            if(buttonState[j]==1){
              midiNoteOnOff('p',0,j);
              buttonState[j]=0;  
            }
            else{
              midiNoteOnOff('p',1,j);
              buttonState[j]=1;  
            }
          }
          timeHit[j] = millis();
        }
      }   
    }
  }
  
  //ENCODER loop
  for(int i=0;i<6;i++){
    if(toReadEncoder[i]==1){
      long tempEncPosition = encoders[i]->read();
      if(tempEncPosition > encPosition[i]){
        midiNoteOnOff('e',1,i);
        encPosition[i] = tempEncPosition;
      }
      if(tempEncPosition < encPosition[i]){
        midiNoteOnOff('e',0,i); 
        encPosition[i] = tempEncPosition; 
      }
    }
  } 
 
  //ANALOG IN MUX loop
  for(int i=0;i<16;i++){ //loop through 16 mux channels
    if(toReadAnalogMux[i]==1){ //check if this a pin with a analog input hooked up to it
      tempAnalogIn = readMux(i); //ready valued using readMux function
      if(abs(analogInsPrev[i]-tempAnalogIn)>analogThreshold){ //ensure value changed more than our threshold
        tempAnalogInMap = map(tempAnalogIn,0,1023,0,127); //remap value between 0 and 127
        midiNoteOnOff('a',tempAnalogInMap,i);
        analogInsPrev[i]=tempAnalogIn; //reset current value
      }
    }    
  } 
  
  //ANALOG IN TEENSY loop  
  for(int i=0;i<6;i++){ //loop through the 6 analog teensy channels
    if(toReadAnalogTeensy[i]==1){ //read if plugged in
      tempAnalogInTeensy = analogRead(analogPinsTeensy[i]);
      if(abs(analogInsPrevTeensy[i]-tempAnalogInTeensy)>analogThresholdTeensy){
        tempAnalogInMapTeensy = map(tempAnalogInTeensy,0,1023,0,127);
        midiNoteOnOff('a',tempAnalogInMapTeensy,i+16);
        analogInsPrevTeensy[i]=tempAnalogInTeensy; 
      }
    }    
  }
    
  //LED loop

}







// COMMUNICATION FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //

//debug out
void serialDebugOut(String cType, int cNum, String cVal){
  Serial.print(cType);
  Serial.print(" ");
  Serial.print(cNum);
  Serial.print(": ");
  Serial.println(cVal);    
}

//function to send note on/off
//this helps to keep the code concise 
void midiNoteOnOff(char type, int val, int pin){
  String clickState;
  switch (type){
  case 'p': //--------------- pusbutton   
    if(enableDebug){
      if(val==1){
        clickState = "click on";  
      }
      else{
        clickState = "click off";  
      }
      serialDebugOut("Pushbutton",pin,clickState);  
    }
    else{
      if(val==1){
        //usbMIDI.sendNoteOn(pin,127,channelNumber);
      }
      else{
        //usbMIDI.sendNoteOff(pin,127,channelNumber);
      }
    }
    break;
  case 'e': //--------------- encoder
    if(enableDebug){
      if(val==1){
        clickState = "forward";  
      }
      else{
        clickState = "reverse";  
      }
      serialDebugOut("Encoder",pin,clickState);  
    }
    else{
      if(val==1){
        //usbMIDI.sendNoteOn(pin+46,127,channelNumber);
      }
      else{
        //usbMIDI.sendNoteOff(pin+46,127,channelNumber);
      }
    }
    break;
  case 'a': //--------------- analog   
    if(enableDebug){
      if(pin>15){
        serialDebugOut("Analog Teensy",pin,val);   
      }
      else{
        serialDebugOut("Analog mux",pin,val);  
      }
    }
    else{
      //usbMIDI.sendControlChange(pin,val,channelNumber);
    }
    break;
  }
}

