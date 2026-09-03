import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/robot_command.dart';

/// The button pad: forward on top, left / stop / right in the middle,
/// backward underneath. Big targets so it works with your thumb.
class Dpad extends StatelessWidget {
  const Dpad({super.key, required this.onPressed, required this.enabled});

  final void Function(RobotCommand) onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PadButton(RobotCommand.forward, onPressed, enabled),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PadButton(RobotCommand.left, onPressed, enabled),
            const SizedBox(width: 12),
            _PadButton(RobotCommand.stop, onPressed, enabled),
            const SizedBox(width: 12),
            _PadButton(RobotCommand.right, onPressed, enabled),
          ],
        ),
        const SizedBox(height: 12),
        _PadButton(RobotCommand.backward, onPressed, enabled),
      ],
    );
  }
}

class _PadButton extends StatelessWidget {
  const _PadButton(this.command, this.onPressed, this.enabled);

  final RobotCommand command;
  final void Function(RobotCommand) onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isStop = command == RobotCommand.stop;
    return SizedBox(
      width: 96,
      height: 96,
      child: FilledButton(
        onPressed: enabled
            ? () {
                HapticFeedback.mediumImpact();
                onPressed(command);
              }
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: isStop ? scheme.error : null,
          foregroundColor: isStop ? scheme.onError : null,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isStop ? 48 : 16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(command.icon, size: 32),
            const SizedBox(height: 4),
            Text(command.label, style: const TextStyle(fontSize: 12)),
            Text(command.code,
                style: const TextStyle(fontSize: 10, height: 1.6)),
          ],
        ),
      ),
    );
  }
}
