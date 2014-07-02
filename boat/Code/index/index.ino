int motorSouth = 3;
int motorSouthReverse = 9;
int motorNorthwest = 5;
int motorNorthwestReverse = 10;
int motorNortheast = 6;
int motorNortheastReverse = 11;

int SensorNorth = A2;
int SensorSouthwest = A1;
int SensorSoutheast = A3;

int SensorValueNorth = 0;
int SensorValueSouthwest = 0;
int SensorValueSoutheast = 0;

int baseFrameBrightness = 0;
int numberOfSamples = 50;
int brightnessSum = 0;
bool isFirstRun;

int play = 25;
int whiteToGray = 100;
int grayToBlack = 100;
int blackToWhite = whiteToBlack + grayToBlack;

void setup() {
  // put your setup code here, to run once:
  pinMode(motorSouth, OUTPUT);
  pinMode(motorSouthReverse, OUTPUT);
  pinMode(motorNorthwest, OUTPUT);
  pinMode(motorNorthwestReverse, OUTPUT);
  pinMode(motorNortheast, OUTPUT);
  pinMode(motorNortheastReverse, OUTPUT);
  isFirstRun = true;


}

void calculateDirection (int valueN, int valueSW, int valueSE) {
  valueN -= baseFrameBrightness;
  valueSW -= baseFrameBrightness;
  valueSE -= baseFrameBrightness;

  if (valueN - valueSW)
}

void calculateAverage() {

  for (int i = 0; i < = numberOfSamples; i++) {
    SensorValueNorth = analogRead(A2);
    SensorValueSouthwest = analogRead(A3);
    SensorValueSoutheast = analogRead(A1);
    brightnessSum += (SensorValueSoutheast + SensorValueSouthwest + SensorValueNorth ) / 3;
  }
  baseFrameBrightness = brightnessSum / numberOfSamples;

}

void move (int degree) {
  // 0 is north, 180 south, 90 east, 270 west

  int powerMotorS = 0;
  int powerMotorNW = 0;
  int powerMotorNE = 0;

  // Fraction of MotorS
  if (degree >= 240 && degree < 360) {
    powerMotorS = 255 - ((360 - degree)/120 * 255));
    powerMotorNE = ;
  }
  if (degree >= 0 && degree < 120) {
    powerMotorS = ((120 - degree)/120 * 255));
    powerMotorNW = ;

  }

  // Fraction of MotorNW
  if (degree >= 0 && degree < 240) {
    powerMotorNW = (-abs(2 * ((240 - degree)/240) - 1) + 1)*255;
  }
  // Fraction of MotorNE
  if (degree >= 120 && degree < 360) {
    powerMotorNE = (-abs(2 * ((360 - degree)/240) - 1) + 1)*255;
  }

  analogWrite(motorSouth, powerMotorS);
  digitalWrite(motorSouthReverse, LOW);

  analogWrite(motorNorthwest, powerMotorNW);
  digitalWrite(motorNorthwestReverse, LOW);

  analogWrite(motorNortheast, powerMotorNE);
  digitalWrite(motorNortheastReverse, LOW);
}

void test() {
   digitalWrite(motorSouth, HIGH);   // turn the LED on (HIGH is the voltage level)
  digitalWrite(motorSouthReverse, LOW);
  delay(1000);               // wait for a second
  digitalWrite(motorSouth, LOW);    // turn the LED off by making the voltage LOW
  delay(1000);               // wait for a second

  digitalWrite(motorNorthwest, HIGH);   // turn the LED on (HIGH is the voltage level)
  digitalWrite(motorNorthwestReverse, LOW);
  delay(1000);               // wait for a second
  digitalWrite(motorNorthwest, LOW);    // turn the LED off by making the voltage LOW
  delay(1000);               // wait for a second

  digitalWrite(motorNortheast, HIGH);   // turn the LED on (HIGH is the voltage level)
  digitalWrite(motorNortheastReverse, LOW);
  delay(1000);               // wait for a second
  digitalWrite(motorNortheast, LOW);    // turn the LED off by making the voltage LOW
  delay(1000);               // wait for a second
}


void loop() {

  if (firstRun) {
    calculateAverage();
    isFirstRun = false;
  }

  SensorValueNorth = analogRead(A2);
  SensorValueSouthwest = analogRead(A3);
  SensorValueSoutheast = analogRead(A1);

  calculateDirection(SensorValueNorth, SensorValueSouthwest, SensorValueSoutheast);

}
