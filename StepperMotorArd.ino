#include <Wire.h>
#include <Adafruit_MotorShield.h>
#include <Adafruit_PWMServoDriver.h>
#include <Stepper.h>

const int stepsPerRevolution = 200;
const int RPM = 6; // 6 rpm = 2 mm/s, 50 rpm = 1 mm/s

Adafruit_MotorShield AFMS = Adafruit_MotorShield();
Adafruit_StepperMotor *myMotor = AFMS.getStepper(200, 2);

int stepCount = 0;  // Number of steps the motor has taken
int stepTarget = 200; // Number of steps to be reach by motor (100 steps = 1 mm)

char val;
boolean runMotor = false;
boolean jogMotor = false;
int sensorValue;
int stepsPerLoop = 4;

unsigned int startMillis;
unsigned int endMillis;
unsigned int timeSpent;

unsigned int startMillisLoop;
unsigned int timeSpentLoop;
unsigned int currentMillisLoop;

void setup() {
  Serial.begin(9600); // Set baud rate
  Serial.println("Stepper Test");
  
  AFMS.begin();
  myMotor->setSpeed(RPM);

  /*
  startMillis = millis();
  myMotor->step(stepTarget, BACKWARD, SINGLE);
  endMillis = millis();
  timeSpent = endMillis - startMillis;
  Serial.print("Single Command Time: ");
  Serial.println(timeSpent);
  */

  delay(100);
}

void loop() {

  
  //while (Serial.available() == 0); // If no data is coming in, nothing happens beyond this line
  if (Serial.available() > 0) {
    val = Serial.read(); // Continuously reading load cell value
  }
  
  // If the character '1' is sent into the command window, the program will run
  if (val == '1') { 
    runMotor = true;
  } else if (val == '2') {
    jogMotor = true;
  } else {
    runMotor = false;
    jogMotor = false;
  }

  if (jogMotor) {
    myMotor->step(800, FORWARD, SINGLE);
  }
  
  while (runMotor) {
    
      if (stepCount < (stepTarget / stepsPerLoop)) {
        
        if (stepCount == 0) startMillisLoop = millis(); // Record initial time in milliseconds
        currentMillisLoop = millis() - startMillisLoop; // Record current time in milliseconds based off start of the loop
        sensorValue = analogRead(A0);
        Serial.print(sensorValue);
        Serial.print(",");
        Serial.println(currentMillisLoop);
        myMotor->step(stepsPerLoop, BACKWARD, SINGLE); // Moving motor by 4 steps (direction can be changed to FORWARD to jog motor opposite direction)
        stepCount++;
        
        // Record final time in milliseconds
        if (stepCount == (stepTarget / stepsPerLoop)) {
          runMotor = false;
          stepCount = 0;
          timeSpentLoop = millis() - startMillisLoop;
          Serial.print("Loop Time: ");
          Serial.println(timeSpentLoop);
        }
      }
  }

  
}



