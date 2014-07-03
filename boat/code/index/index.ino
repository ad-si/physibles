int motorS = 3;
int motorSReverse = 9;
int motorNW = 5;
int motorNWReverse = 10;
int motorNE = 6;
int motorNEReverse = 11;

int sensorNPin = A2;
int sensorSEPin = A1;
int sensorSWPin = A3;

int sensorNValue = 0;
int sensorSWValue = 0;
int sensorSEValue = 0;

int baseFrameBrightness = 0;
int numberOfSamples = 50;
int brightnessSum = 0;
bool isFirstRun;

int play = 25;
int whiteToGray = 100;
int grayToBlack = 100;
int blackToWhite = whiteToGray + grayToBlack;



void calculateDirection (int valueN, int valueSW, int valueSE) {
	valueN -= baseFrameBrightness;
	valueSW -= baseFrameBrightness;
	valueSE -= baseFrameBrightness;

	//if (valueN - valueSW)
}

void calculateAverage() {

	for (int i = 0; i <= numberOfSamples; i++) {
		sensorNValue = analogRead(A2);
		sensorSWValue = analogRead(A3);
		sensorSEValue = analogRead(A1);
		brightnessSum += (sensorSEValue + sensorSWValue + sensorNValue) / 3;
	}
	baseFrameBrightness = brightnessSum / numberOfSamples;

}

void move (int degree) {
	// 0 is north, 180 south, 90 east, 270 west

	int powerMotorS = 0;
	int powerMotorNW = 0;
	int powerMotorNE = 0;

	// Fraction of MotorS
	if (degree >= 240 && degree < 360)
		powerMotorS = 255 - ((360 - degree)/120 * 255);
	
	if (degree >= 0 && degree < 120)
		powerMotorS = ((120 - degree)/120 * 255);

	// Fraction of MotorNW
	if (degree >= 0 && degree < 240)
		powerMotorNW = (-abs(2 * ((240 - degree)/240) - 1) + 1) * 255;
	
	// Fraction of MotorNE
	if (degree >= 120 && degree < 360)
		powerMotorNE = (-abs(2 * ((360 - degree)/240) - 1) + 1) * 255;

	analogWrite(motorS, powerMotorS);
	digitalWrite(motorSReverse, LOW);

	analogWrite(motorNW, powerMotorNW);
	digitalWrite(motorNWReverse, LOW);

	analogWrite(motorNE, powerMotorNE);
	digitalWrite(motorNEReverse, LOW);
}

void test() {
	 digitalWrite(motorS, HIGH);	 // turn the LED on (HIGH is the voltage level)
	digitalWrite(motorSReverse, LOW);
	delay(1000);							 // wait for a second
	digitalWrite(motorS, LOW);		// turn the LED off by making the voltage LOW
	delay(1000);							 // wait for a second

	digitalWrite(motorNW, HIGH);	 // turn the LED on (HIGH is the voltage level)
	digitalWrite(motorNWReverse, LOW);
	delay(1000);							 // wait for a second
	digitalWrite(motorNW, LOW);		// turn the LED off by making the voltage LOW
	delay(1000);							 // wait for a second

	digitalWrite(motorNE, HIGH);	 // turn the LED on (HIGH is the voltage level)
	digitalWrite(motorNEReverse, LOW);
	delay(1000);							 // wait for a second
	digitalWrite(motorNE, LOW);		// turn the LED off by making the voltage LOW
	delay(1000);							 // wait for a second
}



void setup() {
	// put your setup code here, to run once:
	pinMode(motorS, OUTPUT);
	pinMode(motorSReverse, OUTPUT);
	pinMode(motorNW, OUTPUT);
	pinMode(motorNWReverse, OUTPUT);
	pinMode(motorNE, OUTPUT);
	pinMode(motorNEReverse, OUTPUT);
	isFirstRun = true;


}

void loop() {

	if (isFirstRun) {
		calculateAverage();
		isFirstRun = false;
	}

	//sensorNValue = analogRead(sensorNPin);
	//sensorSWValue = analogRead(sensorSWPin);
	//sensorSEValue = analogRead(sensorSEPin);

	//calculateDirection(sensorNValue, sensorSWValue, sensorSEValue);
	
	move(0);
	delay(5000);
	move(120);
	delay(5000);
	move(240);
	delay(5000);
	move(60);
	delay(5000);
	move(180);
	delay(5000);
	move(300);
	delay(5000);
}
