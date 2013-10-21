// Analog pin assignments
//===================================================
int pInL        =  0;
int pInR        =  1;

// Digital pin assignments
//===================================================
int pSpecStrobe =  4;
int pSpecReset  =  5;
int pDataR      =  6; // DI
int pLatchR     =  7; // LI
int pEnableR    =  8; // EI
int pClockR     =  9; // CI
int pDataL      = 13; // DI
int pLatchL     = 12; // LI
int pEnableL    = 11; // EI
int pClockL     = 10; // CI

// Spectrum analyzer stuff
// ===================================================
// Left
int specL[7];
float alphaRedL = .95;
float alphaGreenL = .9;
float alphaBlueL = .95;
float lvl1L = 0;
float lvl1LMin = 80;
float lvl1LMax = 160;
float lvl3L = 0;
float lvl3LMin = 85;
float lvl3LMax = 500; 
float lvl5L = 0;
float lvl5LMin = 150;
float lvl5LMax = 200;

// Right
int specR[7];
float alphaRedR = .8;
float alphaGreenR = .8;
float alphaBlueR = .95;
float lvl1R = 0;
float lvl1RMin = 150;
float lvl1RMax = 200;
float lvl3R = 0;
float lvl3RMin = 70;
float lvl3RMax = 1000; 
float lvl5R = 0;
float lvl5RMin = 150;
float lvl5RMax = 200;

float angleWrap = 3.14;
float angle = 0; // starting angle
float brightStep = .15; // radian step per delay
int dly = 1; // dly in ms
float curLevel;
float heartBeatCount = 0;

void specInit() {//Init spectrum analyzer
  //===================================================
  //Setup pins to drive the spectrum analyzer. 
  analogReference(DEFAULT);
  pinMode(pSpecReset, OUTPUT);
  pinMode(pSpecStrobe, OUTPUT);
  
  // Reset MSGEQ7 (make sure the current band starts at DC)
  // NOTE: This code was copied from the sparkfun example.
  // Other parts of that code didn't work...so this should 
  // be double-checked.  Seems to work though.
  digitalWrite(pSpecStrobe,LOW);
    delay(1);
  digitalWrite(pSpecReset,HIGH);
    delay(1);
  digitalWrite(pSpecStrobe,HIGH);
    delay(1);
  digitalWrite(pSpecStrobe,LOW);
    delay(1);
  digitalWrite(pSpecReset,LOW);
    delay(5);
  // Reading the analyzer now will read the lowest frequency.
} 

void specRead() {
  
  byte band;
  
  digitalWrite(pSpecReset, HIGH);
  digitalWrite(pSpecReset, LOW);
  
  for(band=0; band <7; band++) {
    // Pull strobe low to kick up to next band 
    digitalWrite(pSpecStrobe, LOW); 
    delayMicroseconds(30);
    
    // store left band reading
    specL[band] = analogRead(pInL); 
    specR[band] = analogRead(pInR);
    
    // Pull strobe high before moving on to next band
    digitalWrite(pSpecStrobe,HIGH);  
    delayMicroseconds(30);
  }
}

void specPrint() 
{
  byte band;
  
  // Print Left Values
  Serial.print("L: ");
  for (band = 0; band < 7; band++) {

    // Print leading spaces if necessary.
    if (specL[band] < 1000) {Serial.print(' ');}
    if (specL[band] < 100)  {Serial.print(' ');}
    if (specL[band] < 10)   {Serial.print(' ');}
    
    // Print value.  
    Serial.print(specL[band]);
    Serial.print(", "); 
  }
  
  // Print Right Values
  Serial.print("R: ");
  for (band = 0; band < 7; band++) {

    // Print leading spaces if necessary.
    if (specR[band] < 1000) {Serial.print(' ');}
    if (specR[band] < 100)  {Serial.print(' ');}
    if (specR[band] < 10)   {Serial.print(' ');}
    
    // Print value.  
    Serial.print(specR[band]);
    Serial.print(", "); 
  }
  
  // Print new line.
  Serial.println();
}

// Shiftbrite stuff
// ===================================================
unsigned long sbPacket;
int sbModeL;
int sbRedL     = 0;
int sbGreenL   = 0;
int sbBlueL    = 1023;
int sbModeR;
int sbRedR     = 0;
int sbGreenR   = 0;
int sbBlueR    = 1023;

void sbInit() {
    
  //Init Left Channel Shiftbrites
  pinMode(pDataL, OUTPUT);
  pinMode(pLatchL, OUTPUT);
  pinMode(pEnableL, OUTPUT);
  pinMode(pClockL, OUTPUT);
  
  digitalWrite(pLatchL, LOW);
  digitalWrite(pEnableL, LOW);
  
  // Enable full current
  sbModeL = B01; // Write to current control registers
  sbRedL = 120; // Full current
  sbGreenL = 100; // Full current
  sbBlueL = 100; // Full current
  sbSendPacket(true);
  sbModeL = B00;
  
  //Init Right Channel Shiftbrites
  pinMode(pDataR, OUTPUT);
  pinMode(pLatchR, OUTPUT);
  pinMode(pEnableR, OUTPUT);
  pinMode(pClockR, OUTPUT);
  
  digitalWrite(pLatchR, LOW);
  digitalWrite(pEnableR, LOW);
  
  // Enable full current
  sbModeR = B01; // Write to current control registers
  sbRedR = 120; // Full current
  sbGreenR = 100; // Full current
  sbBlueR = 100; // Full current
  sbSendPacket(false);
  sbModeR = B00;
}

void sbPrintCommand() {
  Serial.print(sbModeL, BIN);
  Serial.print(" ");
  Serial.print(sbRedL);
  Serial.print(" ");
  Serial.print(sbGreenL);
  Serial.print(" ");
  Serial.print(sbBlueL);
}

void sbSendPacket(boolean sendLeft) {

  int pClock;
  int pData;
  int pLatch;
  
  if (sendLeft) {
    sbPacket = sbModeL & B11;
    sbPacket = (sbPacket << 10)  | (sbBlueL & 1023);
    sbPacket = (sbPacket << 10)  | (sbRedL & 1023);
    sbPacket = (sbPacket << 10)  | (sbGreenL & 1023);
    pClock = pClockL;
    pData = pDataL;
    pLatch = pLatchL;
  } else {
    sbPacket = sbModeR & B11;
    sbPacket = (sbPacket << 10)  | (sbBlueR & 1023);
    sbPacket = (sbPacket << 10)  | (sbRedR & 1023);
    sbPacket = (sbPacket << 10)  | (sbGreenR & 1023);
    pClock = pClockR;
    pData = pDataR;
    pLatch = pLatchR;
  }
    
  shiftOut(pData, pClock, MSBFIRST, sbPacket >> 24);
  shiftOut(pData, pClock, MSBFIRST, sbPacket >> 16);
  shiftOut(pData, pClock, MSBFIRST, sbPacket >> 8);
  shiftOut(pData, pClock, MSBFIRST, sbPacket);

  delay(15); // adjustment may be necessary depending on chain length
  digitalWrite(pLatch,HIGH); // latch data into registers
  delay(15); // adjustment may be necessary depending on chain length
  digitalWrite(pLatch,LOW);
}

// Setup function
//===================================================
void setup() {
  
  Serial.begin(19200);
  sbInit(); // Init shiftbrites
  specInit(); // Init spectrum analyzer
}



// Loop function
//===================================================
void loop() {  
  
  if (angle >= angleWrap || angle <= -1*angleWrap) {
     brightStep = -1* brightStep; 
     heartBeatCount += .5;
  }
  
  if (heartBeatCount >= 1) {
    heartBeatCount = 0;
  }
  
  angle += brightStep;
  
  curLevel = sin(abs(angle));
  
  if (angle > 1/2) {
    curLevel = curLevel * .2;
  }
  
  if (curLevel < 0 || heartBeatCount >= .5) {
    curLevel = 0;
  }
  
  sbRedR = (int)(952.0f*curLevel);  
  sbGreenR = (int)(150.0f*curLevel);
  sbBlueR = (int)0;//215;
  //sbSendPacket(false); 
  
  sbRedL = sbRedR;
  sbGreenL = sbGreenR;
  sbBlueL = sbBlueR;
  sbSendPacket(true);
  //sbPrintCommand(); 
  
  delay(dly);
}




