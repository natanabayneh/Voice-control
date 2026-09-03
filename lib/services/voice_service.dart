import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/robot_command.dart';

/// Wraps the phone's built-in speech recogniser and turns what it hears
/// into a [RobotCommand]. No API key and no network account needed —
/// this is the same engine the Android keyboard's mic button uses.
class VoiceService extends ChangeNotifier {
  VoiceService({required this.onCommand});

  /// Called with the matched command and the phrase that produced it.
  final void Function(RobotCommand command, String transcript) onCommand;

  final SpeechToText _speech = SpeechToText();

  bool available = false;
  bool listening = false;
  String transcript = '';
  String? error;
  RobotCommand? lastMatch;

  /// Keeps the recogniser running so you can give commands back to back
  /// without tapping the mic each time.
  bool handsFree = false;

  String? _localeId;
  bool _firedThisSession = false;
  bool _restarting = false;

  Future<void> init() async {
    try {
      available = await _speech.initialize(
        onStatus: _onStatus,
        onError: (e) {
          // "no match" and "speech timeout" just mean it heard nothing —
          // in hands-free mode that is normal, so don't shout about it.
          if (e.errorMsg == 'error_no_match' ||
              e.errorMsg == 'error_speech_timeout') {
            return;
          }
          error = 'Speech error: ${e.errorMsg}';
          notifyListeners();
        },
      );
      if (available) {
        final locales = await _speech.locales();
        _localeId = locales
            .firstWhere(
              (l) => l.localeId.startsWith('en_US'),
              orElse: () => locales.firstWhere(
                (l) => l.localeId.startsWith('en'),
                orElse: () => locales.first,
              ),
            )
            .localeId;
      } else {
        error = 'Speech recognition is unavailable on this device. '
            'Check that Google app / speech services are installed and '
            'that microphone permission was granted.';
      }
    } catch (e) {
      available = false;
      error = 'Could not start speech recognition: $e';
    }
    notifyListeners();
  }

  Future<void> toggleListening() async {
    if (listening) {
      handsFree = false;
      await stop();
    } else {
      await start();
    }
  }

  Future<void> start() async {
    if (!available || listening) return;
    error = null;
    transcript = '';
    lastMatch = null;
    _firedThisSession = false;
    try {
      await _speech.listen(
        onResult: _onResult,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenFor: const Duration(seconds: 8),
          pauseFor: const Duration(seconds: 3),
          localeId: _localeId,
        ),
      );
      listening = true;
    } catch (e) {
      error = 'Could not start listening: $e';
      listening = false;
    }
    notifyListeners();
  }

  Future<void> stop() async {
    if (!listening) return;
    await _speech.stop();
    listening = false;
    notifyListeners();
  }

  void setHandsFree(bool value) {
    handsFree = value;
    notifyListeners();
    if (value && !listening) {
      start();
    } else if (!value && listening) {
      stop();
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    transcript = result.recognizedWords;
    notifyListeners();
    if (_firedThisSession) return;

    final command = RobotCommand.match(transcript);
    if (command != null) {
      // Act on the partial result — waiting for the final one adds a
      // second or more of the robot doing the wrong thing.
      _firedThisSession = true;
      lastMatch = command;
      onCommand(command, transcript);
      notifyListeners();
      _speech.stop();
    } else if (result.finalResult) {
      error = 'Heard "$transcript" — no matching command.';
      notifyListeners();
    }
  }

  void _onStatus(String status) {
    final wasListening = listening;
    listening = _speech.isListening;
    notifyListeners();

    final sessionEnded = wasListening && !listening;
    if (sessionEnded && handsFree && !_restarting) {
      // Give the recogniser a moment to release the mic before reopening.
      _restarting = true;
      Timer(const Duration(milliseconds: 400), () {
        _restarting = false;
        if (handsFree && !listening) start();
      });
    }
  }

  @override
  void dispose() {
    handsFree = false;
    _speech.cancel();
    super.dispose();
  }
}
