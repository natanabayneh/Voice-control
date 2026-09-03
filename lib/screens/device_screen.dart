import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/material.dart';

import '../services/bt_service.dart';
import '../services/voice_service.dart';
import 'control_screen.dart';

/// Lists the devices already paired in Android settings and connects to
/// the one you pick. Pairing itself is done by Android, not by this app.
class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key, required this.bt, required this.voice});

  final BtService bt;
  final VoiceService voice;

  Future<void> _connect(BuildContext context, Device device) async {
    final connected = await bt.connect(device);
    if (!context.mounted) return;
    if (connected) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ControlScreen(bt: bt, voice: voice),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose your robot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh paired devices',
            onPressed: bt.refreshDevices,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: bt,
        builder: (context, _) {
          if (bt.isConnecting) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Connecting to '
                      '${bt.connectedDevice?.name ?? bt.connectedDevice?.address}...'),
                ],
              ),
            );
          }
          return Column(
            children: [
              if (bt.error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline),
                          const SizedBox(width: 12),
                          Expanded(child: Text(bt.error!)),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: bt.pairedDevices.isEmpty
                    ? const Center(child: Text('Nothing paired yet.'))
                    : ListView.separated(
                        itemCount: bt.pairedDevices.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final device = bt.pairedDevices[i];
                          return ListTile(
                            leading: const Icon(Icons.bluetooth),
                            title: Text(device.name ?? 'Unknown device'),
                            subtitle: Text(device.address),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _connect(context, device),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
