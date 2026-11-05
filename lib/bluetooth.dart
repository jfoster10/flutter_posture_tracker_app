import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';



Future<BluetoothDevice?> connectionToBluetooth() async {
  final completer = Completer<BluetoothDevice?>();
  bool found = false;

  // 1. Check if Bluetooth adapter is ON
  BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
  if (state != BluetoothAdapterState.on) {
    print('Bluetooth is off');
    return null;
  }

  // Handle to manage and cancel our stream
  StreamSubscription<List<ScanResult>>? subscription;

  // 2. LISTEN FIRST: Set up stream listener before scanning starts
  subscription = FlutterBluePlus.scanResults.listen((results) async {
    for (ScanResult r in results) {
      if (!found && r.device.platformName.contains('ESP32_PostureTracker')) {
        found = true;

        // Clean up stream & stop scanning immediately
        await subscription?.cancel();
        await FlutterBluePlus.stopScan();

        // 3. TRY / CATCH: Safe connection handling
        try {
          print('Connecting to ${r.device.platformName}...');
          await r.device.connect(timeout: const Duration(seconds: 10));
          
          print('Connected!');
          completer.complete(r.device);
        } catch (e) {
          print('Connection error: $e');
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        }
      }
    }
  });

  // 4. START SCAN SECOND
  await FlutterBluePlus.startScan(
    timeout: const Duration(seconds: 15),
  );

  // 5. TIMEOUT FALLBACK: Clean cleanup if device isn't found
  Future.delayed(const Duration(seconds: 15), () async {
    if (!completer.isCompleted) {
      print('Scan timed out.');
      await subscription?.cancel(); // Prevent ghost listeners
      completer.complete(null);
    }
  });

  return completer.future;
}