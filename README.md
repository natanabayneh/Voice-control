# Voice Command Robot

An Android app for driving an Arduino robot over an HC-05 / HC-06 Bluetooth
module, either with on-screen buttons or by speaking.

## The protocol

One ASCII character per command, matching the sketch in
[`arduino/`](arduino/voice_command_robot/voice_command_robot.ino):

| Command  | Character | Spoken words                            |
| -------- | --------- | --------------------------------------- |
| Forward  | `1`       | forward, ahead, straight, front, go     |
| Backward | `2`       | backward, backwards, back, reverse      |
| Left     | `3`       | left                                    |
| Right    | `4`       | right                                   |
| Stop     | `0`       | stop, halt, brake, freeze               |

Phrases are matched on whole words, so "goal" is not a "go". `stop` is
checked first and directions before `go`, so "stop turning left" stops and
"go left" turns.

## Running it

1. Power the robot and pair the HC-05 in **Android Settings → Bluetooth**
   (PIN is usually `1234` or `0000`). The app does not pair — it only
   connects to what Android has already paired.
2. `flutter run` with the phone plugged in, or install the APK from
   `build/app/outputs/flutter-apk/`.
3. Pick the module from the list, then drive.

Android 6.0 (API 23) or newer. Bluetooth Classic is Android-only — there is
no iOS build, because iOS does not expose the Serial Port Profile to apps.

## Voice

Uses the phone's built-in recogniser (`speech_to_text`) — no API key, no
account, and it works offline once Android has downloaded the English
language pack. Tap the mic for one command, or turn on **Hands-free** to
keep the recogniser running between commands.

A command fires as soon as a keyword appears in the partial transcript
rather than waiting for the recogniser to finalise, which cuts about a
second off the response time.

## Settings

- **Auto-stop** — recognition takes a second or two and the robot keeps
  driving the whole time. After any movement command the app sends `0`
  automatically unless another command arrives first. Default 2s,
  adjustable, can be turned off.
- **Append newline** — turn on if your sketch reads with
  `Serial.readStringUntil('\n')` instead of `Serial.read()`.

## Layout

```
lib/
  models/robot_command.dart    the five commands, their characters and keywords
  services/bt_service.dart     the Bluetooth link, sending, auto-stop, log
  services/voice_service.dart  speech recognition and keyword matching
  screens/device_screen.dart   paired device picker
  screens/control_screen.dart  driving screen
  screens/settings_sheet.dart  auto-stop and newline options
  widgets/dpad.dart            the button pad
arduino/                       matching receiver sketch (L298N wiring in the header)
test/                          command-matching tests
```

## Note on the Bluetooth package

`flutter_bluetooth_serial` is the usual suggestion for HC-05 work, but it was
last published in 2021 and does not build under Android Gradle Plugin 8; the
`_ble` fork is capped at Dart `<3.0.0`. This project uses `bluetooth_classic`
instead, which is current and covers what is needed here: list paired
devices, connect over the SPP UUID, and write bytes.

That plugin pins `compileSdkVersion 31`, so
[`android/build.gradle.kts`](android/build.gradle.kts) raises every plugin's
compile SDK to 35 to avoid having to install an old platform SDK.
