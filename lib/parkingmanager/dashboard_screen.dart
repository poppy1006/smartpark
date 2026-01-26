import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ParkingManagerDashboard extends StatefulWidget {
  const ParkingManagerDashboard({super.key});

  @override
  State<ParkingManagerDashboard> createState() =>
      _ParkingManagerDashboardState();
}

class _ParkingManagerDashboardState
    extends State<ParkingManagerDashboard> {

  bool _processing = false;
  bool _permissionGranted = false;

  // --------------------------------------------------
  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  // --------------------------------------------------
  Future<void> _requestPermission() async {
    PermissionStatus status = await Permission.camera.status;

    if (status.isGranted) {
      setState(() => _permissionGranted = true);
      return;
    }

    if (status.isDenied || status.isRestricted) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      setState(() => _permissionGranted = true);
    } else if (status.isPermanentlyDenied) {
      // OPEN SETTINGS
      await openAppSettings();
    } else {
      setState(() => _permissionGranted = false);
    }
  }

  // --------------------------------------------------
  Future<void> _handleQr(String qr) async {
    if (_processing) return;
    setState(() => _processing = true);

    try {
      final booking = await supabase
          .from('bookings')
          .select()
          .eq('qr_token', qr)
          .maybeSingle();

      if (booking == null) {
        _show("Invalid QR");
        return;
      }

      final status = booking['status'];
      final bookingId = booking['id'];
      final slotId = booking['slot_id'];
      final now = DateTime.now().toIso8601String();

      // ENTRY
      if (status == 'pending') {
        await supabase.from('bookings').update({
          'status': 'parked',
          'start_time': now,
          'qr_token': null,
        }).eq('id', bookingId);

        _show("Vehicle Entered");

      // EXIT
      } else if (status == 'exit_pending') {
        await supabase.from('bookings').update({
          'status': 'completed',
          'end_time': now,
          'qr_token': null,
        }).eq('id', bookingId);

        await supabase
            .from('parking_slots')
            .update({'status': 'free'})
            .eq('id', slotId);

        _show("Vehicle Exited");

      } else {
        _show("QR not valid");
      }
    } catch (e) {
      _show("Error: $e");
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _processing = false);
    }
  }

  // --------------------------------------------------
  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking Manager"),
        backgroundColor: Colors.red,
      ),

      body: !_permissionGranted
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, size: 70),
                  const SizedBox(height: 12),
                  const Text(
                    "Camera permission required",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _requestPermission,
                    child: const Text("Grant Permission"),
                  ),

                  const SizedBox(height: 10),
                  const Text(
                    "If button doesn't work, allow from Settings",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Stack(
              children: [

                MobileScanner(
                  onDetect: (capture) {
                    if (_processing) return;

                    final code =
                        capture.barcodes.first.rawValue;

                    if (code != null) {
                      _handleQr(code);
                    }
                  },
                ),

                // DARK LAYER
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.35),
                  ),
                ),

                // SCAN BOX
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.greenAccent,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // TEXT
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      const Text(
                        "Scan Entry / Exit QR",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      if (_processing) ...[
                        const SizedBox(height: 12),
                        const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      ]
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
