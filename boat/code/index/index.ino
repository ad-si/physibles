int motorS = 3;
int motorSReverse = 9;
int motorNW = 5;
int motorNWReverse = 10;
int motorNE = 6;
int motorNEReverse = 11;

int sensorNPin = A2;
int sensorSEPin = A1;
int sensorSWPin = A3;

float sensorNValue = 0;
float sensorSWValue = 0;
float sensorSEValue = 0;

int baseFrameBrightness = 0;
int numberOfSamples = 50;
float brightnessSum = 0;
bool isFirstRun;

int play = 10;

int whiteToGray = 100;
int grayToBlack = 100;
int blackToWhite = whiteToGray + grayToBlack;


void calculateDirection (unsigned int valueN, unsigned int valueSW, unsigned int valueSE) {

	valueN = (valueN > baseFrameBrightness) ? (valueN - baseFrameBrightness) : 0;
	valueSE = (valueSE > baseFrameBrightness) ? (valueSE - baseFrameBrightness) : 0;
	valueSW = (valueSW > baseFrameBrightness) ? (valueSW - baseFrameBrightness) : 0;

	logCalibratedValues(valueN, valueSE, valueSW);


	int black = 0;
	int gray = 100;
	int white = 200;

	int totalValue = valueN + valueSW + valueSE;

	// black, black, black
	if (totalValue <= 3 * play) {
		move(random(360));
	}
	// gray, black, black
	else if (totalValue <= 3 * play + gray) {
		// valueN is largest
		if (valueN > valueSW && valueN > valueSE) move(0);
		// valueSW is largest
		else if (valueSW > valueN && valueSW > valueSE) move(120);
		// valueSE is largest
		else move(240);
	}
	// gray, gray, black
	else if (totalValue <= 3 * play + gray + gray) {
		// valueN is smallest
		if (valueN < valueSW && valueN < valueSE) move(180);
		// valueSW is smallest
		else if (valueSW < valueN && valueSW < valueSE) move(60);
		// valueSE is smallest
		else move(300);
	}
	// gray, gray, gray
	else if (totalValue <= 3 * play + gray + gray + gray) {
		move(random(360));
	}
	// white, gray, gray
	else if (totalValue <= 3 * play + white + gray + gray) {
		// valueN is largest
		if (valueN > valueSW && valueN > valueSE) move(0);
		// valueSW is largest
		else if (valueSW > valueN && valueSW > valueSE) move(120);
		// valueSE is largest
		else move(240);
	}
	// white, white, gray
	else if (totalValue <= 3 * play + white + white + gray) {
		// valueN is smallest
		if (valueN < valueSW && valueN < valueSE) move(180);
		// valueSW is smallest
		else if (valueSW < valueN && valueSW < valueSE) move(60);
		// valueSE is smallest
		else move(300);
	}
	// white, white, white
	else {
		move(random(360));
	}



	// white, black, black
	/*
	if (totalValue <= 3 * play + 200 && ) {
		// valueN is largest
		if (valueN > valueSW && valueN > valueSE) move(180);
		// valueSW is largest
		else if (valueSW > valueN && valueSW > valueSE) move(60);
		// valueSE is largest
		else move(300);
	}
	// white, white, black
	else if (totalValue <= 3 * play + 500) {
		if (valueN > valueSW && valueN > valueSE) move(180);
		// valueSW is largest
		else if (valueSW > valueN && valueSW > valueSE) move(60);
		// valueSE is largest
		else move(240);
	}
	*/
}

void calculateAverage() {

	for (int i = 0; i <= numberOfSamples; i++) {
		sensorNValue = analogRead(sensorNPin);
		sensorSWValue = analogRead(sensorSWPin);
		sensorSEValue = analogRead(sensorSEPin);
		brightnessSum += (sensorSEValue + sensorSWValue + sensorNValue) / 3;
		delay(20);
	}

	baseFrameBrightness = brightnessSum / numberOfSamples;

	/*Serial.print("baseFrameBrightness: ");
	Serial.println(baseFrameBrightness);*/

}

void move (float degree) {
	// 0 is north, 180 south, 90 east, 270 west

	float powerMotorS = 0;
	float powerMotorNW = 0;
	float powerMotorNE = 0;

	// Fraction of MotorS
	if (degree >= 240 && degree < 360)
		powerMotorS = 255 - ((360 - degree)/120 * 255);

	if (degree >= 0 && degree < 120)
		powerMotorS = (((120 - degree)/120) * 255);

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

void motorTest () {
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

void logSensorData () {
	Serial.print("Sensor data: ");
	Serial.print(sensorNValue);
	Serial.print(", ");
	Serial.print(sensorSWValue);
	Serial.print(", ");
	Serial.println(sensorSEValue);
}

void logCalibratedValues(int valueN, int valueSW, int valueSE) {
	Serial.print("Calibrated Values: ");
	Serial.print(valueN);
	Serial.print(", ");
	Serial.print(valueSW);
	Serial.print(", ");
	Serial.println(valueSE);
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

	Serial.begin(9600);

//	randomSeed(analogRead(0));
}

void loop() {

	if (isFirstRun) {
		calculateAverage();
		isFirstRun = false;
	}

	sensorNValue = analogRead(sensorNPin);
	sensorSWValue = analogRead(sensorSWPin);
	sensorSEValue = analogRead(sensorSEPin);

	calculateDirection(sensorNValue, sensorSWValue, sensorSEValue);

	delay(3000);
}
