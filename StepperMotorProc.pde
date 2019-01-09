import processing.serial.*;

Serial port;
color c;
int c1 = color(255, 0, 0);
int c2 = color(0, 255, 0);
int c3 = color(0, 0, 255);
int count = 0;
int colorCount = 0;
int dataCount = 0;
int switchInterval = 5;
String input;
boolean runMotor = false;
boolean jogMotor = false;

String day = String.valueOf(day());
String month = String.valueOf(month());
String year = String.valueOf(year());
String hour = String.valueOf(hour());
String minute = String.valueOf(minute());

String fileName = "data/Probe_Inserter_" + month + "-" + day + "-" + year + "_" + hour + "-" + minute + ".csv";

Table table;

void setup() {
  
  size(300, 200);
  
  String portName = Serial.list()[0];
  port = new Serial(this, portName, 9600);
  
  port.bufferUntil('\n');
  
  table = new Table();
  table.addColumn("Count");
  table.addColumn("Load");
  table.addColumn("Time");
  
}

void draw() {
  
  if (colorCount < switchInterval) {
    c = c1;
  } else if (colorCount < switchInterval * 2) {
    c = c2;
  } else if (colorCount < switchInterval * 3) {
    c = c3;
  } else {
    colorCount = 0;
  }
  colorCount++;
  background(c);
  
  if (runMotor) {
    port.write('1');
    print(" RUN ");
    runMotor = false;
  } else if (jogMotor) {
    port.write('2');
    print(" JOG ");
    jogMotor = false;
  } else {
    port.write('0'); 
  }
  
  count++;
  
}

void mousePressed () {
 
  if (mouseButton == LEFT) {
    runMotor = true;
  }
  
  if (mouseButton == RIGHT) {
    jogMotor = true;
  }
  
}

void serialEvent (Serial port) {
  
  dataCount++;
  
  input = port.readStringUntil('\n');
  println(input);
  String[] stringData = input.split(",");
  
  table.addRow();
  table.setInt(dataCount, "Count", dataCount);
  table.setString(dataCount, "Load", stringData[0]);
  table.setString(dataCount, "Time", stringData[1]);
  
}
