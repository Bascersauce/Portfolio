import g4p_controls.*;

import org.gicentre.utils.*;
import org.gicentre.utils.network.*;
import org.gicentre.utils.network.traer.physics.*;
import org.gicentre.utils.geom.*;
import org.gicentre.utils.move.*;
import org.gicentre.utils.stat.*;
import org.gicentre.utils.gui.*;
import org.gicentre.utils.colour.*;
import org.gicentre.utils.text.*;
import org.gicentre.utils.*;
import org.gicentre.utils.network.traer.animation.*;
import org.gicentre.utils.io.*;

import processing.serial.*;


final float TRAVEL_DISTANCE = 2.00; // (mm)
final float BREAK_DISTANCE = 6.00; // (mm)

final float PROBE_THICKNESS = 0.05;
final float PROBE_WIDTH = 0.1;
final float PROBE_LENGTH = 2.00;
final float PROBE_CROSS_SECTIONAL_AREA = PROBE_THICKNESS * PROBE_WIDTH;



Serial PMD401;
Serial DPM3;
Serial DP41;

Table table;
XYChart lineChart;
XYChart lineChartLinear;
XYChart stressStrain;

String[] myPorts;
String motorResponse;
String loadCellData;
String linearData;

int count = 0;
int currentCount = 0;
int dataCount = 0;
int timeInit;
int time;
float data;
float dataLinear;
float initLinearPosition;


ArrayList<Float> loadDataGraph = new ArrayList<Float>();
ArrayList<Float> linearDataGraph = new ArrayList<Float>();

int portValue = 0;


String day = String.valueOf(day());
String month = String.valueOf(month());
String year = String.valueOf(year());
String hour = String.valueOf(hour());
String minute = String.valueOf(minute());

String fileName = "data/Tensile_Tester_" + month + "-" + day + "-" + year + "_" + hour + "-" + minute + ".csv";

boolean runMotor1 = false;
boolean runMotor2 = true;
boolean testSwitch = false;
int sawDistance = 50;
float tolerance = 0.5;


GTextField textfield1;
GTextField textfield2;
GLabel label1;


// Commands for Motor
byte[] startTarget = { byte(0x58), byte(0x54), byte(0x30), byte(0x0D) }; //XT0
byte[] identString = { byte(0x58), byte(0x30), byte(0x3F), byte(0x0D) }; //X0?
byte[] moveLeft = { byte(0x58), byte(0x4A), byte(0x2D), byte(0x32),
                    byte(0x30), byte(0x2C), byte(0x30), byte(0x2C),
                    byte(0x31), byte(0x30), byte(0x30), byte(0x0D) }; //XJ-20,0,100
byte[] moveRight = { byte(0x58), byte(0x4A), byte(0x32), byte(0x30),
                    byte(0x2C), byte(0x30), byte(0x2C), byte(0x31),
                    byte(0x30), byte(0x30), byte(0x0D) }; //XJ20,0,100
                    
byte[] moveLeftSlow = { byte(0x58), byte(0x4A), byte(0x2D), byte(0x32),
                        byte(0x2C), byte(0x30), byte(0x2C),
                        byte(0x31), byte(0x30), byte(0x0D) }; //XJ-2,0,10
byte[] moveRightSlow = { byte(0x58), byte(0x4A), byte(0x32),
                         byte(0x2C), byte(0x30), byte(0x2C), byte(0x31),
                         byte(0x30), byte(0x0D) }; //XJ2,0,10
                    
                    
byte[] moveLeftLong = { byte(0x58), byte(0x4A), byte(0x2D), byte(0x38),
                    byte(0x30), byte(0x2C), byte(0x30), byte(0x2C),
                    byte(0x31), byte(0x30), byte(0x30), byte(0x0D) }; //XJ-80,0,100
byte[] moveRightLong = { byte(0x58), byte(0x4A), byte(0x38), byte(0x30),
                    byte(0x2C), byte(0x30), byte(0x2C), byte(0x31),
                    byte(0x30), byte(0x30), byte(0x0D) }; //XJ80,0,100
                    
byte[] stop = { byte(0x58), byte(0x53), byte(0x0D) }; //XS


//Commands for Load Cell Display
byte[] continuousMode = { byte(0x2A), byte(0x31), byte(0x41), byte(0x30), byte(0x0D) };
byte[] commandMode = { byte(0x2A), byte(0x31), byte(0x41), byte(0x31), byte(0x0D) };
byte[] getReading = { byte(0x2A), byte(0x31), byte(0x42), byte(0x31), byte(0x0D) };


//Linear Transducer Display
byte[] commandModeLinear = { byte(0x2A), byte(0x57), byte(0x31), byte(0x43),
                                byte(0x31), byte(0x34), byte(0x0D) }; // *W1C14
byte[] continuousModeLinear = { byte(0x2A), byte(0x57), byte(0x31), byte(0x43),
                                byte(0x30), byte(0x34), byte(0x0D) }; // *W1C06
byte[] dataFormat = { byte(0x2A), byte(0x57), byte(0x31), byte(0x42),
                                byte(0x30), byte(0x30), byte(0x0D) }; // *W1B08
byte[] getData = { byte(0x2A), byte(0x56), byte(0x30), byte(0x31), byte(0x0D) };


void setup () {
 
  size(900, 900);
  
  
  lineChart = new XYChart(this);
  lineChartLinear = new XYChart(this);
  stressStrain = new XYChart(this);
  
  
  PMD401 = new Serial(this, Serial.list()[0], 115200);
  DPM3 = new Serial(this, Serial.list()[1], 19200);
  DP41 = new Serial(this, Serial.list()[2], 19200, 'N', 7, 2.0);
  
  
  myPorts = Serial.list();
  printArray(myPorts);
  
  PMD401.clear();
  DPM3.clear();
  DP41.clear();
  
  PMD401.write(identString);
  DPM3.write(commandMode);
  DP41.write(commandModeLinear);
  DP41.write(dataFormat);
  
  
  timeInit = millis();
  
  table = new Table();
  table.addColumn("Count");
  table.addColumn("Time");
  table.addColumn("Load Data");
  table.addColumn("Linear Data");
  
  
  //Load Cell Graph
  lineChart.showXAxis(true); 
  lineChart.showYAxis(true); 
  lineChart.setMinY(0);
  
  lineChart.setPointColour(color(255, 0, 255));
  lineChart.setPointSize(5);
  lineChart.setLineWidth(2);
  
  
  //Linear Transducer Graph
  lineChartLinear.showXAxis(true); 
  lineChartLinear.showYAxis(true);
  
  lineChartLinear.setPointColour(color(50, 205, 50));
  lineChartLinear.setPointSize(5);
  lineChartLinear.setLineWidth(2);
  
  
  //Stress Strain Graph
  stressStrain.showXAxis(true); 
  stressStrain.showYAxis(true);
  
  stressStrain.setPointColour(color(0, 191, 255));
  stressStrain.setPointSize(5);
  stressStrain.setLineWidth(2);
  
}


void createGUI(){
  G4P.setGlobalColorScheme(GCScheme.BLUE_SCHEME);
  G4P.messagesEnabled(false);
  //G4P.setCursorOff(ARROW);
  if(frame != null)
    frame.setTitle("Sketch Window");
  textfield1 = new GTextField(this, 55, 56, 160, 30, G4P.SCROLLBARS_NONE);
  textfield1.addEventHandler(this, "textfield1_change1");
  textfield2 = new GTextField(this, 57, 12, 160, 30, G4P.SCROLLBARS_NONE);
  textfield2.addEventHandler(this, "textfield2_change1");
  label1 = new GLabel(this, 57, 109, 157, 44);
  label1.setText("My label");
  label1.setOpaque(false);
}


public boolean isDouble(String str){
    try{
        Double.parseDouble(str);
        return true;
      }
    catch(Exception e){
        return false;
    }
}

void mousePressed () {
 
  println("\nDATA SAVED TO FILE\n");
  saveTable(table, fileName);
  
}

void draw () {
 
  background(255);
  fill(0);
  textSize(14);
  
  for(int i = 0; i < myPorts.length; i++) {
    text("Port " + i + ":", 50, 25 + (i * 20));
    fill(255, 0, 0);
    text(myPorts[i], 105, 25 + (i * 20));
    fill(0);
  }
  
  
  DPM3.write(getReading);
  DP41.write(getData);
  
  
  if (runMotor1 && count > 20) {
    if (testSwitch) {
      PMD401.write(moveRightSlow);
      println("RIGHT");
    } else {
     PMD401.write(moveLeftSlow);
     println("LEFT");
    }
  }
  
    
  while (PMD401.available() > 0) {
    motorResponse = PMD401.readString();   
    if (motorResponse != null) {
      //println(motorResponse);
    }
  }
  
  while (DPM3.available() > 0) {
    loadCellData = DPM3.readString();   
    if (loadCellData != null) {
      //println(loadCellData);
    }
  }
  
  while (DP41.available() > 0) {
    linearData = DP41.readString();
    if (linearData != null) {
      //println(linearData);
    }
  }
  
  text("Motor Response: " + motorResponse, 220, 25);
  text("Load Cell Data: " + loadCellData, 220, 45);
  text("Linear Transducer Data: " + linearData, 220, 65);
  
  
  if (isDouble(loadCellData) && isDouble(linearData)) {
    time = millis() - timeInit;
    data = Float.parseFloat(loadCellData);
    dataLinear = Float.parseFloat(linearData);
    
    if (dataCount == 0) {
      linearDataGraph.add(dataLinear);
      loadDataGraph.add(data);
      initLinearPosition = linearDataGraph.get(0);
      dataCount = 1;
    }
    
    if (abs(dataLinear - linearDataGraph.get(linearDataGraph.size()-1)) < tolerance) {
    table.addRow();
    table.setInt(dataCount, "Count", count);
    table.setInt(dataCount, "Time", time);
    table.setFloat(dataCount, "Load Data", data);
    table.setFloat(dataCount, "Linear Data", dataLinear);
    
    loadDataGraph.add(data);
    linearDataGraph.add(dataLinear);
    
    
    println(initLinearPosition);
    
    dataCount++;
    }
    println(dataCount);
    float[] xData = new float[dataCount];
  float[] yData = new float[dataCount];
  float[] timeData = new float[dataCount];
  float[] stressData = new float[dataCount];
  float[] strainData = new float[dataCount];
  
  for (int j = 0; j < dataCount; j++) {
    xData[j] = loadDataGraph.get(j);
    yData[j] = linearDataGraph.get(j);
    timeData[j] = j;
    stressData[j] = (loadDataGraph.get(j) * 9.807)/PROBE_CROSS_SECTIONAL_AREA;
    strainData[j] = (linearDataGraph.get(j) - initLinearPosition)/PROBE_LENGTH;
  }
  
  lineChart.setData(timeData, xData);
  lineChartLinear.setData(timeData, yData);
  stressStrain.setData(strainData, stressData);
    
  }
  
  
  textSize(9);
  lineChart.draw(15,100,width-30,225);
  lineChartLinear.draw(15,350,width-30,225);
  stressStrain.draw(15,600,width-30,225);
  
  
  
  if (runMotor1 && dataCount > 0) {
    float position = linearDataGraph.get(linearDataGraph.size()-1) - initLinearPosition;
  if (position > (TRAVEL_DISTANCE / 2.0)) {
    testSwitch = false;
    println("RIGHT: " + position);
  } else if (position < -(TRAVEL_DISTANCE / 2.0)) {
    testSwitch = true;
    println("LEFT: " + position);
  }
  }
  
  
  if (runMotor2 && dataCount > 0) {
    if (abs(linearDataGraph.get(linearDataGraph.size()-1) - initLinearPosition) < BREAK_DISTANCE) {
      PMD401.write(moveLeftSlow);
    } else {
      PMD401.write(stop);
    }
  }
  
  
  count++;
  
  delay(50);
}
