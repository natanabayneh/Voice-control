import 'dart:async';

import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/foundation.dart';

import '../models/robot_command.dart';

/// Where a command came from, so the log can show it.
enum CommandSource { button, voice, autoStop }

class LogEntry {
  LogEntry(this.command, this.source, {this.detail}) : at = DateTime.now();

  final RobotCommand command;
  final CommandSource source;
  final String? detail;
  final DateTime at;
}

/// Owns the Bluetooth Classic link to the HC-05 and every byte we send it.
class BtService extends ChangeNotifier {
  /// Standard Serial Port Profile UUID — what an HC-05/HC-06 advertises.
  static const sppUuid = '00001101-0000-1000-8000-00805f9b34fb';

  final _bluetooth = BluetoothClassic();

  List<Device> pairedDevices = [];
  Device? connectedDevice;
  int status = Device.disconnected;
  String? error;
  final List<LogEntry> log = [];

  /// Some sketches read with `Serial.readStringUntil('\n')` instead of
  /// `Serial.read()`. Flip this if yours needs the terminator.
  bool appendNewline = false;

  /// Voice recognition takes a second or two, during which the robot keeps
  /// driving. After a movement command we send a stop unless another
  /// command arrives first.
  bool autoStopEnabled = true;
  Duration autoStopAfter = const Duration(seconds: 2);

  Timer? _autoStopTimer;
  StreamSubscription<int>? _statusSub;
  bool _initialised = false;

  bool get isConnected => status == Device.connected;
  bool get isConnecting => status == Device.connecting;

  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;
    _statusSub = _bluetooth.onDeviceStatusChanged().listen((newStatus) {
      status = newStatus;
      if (newStatus == Device.disconnected) {
        connectedDevice = null;
        _autoStopTimer?.cancel();
      }
      notifyListeners();
    });
    await refreshDevices();
  }

  /// Asks for the Bluetooth permissions, then reloads the paired list.
  Future<void> refreshDevices() async {
    error = null;
    notifyListeners();
    try {
      await _bluetooth.initPermissions();
      pairedDevices = await _bluetooth.getPairedDevices();
      if (pairedDevices.isEmpty) {
        error = 'No paired devices. Pair the HC-05 in Android '
            'Settings > Bluetooth first (PIN is usually 1234 or 0000).';
      }
    } catch (e) {
      error = 'Could not read paired devices: $e';
    }
    notifyListeners();
  }

  Future<bool> connect(Device device) async {
    error = null;
    status = Device.connecting;
    connectedDevice = device;
    notifyListeners();
    try {
      await _bluetooth.connect(device.address, sppUuid);
      return true;
    } catch (e) {
      error = 'Connection to ${device.name ?? device.address} failed: $e';
      status = Device.disconnected;
      connectedDevice = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect() async {
    _autoStopTimer?.cancel();
    try {
      await _bluetooth.disconnect();
    } catch (_) {
      // Already gone; the status stream will settle it.
    }
    status = Device.disconnected;
    connectedDevice = null;
    notifyListeners();
  }

  /// Writes one command character. Returns false (and records an error)
  /// rather than throwing when the link is down.
  Future<bool> send(
    RobotCommand command, {
    CommandSource source = CommandSource.button,
    String? detail,
  }) async {
    if (!isConnected) {
      error = 'Not connected — connect to the robot first.';
      notifyListeners();
      return false;
    }
    _autoStopTimer?.cancel();
    try {
      await _bluetooth.write(appendNewline ? '${command.code}\n' : command.code);
      error = null;
      log.insert(0, LogEntry(command, source, detail: detail));
      if (log.length > 50) log.removeLast();
      if (autoStopEnabled && command.isMovement) {
        _autoStopTimer = Timer(autoStopAfter, () {
          send(RobotCommand.stop, source: CommandSource.autoStop);
        });
      }
      notifyListeners();
      return true;
    } catch (e) {
      error = 'Send failed: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (error == null) return;
    error = null;
    notifyListeners();
  }

  void setAppendNewline(bool value) {
    appendNewline = value;
    notifyListeners();
  }

  void setAutoStopEnabled(bool value) {
    autoStopEnabled = value;
    if (!value) _autoStopTimer?.cancel();
    notifyListeners();
  }

  void setAutoStopAfter(Duration value) {
    autoStopAfter = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _autoStopTimer?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }
}
