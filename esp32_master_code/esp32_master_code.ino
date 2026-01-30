#include <SPI.h>

const int CS_PIN = 5; 

void setup() {
  Serial.begin(115200);
  
  pinMode(CS_PIN, OUTPUT);
  digitalWrite(CS_PIN, HIGH); // Idle state

  SPI.begin(); 
  SPI.beginTransaction(SPISettings(1000000, MSBFIRST, SPI_MODE0));  //configure to Mode 0: data sampled in rising edge, shifted in falling edge; start at 1MHz

}

uint32_t executeOp(byte opcode, byte a, byte b) {     //sends the 24-bit command and reads the result back
  uint32_t result = 0;

  digitalWrite(CS_PIN, LOW);        //sending the comm
  SPI.transfer(opcode);             // op code
  SPI.transfer(a);                  // A
  SPI.transfer(b);                  // B
  digitalWrite(CS_PIN, HIGH);

  delayMicroseconds(5); 

  digitalWrite(CS_PIN, LOW);                      //reading the 32-bit result back
  SPI.transfer(0x08);                             // Read Last Result op code
  SPI.transfer(0x00);                             // Dummy
  SPI.transfer(0x00);                             // Dummy
  
  // Shift in 4 bytes of result data
  for (int i = 0; i < 4; i++) {
    result = (result << 8) | SPI.transfer(0x00);
  }
  digitalWrite(CS_PIN, HIGH);

  return result;
}

void loop() {
  //ADD (5 + 9)
  uint32_t sum = executeOp(0x01, 5, 9);
  Serial.print("ADD (5+9): "); Serial.println(sum);

  //MUL (6 * 7)
  uint32_t prod = executeOp(0x02, 6, 7);
  Serial.print("MUL (6*7): "); Serial.println(prod);
  
  //MAC (Multiply-Accumulate)
  executeOp(0x06, 0, 0);
  executeOp(0x05, 2, 3);
  uint32_t mac_val = executeOp(0x05, 4, 5);
  Serial.print("MAC Result: "); Serial.println(mac_val);
  
  Serial.println("-----------------------------");
  delay(2000);
}