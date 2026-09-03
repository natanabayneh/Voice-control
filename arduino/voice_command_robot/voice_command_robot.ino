/*
 * Voice Command Robot — receiver sketch
 *
 * Pairs with the Flutter app in this repository. The app sends one ASCII
 * character per command over the HC-05:
 *
 *   '1' forward   '2' backward   '3' left   '4' right   '0' stop
 *
 * Wiring assumed below (Arduino Uno / Nano + L298N motor driver):
 *
 *   HC-05 VCC  -> 5V
 *   HC-05 GND  -> GND
 *   HC-05 TXD  -> pin 2            (Arduino receives)
 *   HC-05 RXD  -> pin 3 through a voltage divider (2k / 1k) — the module's
 *                 RX pin is 3.3V tolerant only, a bare 5V line can kill it.
 *
 *   L298N ENA -> 5    IN1 -> 6    IN2 -> 7      (left motor)
 *   L298N ENB -> 10   IN3 -> 8    IN4 -> 9      (right motor)
 *   L298N GND -> Arduino GND  (common ground is required)
 *
 * SoftwareSerial is used so pins 0/1 stay free for USB uploads and the
 * serial monitor.
 */

#include <SoftwareSerial.h>

const uint8_t BT_RX = 2;  // Arduino RX  <- HC-05 TXD
const uint8_t BT_TX = 3;  // Arduino TX  -> HC-05 RXD (via divider)

const uint8_t ENA = 5;
const uint8_t IN1 = 6;
const uint8_t IN2 = 7;
const uint8_t IN3 = 8;
const uint8_t IN4 = 9;
const uint8_t ENB = 10;

// 0-255. Start around 180; below ~120 most cheap gear motors just buzz.
const uint8_t SPEED = 180;

// Safety net in case the phone disconnects mid-move or a packet is lost.
// The app also sends its own auto-stop, so this rarely fires.
const unsigned long COMMAND_TIMEOUT_MS = 3000;

SoftwareSerial bluetooth(BT_RX, BT_TX);

unsigned long lastCommandAt = 0;
bool moving = false;

void setup() {
  pinMode(ENA, OUTPUT);
  pinMode(ENB, OUTPUT);
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);

  Serial.begin(9600);      // USB serial monitor, for debugging
  bluetooth.begin(9600);   // HC-05 default baud

  stopMotors();
  Serial.println(F("Ready. Waiting for commands: 1 2 3 4 0"));
}

void loop() {
  if (bluetooth.available()) {
    char command = bluetooth.read();
    handleCommand(command);
  }

  if (moving && millis() - lastCommandAt > COMMAND_TIMEOUT_MS) {
    Serial.println(F("Timeout - stopping"));
    stopMotors();
  }
}

void handleCommand(char command) {
  switch (command) {
    case '1':
      forward();
      break;
    case '2':
      backward();
      break;
    case '3':
      left();
      break;
    case '4':
      right();
      break;
    case '0':
      stopMotors();
      break;
    default:
      // Ignore newlines, spaces and anything else we did not ask for.
      return;
  }
  lastCommandAt = millis();
  Serial.print(F("Command: "));
  Serial.println(command);
}

// --- motor primitives -------------------------------------------------

void driveMotors(bool leftForward, bool rightForward) {
  digitalWrite(IN1, leftForward ? HIGH : LOW);
  digitalWrite(IN2, leftForward ? LOW : HIGH);
  digitalWrite(IN3, rightForward ? HIGH : LOW);
  digitalWrite(IN4, rightForward ? LOW : HIGH);
  analogWrite(ENA, SPEED);
  analogWrite(ENB, SPEED);
  moving = true;
}

void forward() {
  driveMotors(true, true);
}

void backward() {
  driveMotors(false, false);
}

// Turning in place: one side forward, the other back. If your robot spins
// the wrong way, swap the two motor connectors on the L298N.
void left() {
  driveMotors(false, true);
}

void right() {
  driveMotors(true, false);
}

void stopMotors() {
  analogWrite(ENA, 0);
  analogWrite(ENB, 0);
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);
  moving = false;
}
