import 'package:flutter/material.dart';

import '../services/bt_service.dart';
import '../services/voice_service.dart';
import '../widgets/dpad.dart';
import 'settings_sheet.dart';

/// The driving screen: buttons, microphone, and a log of what was sent.
class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key, required this.bt, required this.voice});

  final BtService bt;
  final VoiceService voice;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([bt, voice]),
      builder: (context, _) {
        // If the link drops, go back to the picker rather than leaving
        // dead buttons on screen.
        if (!bt.isConnected && !bt.isConnecting) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(bt.connectedDevice?.name ?? 'Robot'),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Settings',
                onPressed: () => showSettingsSheet(context, bt),
              ),
              IconButton(
                icon: const Icon(Icons.bluetooth_disabled),
                tooltip: 'Disconnect',
                onPressed: bt.disconnect,
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusBar(bt: bt),
                  const SizedBox(height: 20),
                  Dpad(
                    enabled: bt.isConnected,
                    onPressed: (command) => bt.send(command),
                  ),
                  const SizedBox(height: 24),
                  _VoicePanel(voice: voice, enabled: bt.isConnected),
                  const SizedBox(height: 24),
                  _Log(bt: bt),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.bt});

  final BtService bt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bt.isConnected
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                bt.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bt.isConnected
                      ? 'Connected to ${bt.connectedDevice?.name ?? bt.connectedDevice?.address}'
                      : 'Disconnected',
                ),
              ),
              if (bt.autoStopEnabled)
                Text('auto-stop ${bt.autoStopAfter.inSeconds}s',
                    style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
        if (bt.error != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.error_outline, size: 18, color: scheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(bt.error!,
                    style: TextStyle(color: scheme.error, fontSize: 12)),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: bt.clearError,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _VoicePanel extends StatelessWidget {
  const _VoicePanel({required this.voice, required this.enabled});

  final VoiceService voice;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: FilledButton(
                    onPressed:
                        enabled && voice.available ? voice.toggleListening : null,
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                      backgroundColor: voice.listening ? scheme.error : null,
                    ),
                    child: Icon(voice.listening ? Icons.mic : Icons.mic_none,
                        size: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voice.listening
                            ? 'Listening...'
                            : voice.available
                                ? 'Tap to speak'
                                : 'Speech unavailable',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        voice.transcript.isEmpty
                            ? 'Say: forward, back, left, right, stop'
                            : '"${voice.transcript}"',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (voice.error != null) ...[
              const SizedBox(height: 8),
              Text(voice.error!,
                  style: TextStyle(color: scheme.error, fontSize: 12)),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hands-free'),
              subtitle: const Text('Keep listening after each command'),
              value: voice.handsFree,
              onChanged: enabled && voice.available ? voice.setHandsFree : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Log extends StatelessWidget {
  const _Log({required this.bt});

  final BtService bt;

  static const _sourceLabels = {
    CommandSource.button: 'button',
    CommandSource.voice: 'voice',
    CommandSource.autoStop: 'auto-stop',
  };

  @override
  Widget build(BuildContext context) {
    if (bt.log.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sent', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...bt.log.take(8).map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(entry.command.icon, size: 16),
                    const SizedBox(width: 8),
                    Text('${entry.command.code}  ${entry.command.label}'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.detail != null
                            ? '${_sourceLabels[entry.source]}: "${entry.detail}"'
                            : _sourceLabels[entry.source]!,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
