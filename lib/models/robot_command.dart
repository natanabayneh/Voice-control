import 'package:flutter/material.dart';

/// A single instruction sent to the Arduino.
///
/// The robot protocol is one ASCII character per command, matching the
/// `switch (Serial.read())` in the sketch:
///   '1' forward, '2' backward, '3' left, '4' right, '0' stop.
enum RobotCommand {
  forward('1', 'Forward', Icons.arrow_upward_rounded,
      ['forward', 'ahead', 'straight', 'front', 'go']),
  backward('2', 'Backward', Icons.arrow_downward_rounded,
      ['backward', 'backwards', 'back', 'reverse', 'behind']),
  left('3', 'Left', Icons.arrow_back_rounded, ['left']),
  right('4', 'Right', Icons.arrow_forward_rounded, ['right']),
  stop('0', 'Stop', Icons.stop_rounded, ['stop', 'halt', 'brake', 'freeze']);

  const RobotCommand(this.code, this.label, this.icon, this.keywords);

  /// The character written over the serial link.
  final String code;
  final String label;
  final IconData icon;

  /// Spoken words that select this command.
  final List<String> keywords;

  bool get isMovement => this != RobotCommand.stop;

  /// Order matters. `stop` wins over everything so "stop turning left"
  /// stops instead of turning, and `left`/`right` are checked before
  /// `forward` so "go left" is a turn rather than the "go" keyword.
  static const _matchOrder = [stop, left, right, backward, forward];

  /// Finds the command a spoken phrase refers to, or null if none matches.
  static RobotCommand? match(String transcript) {
    final text = transcript.toLowerCase();
    for (final command in _matchOrder) {
      for (final keyword in command.keywords) {
        if (RegExp('\b$keyword\b').hasMatch(text)) return command;
      }
    }
    return null;
  }
}
