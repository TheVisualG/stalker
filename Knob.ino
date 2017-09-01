
#include <Servo.h>

Servo servoY;  // create servo object to control a servo
Servo servoX;

int ValX;
int ValY;

byte Processing;

int val;    // variable to read the value from the analog pin

void setup() {
  ValY = 0;
  ValX = 0;
  Serial.begin(9600);
  servoX.attach(7);  // attaches the servo on pin 9 to the servo object
  servoY.attach(8);
}

void loop() {

  if (Serial.available() > 0) {
    Processing = Serial.read();
  }

  if (Processing == 'a') {
    ValY--;
    servoY.write(ValY);
  }
  if (Processing == 'b') {
    ValY++;
    servoY.write(ValY);
  }
 
  if (Processing == 'c') {
    ValX--;
    servoX.write(ValX);
  }
  if (Processing == 'd') {
    ValX++;
    servoX.write(ValX);
  }
  if (Processing == 'e') {

  }

if (ValX >= 210){
  ValX = 210;
}
if (ValX <= 0){
  ValX = 0;
  
}
if (ValY >= 210){
  ValY = 210;
}
if (ValY <= 0){
  ValY = 0;
}

  
  // sets the servo position according to the scaled value

}

