static long openCode = 0xdddd;
static long lockHigh = 0xaaaa;
static long lockLow = 0xaaab;
static int d1 = 1;
int counter = 0;

long currentValue = 0;


void setup() {
  // put your setup code here, to run once:
  pinMode(d1, OUTPUT);
}


void loop() {

  currentValue = Bean.readScratchNumber(1);
  if (currentValue == openCode) {
    Bean.setScratchNumber(1, 0);
    digitalWrite(d1,HIGH);
    delay(500);
    digitalWrite(d1,LOW);
  } else if (currentValue == lockHigh){
    Bean.setScratchNumber(1, 0);
    digitalWrite(d1,HIGH);
  } else if (currentValue == lockLow){
    Bean.setScratchNumber(1, 0);
    digitalWrite(d1,LOW);
  }
    
    
  if (Bean.getConnectionState()){
    if (counter == 600){
      Bean.disconnect();
      counter = 0;
    }
  } else {
    counter = 0;
  }
  Bean.sleep(500);
}
