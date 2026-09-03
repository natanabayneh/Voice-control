import 'package:flutter/material.dart';

import '../services/bt_service.dart';

/// The two knobs worth exposing: the auto-stop safety timer and whether
/// the sketch expects a newline after each command character.
void showSettingsSheet(BuildContext context, BtService bt) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => ListenableBuilder(
      listenable: bt,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto-stop'),
              subtitle: const Text(
                'Send stop automatically after a movement command, so the '
                'robot does not keep driving while you think.',
              ),
              value: bt.autoStopEnabled,
              onChanged: bt.setAutoStopEnabled,
            ),
            if (bt.autoStopEnabled) ...[
              Text('Stop after ${bt.autoStopAfter.inMilliseconds / 1000}s'),
              Slider(
                min: 0.5,
                max: 10,
                divisions: 19,
                label: '${bt.autoStopAfter.inMilliseconds / 1000}s',
                value: bt.autoStopAfter.inMilliseconds / 1000,
                onChanged: (v) => bt.setAutoStopAfter(
                  Duration(milliseconds: (v * 1000).round()),
                ),
              ),
            ],
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Append newline'),
              subtitle: const Text(
                'Turn on if your sketch uses Serial.readStringUntil(\'\\n\') '
                'instead of Serial.read().',
              ),
              value: bt.appendNewline,
              onChanged: bt.setAppendNewline,
            ),
          ],
        ),
      ),
    ),
  );
}
