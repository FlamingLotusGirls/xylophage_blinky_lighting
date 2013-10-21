int spectrumLeft[7];
int spectrumRight[7];

#define GOTOXY( x,y) "\033[x;yH"   // Esc[Line;ColumnH

void setup() {
  
  Serial.begin(115200);
  
  //Two PWM pins used. Will only light two of 8 LED strips in BM2013 shield configuration. Re
  pinMode(10, OUTPUT);
  pinMode(11, OUTPUT);
  
  //Setup pins to drive the spectrum analyzer. It needs RESET and STROBE pins.
  pinMode(5, OUTPUT); //Strobe
  pinMode(4, OUTPUT); //Reset

  //Init spectrum analyzer
  digitalWrite(4,LOW);  
  digitalWrite(5,HIGH); 
  digitalWrite(4,HIGH);
  digitalWrite(4,LOW);
  digitalWrite(5,LOW);
  
}

void loop() {
  int bassAvg = 0;
  int midAvg = 0;
  
  while(1)
  {
    readSpectrum(); 

    bassAvg = (bassAvg + spectrumLeft[1])/2;
    midAvg  = (midAvg + spectrumLeft[5])/2;

    analogWrite(10,bassAvg);
    analogWrite(11,midAvg);
  }

}

void readSpectrum()
{
  int Band;
  for(Band=0;Band <7; Band++)
  {
    spectrumLeft[Band] = analogRead(0); //left
    spectrumRight[Band] = analogRead(1); //right
    digitalWrite(4,HIGH);  //Strobe pin on the shield
    digitalWrite(4,LOW);     
  }
}

