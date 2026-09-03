import 'package:flutter/material.dart';

import 'screens/device_screen.dart';
import 'services/bt_service.dart';
import 'services/voice_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VoiceCommandRobotApp());
}

class VoiceCommandRobotApp extends StatefulWidget {
  const VoiceCommandRobotApp({super.key});

  @override
  State<VoiceCommandRobotApp> createState() => _VoiceCommandRobotAppState();
}

class _VoiceCommandRobotAppState extends State<VoiceCommandRobotApp> {
  late final BtService _bt;
  late final VoiceService _voice;

  @override
  void initState() {
    super.initState();
    _bt = BtService();
    // A recognised phrase goes straight out over Bluetooth; the phrase
    // itself is passed along so the log can show what was heard.
    _voice = VoiceService(
      onCommand: (command, transcript) => _bt.send(
        command,
        source: CommandSource.voice,
        detail: transcript,
      ),
    );
    _bt.init();
    _voice.init();
  }

  @override
  void dispose() {
    _voice.dispose();
    _bt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Command Robot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: DeviceScreen(bt: _bt, voice: _voice),
    );
  }
}
